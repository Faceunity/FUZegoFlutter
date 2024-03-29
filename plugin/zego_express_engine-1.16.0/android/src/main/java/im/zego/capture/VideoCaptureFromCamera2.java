package im.zego.capture;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.opengl.Matrix;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.SystemClock;
import android.util.Log;
import android.view.TextureView;
import android.view.View;

import androidx.annotation.RequiresApi;

import com.faceunity.core.entity.FURenderInputData;
import com.faceunity.core.entity.FURenderOutputData;
import com.faceunity.core.enumeration.FUInputTextureEnum;
import com.faceunity.core.enumeration.FUTransformMatrixEnum;
import com.faceunity.core.faceunity.FURenderKit;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import im.zego.faceunity.FaceUnityExtension;
import im.zego.ve_gl.EglBase;
import im.zego.ve_gl.EglBase14;
import im.zego.ve_gl.GlRectDrawer;
import im.zego.ve_gl.GlUtil;
import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.callback.IZegoCustomVideoCaptureHandler;
import im.zego.zegoexpress.constants.ZegoPublishChannel;

/**
 * VideoCaptureFromCamera2
 * 实现从摄像头采集数据并传给ZEGO SDK，需要继承实现ZEGO SDK 的ZegoVideoCaptureDevice类
 * 采用SURFACE_TEXTURE方式传递数据，将client返回的SurfaceTexture对象转为EglSurface再进行图像绘制
 */

/**
 *  * VideoCaptureFromCamera2
 *  * To collect data from the camera and pass it to the ZEGO SDK, you need to inherit the ZegoVideoCaptureDevice class that implements the ZEGO SDK
 *  * Use SURFACE_TEXTURE to transfer data, convert the SurfaceTexture object returned by the client to EglSurface and then draw the image
 *  
 */
public class VideoCaptureFromCamera2 extends IZegoCustomVideoCaptureHandler implements
        SurfaceTexture.OnFrameAvailableListener,
        TextureView.SurfaceTextureListener, ICaptureCamera {
    private static final String TAG = "VideoCaptureFromCamera2";
    private static final int CAMERA_STOP_TIMEOUT_MS = 7000;

    private Camera mCam = null;
    private Camera.CameraInfo mCamInfo = null;
    // camera相关参数的初始值
    // Initial values ​​of camera related parameters
    private int mFront = 1;
    private int mCameraWidth = 720;
    private int mCameraHeight = 1280;
    private int mCaptureWidth = 720;
    private int mCaptureHeight = 1280;
    private int mViewWidth = 0;
    private int mViewHeight = 0;
    private int mViewMode = 1;
    private int mFrameRate = 15;
    private int mDisplayRotation = 0;
    private int mImageRotation = 0;

    // 用于帧缓冲区对象（FBO）的相关变量
    // Related variables for frame buffer object (FBO)
    private EglBase mDummyContext = null;
    private GlRectDrawer mDummyDrawer = null;
    private boolean mIsEgl14 = false;
    private int mInputTextureId = 0;
    private SurfaceTexture mInputSurfaceTexture = null;
    private float[] mInputMatrix = new float[16];
    private int mTextureId = 0;
    private int mFrameBufferId = 0;

    private boolean mCameraEnable = false;

    // 纹理变换矩阵
    // Texture transformation matrix
    private float[] mIdentityMatrix = new float[]{1.0f, 0.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f, 0.0f,
            0.0f, 0.0f, 1.0f, 0.0f,
            0.0f, 0.0f, 0.0f, 1.0f};

    private HandlerThread mThread = null;
    private volatile Handler cameraThreadHandler = null;
    private final AtomicBoolean isCameraRunning = new AtomicBoolean();
    private final Object pendingCameraRestartLock = new Object();
    private volatile boolean pendingCameraRestart = false;

    // 用于展示预览图的相关变量
    // Related variables used to display preview images
    private boolean mIsPreview = false;
    private EglBase previewEglBase = null;
    private GlRectDrawer previewDrawer = null;
    private float[] mPreviewMatrix = new float[16];

    // 用于向SDK传递SurfaceTexture的相关变量
    // Used to pass SurfaceTexture related variables to SDK
    private boolean mIsCapture = false;
    private EglBase captureEglBase = null;
    private GlRectDrawer captureDrawer = null;
    private float[] mCaptureMatrix = new float[16];
    private FURenderKit mFURenderKit = FURenderKit.getInstance();
    private FURenderInputData mFURenderInputData;
    private TextureView mTextureView = null;

    private SensorManager mSensorManager;
    private Sensor mSensor;
    private int deviceOrientation = 90;

    public VideoCaptureFromCamera2(Context context) {
        mSensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        mSensor = mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
    }

    /**
     * 内置陀螺仪
     */
    private SensorEventListener mSensorEventListener = new SensorEventListener() {
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) {}

        @Override
        public void onSensorChanged(SensorEvent event) {
            if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
                float x = event.values[0];
                float y = event.values[1];
                if (Math.abs(x) > 3 || Math.abs(y) > 3) {
                    if (Math.abs(x) > Math.abs(y)) {
                        deviceOrientation = x > 0 ? 0 : 180;
                    } else {
                        deviceOrientation = y > 0 ? 90 : 270;
                    }

                }
            }
        }
    };

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    @Override
    public void onStart(ZegoPublishChannel channel) {
        if (channel == ZegoPublishChannel.MAIN) {
            allocateAndStart();
            cameraThreadHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    startPreview();
                }
            }, 1000);

            cameraThreadHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    restartCam();
                    startCapture();

                }
            }, 2000);
            mSensorManager.registerListener(mSensorEventListener, mSensor, SensorManager.SENSOR_DELAY_NORMAL);
        }
    }

    /**
     * 初始化资源，必须实现
     */
    /**
     * Initialization of resources must be achieved
     *      
     */
    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public void allocateAndStart() {
        Log.d(TAG, "allocateAndStart");
        mThread = new HandlerThread("camera-cap");
        mThread.start();
        // 创建camera异步消息处理handler
        // Create a camera asynchronous message processing handler
        cameraThreadHandler = new Handler(mThread.getLooper());

        final CountDownLatch barrier = new CountDownLatch(1);
        cameraThreadHandler.post(new Runnable() {
            @Override
            public void run() {
                mDummyContext = EglBase.create(null, EglBase.CONFIG_PIXEL_BUFFER);

                try {
                    // 创建Surface
                    mDummyContext.createDummyPbufferSurface();
                    // 绑定eglContext、eglDisplay、eglSurface
                    mDummyContext.makeCurrent();
                    // 创建绘制类，用于FBO
                    mDummyDrawer = new GlRectDrawer();
                } catch (RuntimeException e) {
                    // Clean up before rethrowing the exception.
                    mDummyContext.releaseSurface();
                    e.printStackTrace();
                    throw e;
                }

                mIsEgl14 = EglBase14.isEGL14Supported();
                mInputTextureId = GlUtil.generateTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES);
                mInputSurfaceTexture = new SurfaceTexture(mInputTextureId);
                // 设置视频帧回调监听
                // Create a camera asynchronous message processing handler
                mInputSurfaceTexture.setOnFrameAvailableListener(VideoCaptureFromCamera2.this);

                barrier.countDown();
            }
        });
        try {
            barrier.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    @Override
    public void onStop(ZegoPublishChannel channel) {
        if (ZegoPublishChannel.MAIN == channel) {
            stopPreview();
            stopAndDeAllocate();
            mFURenderKit.release();
            mSensorManager.unregisterListener(mSensorEventListener);
        }
    }

    /**
     * 释放资源，必须实现
     * 先停止采集任务再清理client对象，以保证ZEGO SDK调用stopAndDeAllocate后，没有残留的异步任务导致野指针crash
     */
    /**
     *      * To release resources, it must be realized
     *      * Stop the collection task before cleaning the client object to ensure that after the ZEGO SDK calls stopAndDeAllocate, there is no residual asynchronous task that causes wild pointer crash
     *      
     */
    public void stopAndDeAllocate() {
        Log.d(TAG, "stopAndDeAllocate");
        stopCapture();

        if (cameraThreadHandler != null) {
            final CountDownLatch barrier = new CountDownLatch(1);
            cameraThreadHandler.post(new Runnable() {
                @Override
                public void run() {
                    // 销毁传递给ZEGO SDK的surface
                    releaseCaptureSurface();

                    if (captureEglBase != null) {
                        captureEglBase.release();
                        captureEglBase = null;
                    }

                    // 销毁用于屏幕显示的surface（预览）
                    releasePreviewSurface();

                    if (previewDrawer != null) {
                        previewDrawer.release();
                        previewDrawer = null;
                    }
                    if (captureEglBase != null) {
                        captureEglBase.release();

                        captureEglBase = null;
                    }
                    if (mTextureView != null) {
                        if (mTextureView.getSurfaceTextureListener().equals(VideoCaptureFromCamera2.this)) {
                            mTextureView.setSurfaceTextureListener(null);
                        }
                        mTextureView = null;
                    }

                    mInputSurfaceTexture.release();
                    mInputSurfaceTexture = null;

                    // 绑定eglContext、eglDisplay、eglSurface
                    mDummyContext.makeCurrent();
                    if (mInputTextureId != 0) {
                        int[] textures = new int[]{mInputTextureId};
                        GLES20.glDeleteTextures(1, textures, 0);
                        mInputTextureId = 0;
                    }

                    if (mTextureId != 0) {
                        int[] textures = new int[]{mTextureId};
                        GLES20.glDeleteTextures(1, textures, 0);
                        mTextureId = 0;
                    }

                    if (mFrameBufferId != 0) {
                        int[] frameBuffers = new int[]{mFrameBufferId};
                        GLES20.glDeleteFramebuffers(1, frameBuffers, 0);
                        mFrameBufferId = 0;
                    }

                    mDummyDrawer = null;
                    mDummyContext.release();
                    mDummyContext = null;

                    barrier.countDown();
                }
            });
            try {
                barrier.await();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        mThread.quit();
        mThread = null;
    }

    // 开始推流时，ZEGO SDK 调用 startCapture 通知外部采集设备开始工作，必须实现
    // When starting to push the stream, ZEGO SDK calls startCapture to notify the external collection device to start work, which must be implemented
    public int startCapture() {
        Log.d(TAG, "startCapture");
        mIsCapture = true;
        startCamera();
        return 0;
    }

    // 停止推流时，ZEGO SDK 调用 stopCapture 通知外部采集设备停止采集，必须实现
    // When stopping pushing, the ZEGO SDK calls stopCapture to notify the external collection device to stop collection, which must be implemented
    public int stopCapture() {
        Log.d(TAG, "stopCapture");
        mIsCapture = false;
        stopCamera();
        return 0;
    }

    @Override
    public void enableCamera(boolean enable) {
        mCameraEnable = enable;
        if (enable) {
            cameraThreadHandler.post(this::restartCam);
        }
    }

    // 启动camera
    public int startCamera() {
        if (isCameraRunning.getAndSet(true)) {
            Log.e(TAG, "Camera has already been started.");
            return 0;
        }

        final boolean didPost = maybePostOnCameraThread(new Runnable() {
            @Override
            public void run() {
                // * Create and Start Cam
                if (mCameraEnable) {
                    createCamOnCameraThread();
                    startCamOnCameraThread();
                }

            }
        });

        return 0;
    }

    // 关闭camera
    public int stopCamera() {
        if (mIsPreview) {
            return 0;
        }

        final CountDownLatch barrier = new CountDownLatch(1);
        final boolean didPost = maybePostOnCameraThread(new Runnable() {
            @Override
            public void run() {
                stopCaptureOnCameraThread(true /* stopHandler */);
                releaseCam();
                barrier.countDown();
            }
        });
        if (!didPost) {
            Log.e(TAG, "Calling stopCapture() for already stopped camera.");
            return 0;
        }
        try {
            if (!barrier.await(CAMERA_STOP_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
                Log.e(TAG, "Camera stop timeout");
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        FURenderKit.getInstance().releaseSafe();
        Log.d(TAG, "stopCapture done");

        return 0;
    }

    // 设置采集帧率
    // Set the acquisition frame rate
    public int setFrameRate(final int framerate) {
        mFrameRate = framerate;

        if (cameraThreadHandler != null) {
            cameraThreadHandler.post(new Runnable() {
                @Override
                public void run() {
                    updateRateOnCameraThread(framerate);
                }
            });
        }

        return 0;
    }

    // 设置视图宽高
    // Set view width and height
    public int setResolution(int width, int height) {
        mCaptureWidth = width;
        mCaptureHeight = height;
        // 修改视图宽高后需要重启camera
        restartCam();
        return 0;
    }

    // 前后摄像头的切换
    // Switching between front and back cameras
    public int setFrontCam(int bFront) {
        mFront = bFront;
        // 切换摄像头后需要重启camera
        // Camera needs to be restarted after switching cameras
        restartCam();
        return 0;
    }

    // 设置展示视图
    // Set display view
    public int setView(final View view) {
        if (view instanceof TextureView) {
            setRendererView((TextureView) view);
        }

        return 0;
    }

    public int setViewMode(int nMode) {
        mViewMode = nMode;
        return 0;
    }

    public int setViewRotation(int nRotation) {
        return 0;
    }

    // 设置采集时的旋转方向
    // Set the rotation direction during acquisition
    public int setCaptureRotation(int nRotation) {
        mDisplayRotation = nRotation;
        return 0;
    }

    // 启动预览
    public int startPreview() {
        mIsPreview = true;
        return startCamera();
    }

    // 停止预览
    public int stopPreview() {
        mIsPreview = false;
        mIsCapture = false;
        return stopCamera();
    }

    public int enableTorch(boolean bEnable) {
        return 0;
    }

    public int takeSnapshot() {
        return 0;
    }

    public int setPowerlineFreq(int nFreq) {
        return 0;
    }

    // 更新camera的采集帧率
    // Update camera frame rate
    private int updateRateOnCameraThread(final int framerate) {
        checkIsOnCameraThread();
        if (mCam == null) {
            return 0;
        }

        mFrameRate = framerate;

        Camera.Parameters parms = mCam.getParameters();
        List<int[]> supported = parms.getSupportedPreviewFpsRange();

        for (int[] entry : supported) {
            if ((entry[0] == entry[1]) && entry[0] == mFrameRate * 1000) {
                parms.setPreviewFpsRange(entry[0], entry[1]);
                break;
            }
        }

        int[] realRate = new int[2];
        parms.getPreviewFpsRange(realRate);
        if (realRate[0] == realRate[1]) {
            mFrameRate = realRate[0] / 1000;
        } else {
            mFrameRate = realRate[1] / 2 / 1000;
        }

        try {
            mCam.setParameters(parms);
        } catch (Exception ex) {
            Log.i(TAG, "vcap: update fps -- set camera parameters error with exception\n");
            ex.printStackTrace();
        }
        return 0;
    }

    private void checkIsOnCameraThread() {
        if (cameraThreadHandler == null) {
            Log.e(TAG, "Camera is not initialized - can't check thread.");
        } else if (Thread.currentThread() != cameraThreadHandler.getLooper().getThread()) {
            throw new IllegalStateException("Wrong thread");
        }
    }

    private boolean maybePostOnCameraThread(Runnable runnable) {
        return cameraThreadHandler != null && isCameraRunning.get()
                && cameraThreadHandler.postAtTime(runnable, this, SystemClock.uptimeMillis());
    }

    // 创建camera
    // create camera
    private int createCamOnCameraThread() {
        checkIsOnCameraThread();
        if (!isCameraRunning.get()) {
            Log.e(TAG, "startCaptureOnCameraThread: Camera is stopped");
            return 0;
        }

        Log.i(TAG, "board: " + Build.BOARD);
        Log.i(TAG, "device: " + Build.DEVICE);
        Log.i(TAG, "manufacturer: " + Build.MANUFACTURER);
        Log.i(TAG, "brand: " + Build.BRAND);
        Log.i(TAG, "model: " + Build.MODEL);
        Log.i(TAG, "product: " + Build.PRODUCT);
        Log.i(TAG, "sdk: " + Build.VERSION.SDK_INT);

        // 获取欲设置camera的索引号
        // Get the index number of the camera to be set
        int nFacing = (mFront != 0) ? Camera.CameraInfo.CAMERA_FACING_FRONT : Camera.CameraInfo.CAMERA_FACING_BACK;

        if (mCam != null) {
            // 已打开camera
            // Camera opened
            return 0;
        }

        mCamInfo = new Camera.CameraInfo();
        // 获取camera的数目
        // Get the number of cameras
        int nCnt = Camera.getNumberOfCameras();
        // 得到欲设置camera的索引号并打开camera
        // Get the index number of the camera you want to set and open the camera
        for (int i = 0; i < nCnt; i++) {
            Camera.getCameraInfo(i, mCamInfo);
            if (mCamInfo.facing == nFacing) {
                try {
                    mCam = Camera.open(i);
                } catch (RuntimeException e) {
                    mCam = null;
                }
                break;
            }
        }

        // 没找到欲设置的camera
        // Did not find the camera to be set
        if (mCam == null) {
            Log.i(TAG, "[WARNING] no camera found, try default\n");
            // 先试图打开默认camera
            // First try to open the default camera
            mCam = Camera.open();

            if (mCam == null) {
                Log.i(TAG, "[ERROR] no camera found\n");
                return -1;
            }
        }

        // *
        // * Now set preview size
        // *
        boolean bSizeSet = false;
        Camera.Parameters parms = mCam.getParameters();
        // 获取camera首选的size
        // Get the camera's preferred size
        Camera.Size psz = parms.getPreferredPreviewSizeForVideo();

        if (psz == null) {
            psz = mCam.new Size(640, 480);
        }

        // 设置camera的采集视图size
        // Set the camera's collection view size
        parms.setPreviewSize(psz.width, psz.height);
        mCameraWidth = psz.width;
        mCameraHeight = psz.height;

        // 获取camera支持的帧率范围，并设置预览帧率范围
        // Get the frame rate range supported by the camera and set the preview frame rate range
        List<int[]> supported = parms.getSupportedPreviewFpsRange();

        for (int[] entry : supported) {
            if ((entry[0] == entry[1]) && entry[0] == mFrameRate * 1000) {
                parms.setPreviewFpsRange(entry[0], entry[1]);
                break;
            }
        }

        // 获取camera的实际帧率
        // Get the actual frame rate of the camera
        int[] realRate = new int[2];
        parms.getPreviewFpsRange(realRate);
        if (realRate[0] == realRate[1]) {
            mFrameRate = realRate[0] / 1000;
        } else {
            mFrameRate = realRate[1] / 2 / 1000;
        }

        // 设置camera的对焦模式
        // Set the camera's focus mode
        boolean bFocusModeSet = false;
        for (String mode : parms.getSupportedFocusModes()) {
            if (mode.compareTo(Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO) == 0) {
                try {
                    parms.setFocusMode(mode);
                    bFocusModeSet = true;
                    break;
                } catch (Exception ex) {
                    Log.i(TAG, "[WARNING] vcap: set focus mode error (stack trace followed)!!!\n");
                    ex.printStackTrace();
                }
            }
        }
        if (!bFocusModeSet) {
            Log.i(TAG, "[WARNING] vcap: focus mode left unset !!\n");
        }

        try {
            // 设置camera的参数
            mCam.setParameters(parms);
        } catch (Exception ex) {
            Log.i(TAG, "vcap: set camera parameters error with exception\n");
            ex.printStackTrace();
        }

        Camera.Parameters actualParm = mCam.getParameters();
        mCameraWidth = actualParm.getPreviewSize().width;
        mCameraHeight = actualParm.getPreviewSize().height;
        Log.i(TAG, "[WARNING] vcap: focus mode " + actualParm.getFocusMode());

        int result;
        if (mCamInfo.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            result = (mCamInfo.orientation + mDisplayRotation) % 360;
            result = (360 - result) % 360;  // compensate the mirror
        } else {  // back-facing
            result = (mCamInfo.orientation - mDisplayRotation + 360) % 360;
        }
        // 设置预览图像的转方向
        // Set the rotation direction of the preview image
        mCam.setDisplayOrientation(result);
        mImageRotation = result;

        // 绑定eglContext、eglDisplay、eglSurface
        mDummyContext.makeCurrent();

        Log.d(TAG, "ImageRotation:" + mImageRotation);
        if (mTextureId != 0) {
            int[] textures = new int[]{mTextureId};
            GLES20.glDeleteTextures(1, textures, 0);
            mTextureId = 0;
        }

        if (mFrameBufferId != 0) {
            int[] frameBuffers = new int[]{mFrameBufferId};
            GLES20.glDeleteFramebuffers(1, frameBuffers, 0);
            mFrameBufferId = 0;
        }

        // 销毁传递给ZEGO SDK的surface，如果原先已有EGLSurface的情况下
//        Destroy the surface passed to the ZEGO SDK, if the EGLSurface already exists
        releaseCaptureSurface();

        return 0;
    }

    // 启动camera
    private int startCamOnCameraThread() {
        checkIsOnCameraThread();
        if (!isCameraRunning.get() || mCam == null) {
            Log.e(TAG, "startPreviewOnCameraThread: Camera is stopped");
            return 0;
        }

        // * mCam.setDisplayOrientation(90);
        if (mInputSurfaceTexture == null) {
            Log.e(TAG, "mInputSurfaceTexture == null");
            return -1;
        }

        try {
            // 设置预览SurfaceTexture
            mCam.setPreviewTexture(mInputSurfaceTexture);
        } catch (IOException e) {
            e.printStackTrace();
        }

        // 启动camera预览
        mCam.startPreview();
        Log.e(TAG, "startPreview success");

        return 0;
    }

    // camera停止采集
    // The camera stops collecting
    private int stopCaptureOnCameraThread(boolean stopHandler) {
        checkIsOnCameraThread();
        Log.d(TAG, "stopCaptureOnCameraThread");

        if (stopHandler) {
            // Clear the cameraThreadHandler first, in case stopPreview or
            // other driver code deadlocks. Deadlock in
            // android.hardware.Camera._stopPreview(Native Method) has
            // been observed on Nexus 5 (hammerhead), OS version LMY48I.
            // The camera might post another one or two preview frames
            // before stopped, so we have to check |isCameraRunning|.
            // Remove all pending Runnables posted from |this|.
            isCameraRunning.set(false);
            cameraThreadHandler.removeCallbacksAndMessages(this /* token */);
        }

        if (mCam != null) {
            // 停止camera预览
            mCam.stopPreview();
        }
        return 0;
    }

    // 重启camera
    private int restartCam() {

        if (!mCameraEnable) return 0;

        synchronized (pendingCameraRestartLock) {
            if (pendingCameraRestart) {
                // Do not handle multiple camera switch request to avoid blocking
                // camera thread by handling too many switch request from a queue.
                Log.w(TAG, "Ignoring camera switch request.");
                return 0;
            }
            pendingCameraRestart = true;
        }

        final boolean didPost = maybePostOnCameraThread(new Runnable() {
            @Override
            public void run() {
                stopCaptureOnCameraThread(false);
                releaseCam();
                createCamOnCameraThread();
                startCamOnCameraThread();
                synchronized (pendingCameraRestartLock) {
                    pendingCameraRestart = false;
                }
            }
        });

        if (!didPost) {
            synchronized (pendingCameraRestartLock) {
                pendingCameraRestart = false;
            }
        }

        return 0;
    }

    // 释放camera
    private int releaseCam() {
        // * release cam
        if (mCam != null) {
            mCam.release();
            mCam = null;
        }

        // * release cam info
        mCamInfo = null;
        return 0;
    }

    @Override
    public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
    }

    @Override
    public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
        if (cameraThreadHandler != null) {
            cameraThreadHandler.post(new Runnable() {
                @Override
                public void run() {
                    releasePreviewSurface();
                }
            });
        }
    }

    @Override
    public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
        if (cameraThreadHandler != null) {
            final CountDownLatch barrier = new CountDownLatch(1);
            cameraThreadHandler.post(new Runnable() {
                @Override
                public void run() {
                    // 销毁用于屏幕显示的surface（预览）
                    releasePreviewSurface();
                    barrier.countDown();
                }
            });
            try {
                barrier.await();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        return true;
    }

    @Override
    public void onSurfaceTextureUpdated(SurfaceTexture surface) {

    }

    // 设置渲染视图
    // Set the rendering view
    public int setRendererView(TextureView view) {
        if (cameraThreadHandler == null) {
            // 设置Texture.SurfaceTextureListener回调监听
            doSetRendererView(view);
        } else {
            final CountDownLatch barrier = new CountDownLatch(1);
            final TextureView temp = view;
            cameraThreadHandler.post(new Runnable() {
                @Override
                public void run() {
                    doSetRendererView(temp);
                    barrier.countDown();
                }
            });
            try {
                barrier.await();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        return 0;
    }

    // 设置Texture.SurfaceTextureListener回调监听
    // Set Texture.SurfaceTextureListener callback listener
    private void doSetRendererView(TextureView temp) {
        if (mTextureView != null) {
            if (mTextureView.getSurfaceTextureListener().equals(VideoCaptureFromCamera2.this)) {
                mTextureView.setSurfaceTextureListener(null);
            }
            releasePreviewSurface();
        }

        mTextureView = temp;
        if (mTextureView != null) {
            mTextureView.setSurfaceTextureListener(VideoCaptureFromCamera2.this);
        }
    }

    // 设置预览视图
    // Set preview view
    private void attachTextureView() {
        if (previewEglBase.hasSurface()) {
            return;
        }

        if (!mTextureView.isAvailable()) {
            return;
        }

        mViewWidth = mTextureView.getWidth();
        mViewHeight = mTextureView.getHeight();
        try {
            // 创建EGLSurface
            previewEglBase.createSurface(mTextureView.getSurfaceTexture());
        } catch (RuntimeException e) {
            e.printStackTrace();
            releasePreviewSurface();
            mViewWidth = 0;
            mViewHeight = 0;
        }
    }

    // 绘制图像数据到屏幕
    // Draw image data to the screen
    private void drawToPreview(int textureId, int width, int height, float[] texMatrix) {
        if (previewEglBase == null) {
            previewEglBase = EglBase.create(mDummyContext.getEglBaseContext(), EglBase.CONFIG_RGBA);
        }

        if (mTextureView != null) {
            attachTextureView();
        }

        if (!previewEglBase.hasSurface()) {
            return;
        }

        if (previewDrawer == null) {
            previewDrawer = new GlRectDrawer();
        }

        try {
            // 绑定eglContext、eglDisplay、eglSurface
            previewEglBase.makeCurrent();

            // 作用是使图像正立显示
            // The role is to make the image stand upright
            int scaleWidth = mViewWidth;
            int scaleHeight = mViewHeight;

            System.arraycopy(texMatrix, 0, mPreviewMatrix, 0, 16);
            if (mViewMode == 0) {
                if (mViewHeight * width <= mViewWidth * height) {
                    scaleWidth = mViewHeight * width / height;
                } else {
                    scaleHeight = mViewWidth * height / width;
                }
            } else if (mViewMode == 1) {
                if (mViewHeight * width <= mViewWidth * height) {
                    scaleHeight = mViewWidth * height / width;
                } else {
                    scaleWidth = mViewHeight * width / height;
                }
                float fWidthScale = (float) mViewWidth / scaleWidth;
                float fHeightScale = (float) mViewHeight / scaleHeight;
                Matrix.scaleM(mPreviewMatrix, 0, fWidthScale, fHeightScale, 1.0f);
                Matrix.translateM(mPreviewMatrix, 0, (1.0f - fWidthScale) / 2.0f, (1.0f - fHeightScale) / 2.0f, 1.0f);

                scaleWidth = mViewWidth;
                scaleHeight = mViewHeight;
            }

            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
            // 绘制rgb格式图像
            // Draw rgb format image
            previewDrawer.drawRgb(mTextureId, mPreviewMatrix, width, height,
                    (mViewWidth - scaleWidth) / 2,
                    (mViewHeight - scaleHeight) / 2,
                    scaleWidth, scaleHeight);
            // 交换渲染好的buffer 去显示
            // Exchange the rendered buffer to display
            previewEglBase.swapBuffers();
            // 分离当前eglContext
            previewEglBase.detachCurrent();
        } catch (RuntimeException e) {
            e.printStackTrace();
        }
    }

    // 绘制图像数据到SDK提供的EglSurface上
    // Draw image data to EglSurface provided by SDK
    private void drawToCapture(int textureId, int width, int height, float[] texMatrix, long timestamp_ns) {
        if (captureEglBase == null) {
            captureEglBase = EglBase.create(mDummyContext.getEglBaseContext(), EglBase.CONFIG_RECORDABLE);
        }

        if (!captureEglBase.hasSurface() && ZegoExpressEngine.getEngine() != null) {
            SurfaceTexture temp = ZegoExpressEngine.getEngine().getCustomVideoCaptureSurfaceTexture();
            if (temp == null) {
                return;
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH_MR1) {
                // 设置Surface的分辨率
                // Set Surface resolution
                temp.setDefaultBufferSize(mCaptureWidth, mCaptureHeight);
            }
            try {
                // 创建EGLSurface
                captureEglBase.createSurface(temp);
                // 绑定eglContext、eglDisplay、eglSurface
                captureEglBase.makeCurrent();
                // 创建绘制类
                captureDrawer = new GlRectDrawer();
            } catch (RuntimeException e) {
                e.printStackTrace();
                // Clean up before rethrowing the exception.
                captureEglBase.releaseSurface();
                return;
            }
        }

        try {
            // 绑定eglContext、eglDisplay、eglSurface
            captureEglBase.makeCurrent();

            int scaleWidth = mCaptureWidth;
            int scaleHeight = mCaptureHeight;
            System.arraycopy(texMatrix, 0, mCaptureMatrix, 0, 16);
            if (mViewMode == 0) {
                if (mCaptureHeight * width <= mCaptureWidth * height) {
                    scaleWidth = mCaptureHeight * width / height;
                } else {
                    scaleHeight = mCaptureWidth * height / width;
                }
            } else if (mViewMode == 1) {
                if (mCaptureHeight * width <= mCaptureWidth * height) {
                    scaleHeight = mCaptureWidth * height / width;
                } else {
                    scaleWidth = mCaptureHeight * width / height;
                }
                float fWidthScale = (float) mCaptureWidth / scaleWidth;
                float fHeightScale = (float) mCaptureHeight / scaleHeight;
                Matrix.scaleM(mCaptureMatrix, 0, fWidthScale, fHeightScale, 1.0f);
                Matrix.translateM(mCaptureMatrix, 0, (1.0f - fWidthScale) / 2.0f, (1.0f - fHeightScale) / 2.0f, 1.0f);

                scaleWidth = mCaptureWidth;
                scaleHeight = mCaptureHeight;
            }

            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);

            FaceUnityExtension.execute();

            if (mFURenderInputData == null) {
                mFURenderInputData = new FURenderInputData(width, height);
            }
            mFURenderInputData.setTexture(new FURenderInputData.FUTexture(FUInputTextureEnum.FU_ADM_FLAG_COMMON_TEXTURE, textureId));
            mFURenderInputData.getRenderConfig().setInputTextureMatrix(FUTransformMatrixEnum.CCROT0);
            mFURenderInputData.getRenderConfig().setDeviceOrientation(deviceOrientation);
            mFURenderInputData.getRenderConfig().setOutputMatrix(FUTransformMatrixEnum.CCROT0_FLIPVERTICAL);
            FURenderOutputData fuRenderOutputData = mFURenderKit.renderWithInput(mFURenderInputData);
            int zegoTextureId = fuRenderOutputData.getTexture().getTexId();
            GLES20.glFinish();
            // 绘制rgb格式图像
            // Draw rgb format image
            captureDrawer.drawRgb(zegoTextureId, mCaptureMatrix, width, height,
                    0,
                    0,
                    scaleWidth, scaleHeight);
//
            // 交换渲染好的buffer 去显示
            // Exchange the rendered buffer to display
            if (mIsEgl14) {
                ((EglBase14) captureEglBase).swapBuffers(timestamp_ns);
            } else {
                captureEglBase.swapBuffers();
            }

            // 分离当前eglContext
            captureEglBase.detachCurrent();
        } catch (RuntimeException e) {
            e.printStackTrace();
        }
    }

    // 销毁用于屏幕显示的surface（预览）
    // Destroy the surface used for screen display (preview)
    private void releasePreviewSurface() {
        if (previewEglBase == null) {
            return;
        }

        if (previewEglBase.hasSurface()) {
            // 绑定eglContext、eglDisplay、eglSurface
            previewEglBase.makeCurrent();

            if (previewDrawer != null) {
                previewDrawer = null;
            }

            previewEglBase.releaseSurface();
            previewEglBase.detachCurrent();
        }

        previewEglBase.release();
        previewEglBase = null;
    }

    // 销毁传递给ZEGO SDK的surface
    // Destroy the surface passed to the ZEGO SDK
    private void releaseCaptureSurface() {
        if (captureEglBase == null) {
            return;
        }

        if (captureEglBase.hasSurface()) {
            // 绑定eglContext、eglDisplay、eglSurface
            captureEglBase.makeCurrent();

            if (captureDrawer != null) {
                captureDrawer = null;
            }

            captureEglBase.releaseSurface();
            captureEglBase.detachCurrent();
        }
    }

    // 在SurfaceTexture.OnFrameAvailableListener回调中更新采集数据
    // Update the collected data in the SurfaceTexture.OnFrameAvailableListener callback
    @Override
    public void onFrameAvailable(SurfaceTexture surfaceTexture) {
        // 绑定eglContext、eglDisplay、eglSurface
        mDummyContext.makeCurrent();
        surfaceTexture.updateTexImage();
        long timestamp = surfaceTexture.getTimestamp();
        surfaceTexture.getTransformMatrix(mInputMatrix);

        // do preprocessing here such as camera 360 sdk

        // 纠正图像展示方向
        // Correct image display direction
        int width = mCameraWidth;
        int height = mCameraHeight;
        if (mImageRotation == 90 || mImageRotation == 270) {
            int temp = width;
            width = height;
            height = temp;
        }

        if (mTextureId == 0) {
            GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
            mTextureId = GlUtil.generateTexture(GLES20.GL_TEXTURE_2D);
            // 生成2D纹理
            // Generate 2D textures
            GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, width, height, 0, GLES20.GL_RGBA,
                    GLES20.GL_UNSIGNED_BYTE, null);

            // 创建帧缓冲对象，绘制纹理到帧缓冲区并返回缓冲区索引
            // Create frame buffer object, draw texture to frame buffer and return buffer index
            mFrameBufferId = GlUtil.generateFrameBuffer(mTextureId);
            Log.e("zego", "生成的mFrameBufferId=" + mFrameBufferId);
        } else {
            // 绑定帧缓冲区
            // Bind frame buffer
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mFrameBufferId);
        }

        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        // 绘制OES texture
        // Draw OES texture
        mDummyDrawer.drawOes(mInputTextureId, mInputMatrix,
                width, height, 0, 0, width, height);
        // 解邦帧缓冲区
        // Unbind the frame buffer
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);

        // 绘制图像数据到SDK提供的EglSurface上
        // Draw image data to EglSurface provided by SDK
        if (mIsCapture) {
            drawToCapture(mTextureId, width, height, mIdentityMatrix, timestamp);
        }

        // 绘制图像数据到屏幕
        // Draw image data to the screen
        if (mIsPreview) {
            drawToPreview(mTextureId, width, height, mIdentityMatrix);
        }
    }
}
