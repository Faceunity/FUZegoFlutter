package im.zego.zego_express_example_topics_flutter;

import android.annotation.SuppressLint;
import android.graphics.SurfaceTexture;
import android.util.Log;

import java.nio.*;
import im.zego.zego_express_engine.IZegoFlutterCustomVideoProcessHandler;
import im.zego.zego_express_engine.ZGFlutterPublishChannel;
import im.zego.zego_express_engine.ZGFlutterVideoFrameParam;
import im.zego.zego_express_engine.ZegoCustomVideoProcessManager;
import im.zego.zegoexpress.ZegoExpressEngine;

public class CustomVideoProcess implements IZegoFlutterCustomVideoProcessHandler {

    @SuppressLint("StaticFieldLeak")
    private static CustomVideoProcess instance;

    public static CustomVideoProcess getInstance() {
        if (instance == null) {
            synchronized (CustomVideoProcess.class) {
                if (instance == null) {
                    instance = new CustomVideoProcess();
                }
            }
        }
        return instance;
    }

    @Override
    public void onStart(ZGFlutterPublishChannel channel) {
        Log.i("CustomVideoProcess", "Start");
    }

    @Override
    public void onStop(ZGFlutterPublishChannel channel) {
        Log.i("CustomVideoProcess", "Stop");
    }

    @Override
    public void onCapturedUnprocessedTextureData(int textureID, int width, int height, long referenceTimeMillisecond, ZGFlutterPublishChannel channel) {
        ZegoCustomVideoProcessManager.getInstance().sendProcessedTextureData(textureID, width, height, referenceTimeMillisecond, channel);
    }

    @Override
    public void onCapturedUnprocessedRawData(ByteBuffer data, int[] dataLength, ZGFlutterVideoFrameParam param, long referenceTimeMillisecond, ZGFlutterPublishChannel channel) {
        
    }

    @Override
    public SurfaceTexture getCustomVideoProcessInputSurfaceTexture(int width, int height, ZGFlutterPublishChannel channel) {
        return null;
    }
}
