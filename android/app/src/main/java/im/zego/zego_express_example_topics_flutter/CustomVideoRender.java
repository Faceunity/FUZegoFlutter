package im.zego.zego_express_example_topics_flutter;

import android.annotation.SuppressLint;

import java.nio.ByteBuffer;

import im.zego.zego_express_engine.IZegoFlutterCustomVideoRenderHandler;
import im.zego.zego_express_engine.ZGFlutterPublishChannel;
import im.zego.zego_express_engine.ZGFlutterVideoEncodedFrameParam;
import im.zego.zego_express_engine.ZGFlutterVideoFlipMode;
import im.zego.zego_express_engine.ZGFlutterVideoFrameParam;

public class CustomVideoRender implements IZegoFlutterCustomVideoRenderHandler {

    @SuppressLint("StaticFieldLeak")
    private static CustomVideoRender instance;

    public static CustomVideoRender getInstance() {
        if (instance == null) {
            synchronized (CustomVideoRender.class) {
                if (instance == null) {
                    instance = new CustomVideoRender();
                }
            }
        }
        return instance;
    }

    @Override
    public void onCapturedVideoFrameRawData(ByteBuffer[] data, int[] dataLength, ZGFlutterVideoFrameParam param, ZGFlutterVideoFlipMode flipMode, ZGFlutterPublishChannel channel) {

    }

    @Override
    public void onRemoteVideoFrameRawData(ByteBuffer[] data, int[] dataLength, ZGFlutterVideoFrameParam param, String streamID) {

    }

    @Override
    public void onRemoteVideoFrameEncodedData(ByteBuffer data, int dataLength, ZGFlutterVideoEncodedFrameParam param, long referenceTimeMillisecond, String streamID) {

    }
}
