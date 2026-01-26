package im.zego.zego_express_example_topics_flutter;

import android.annotation.SuppressLint;

import org.json.JSONObject;

import java.nio.ByteBuffer;

import im.zego.zego_express_engine.IZegoFlutterMediaPlayerVideoHandler;
import im.zego.zego_express_engine.ZGFlutterPublishChannel;
import im.zego.zego_express_engine.ZGFlutterVideoFrameParam;
import im.zego.zego_express_engine.ZegoCustomVideoCaptureManager;

public class MediaPlayerVideo implements IZegoFlutterMediaPlayerVideoHandler {

    @SuppressLint("StaticFieldLeak")
    private static MediaPlayerVideo instance;

    public static MediaPlayerVideo getInstance() {
        if (instance == null) {
            synchronized (MediaPlayerVideo.class) {
                if (instance == null) {
                    instance = new MediaPlayerVideo();
                }
            }
        }
        return instance;
    }

    @Override
    public void onVideoFrame(int mediaPlayerIndex, ByteBuffer[] data, int[] dataLength, ZGFlutterVideoFrameParam param, JSONObject extraInfo) {
        ZegoCustomVideoCaptureManager.getInstance().sendRawData(data[0],dataLength[0], param, System.currentTimeMillis(), ZGFlutterPublishChannel.MAIN);
    }
}
