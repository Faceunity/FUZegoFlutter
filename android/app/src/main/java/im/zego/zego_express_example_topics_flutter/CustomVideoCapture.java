package im.zego.zego_express_example_topics_flutter;

import android.annotation.SuppressLint;
import android.util.Log;

import im.zego.zego_express_engine.IZegoFlutterCustomVideoCaptureHandler;
import im.zego.zego_express_engine.ZGFlutterPublishChannel;
import im.zego.zego_express_engine.ZGFlutterTrafficControlInfo;

public class CustomVideoCapture implements IZegoFlutterCustomVideoCaptureHandler {

    @SuppressLint("StaticFieldLeak")
    private static CustomVideoCapture instance;

    public static CustomVideoCapture getInstance() {
        if (instance == null) {
            synchronized (CustomVideoCapture.class) {
                if (instance == null) {
                    instance = new CustomVideoCapture();
                }
            }
        }
        return instance;
    }

    @Override
    public void onStart(ZGFlutterPublishChannel channel) {
        Log.i("CustomVideoCapture", "start");
    }

    @Override
    public void onStop(ZGFlutterPublishChannel channel) {
        Log.i("CustomVideoCapture", "onStop");
    }

    @Override
    public void onEncodedDataTrafficControl(ZGFlutterTrafficControlInfo trafficControlInfo, ZGFlutterPublishChannel channel) {
        Log.i("CustomVideoCapture", "onEncodedDataTrafficControl");
    }
}
