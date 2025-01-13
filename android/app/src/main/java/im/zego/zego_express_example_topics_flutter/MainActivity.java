package im.zego.zego_express_example_topics_flutter;

import android.os.Bundle;

import androidx.annotation.Nullable;

import im.zego.zego_express_engine.ZegoCustomVideoCaptureManager;
import im.zego.zego_express_engine.ZegoCustomVideoProcessManager;
import im.zego.zego_express_engine.ZegoCustomVideoRenderManager;
import im.zego.zego_express_engine.ZegoMediaPlayerVideoManager;
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        ZegoCustomVideoCaptureManager.getInstance().setCustomVideoCaptureHandler(CustomVideoCapture.getInstance());
        ZegoCustomVideoProcessManager.getInstance().setCustomVideoProcessHandler(FaceunityVideoProcess.getInstance());
        ZegoCustomVideoRenderManager.getInstance().setCustomVideoRenderHandler(CustomVideoRender.getInstance());
        ZegoMediaPlayerVideoManager.getInstance().setVideoHandler(MediaPlayerVideo.getInstance());
    }
}
