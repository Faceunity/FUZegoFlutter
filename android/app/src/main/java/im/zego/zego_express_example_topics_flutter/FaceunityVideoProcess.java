package im.zego.zego_express_example_topics_flutter;

import android.annotation.SuppressLint;
import android.graphics.SurfaceTexture;
import android.opengl.EGL14;
import android.util.Log;
import com.faceunity.faceunity_plugin.FUVideoProcessor;

import java.nio.ByteBuffer;

import im.zego.zego_express_engine.IZegoFlutterCustomVideoProcessHandler;
import im.zego.zego_express_engine.ZGFlutterPublishChannel;
import im.zego.zego_express_engine.ZGFlutterVideoFrameParam;
import im.zego.zego_express_engine.ZegoCustomVideoProcessManager;

public class FaceunityVideoProcess implements IZegoFlutterCustomVideoProcessHandler {

    @SuppressLint("StaticFieldLeak")
    private static FaceunityVideoProcess instance;

    public static FaceunityVideoProcess getInstance() {
        if (instance == null) {
            synchronized (FaceunityVideoProcess.class) {
                if (instance == null) {
                    instance = new FaceunityVideoProcess();
                }
            }
        }
        return instance;
    }

    @Override
    public void onStart(ZGFlutterPublishChannel channel) {
        Log.i("CustomVideoProcess", "Start: " + EGL14.eglGetCurrentContext());
    }

    @Override
    public void onStop(ZGFlutterPublishChannel channel) {
        Log.i("CustomVideoProcess", "Stop: " + EGL14.eglGetCurrentContext());
    }

    @Override
    public void onCapturedUnprocessedTextureData(int textureID, int width, int height, long referenceTimeMillisecond, ZGFlutterPublishChannel channel) {
        int newTexId = FUVideoProcessor.onProcessVideoFrame(textureID, width, height);
        ZegoCustomVideoProcessManager.getInstance().sendProcessedTextureData(newTexId, width, height, referenceTimeMillisecond, channel);
    }

    @Override
    public void onCapturedUnprocessedRawData(ByteBuffer data, int[] dataLength, ZGFlutterVideoFrameParam param, long referenceTimeMillisecond, ZGFlutterPublishChannel channel) {
        
    }

    @Override
    public SurfaceTexture getCustomVideoProcessInputSurfaceTexture(int width, int height, ZGFlutterPublishChannel channel) {
        return null;
    }
}
