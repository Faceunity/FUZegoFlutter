package im.zego.faceunity;

import com.faceunity.core.faceunity.FUAIKit;
import com.faceunity.core.faceunity.FURenderKit;
import com.faceunity.core.model.facebeauty.FaceBeautyBlurTypeEnum;

/**
 * @author benyq
 * @date 2023/4/6
 * @email 1520063035@qq.com
 * 处理有无人脸以及高端机型的 磨皮处理
 */
public class FaceUnityExtension {

    public static int DEVICE_LEVEL = FuDeviceUtils.DEVICE_LEVEL_MID;

    public static void judgeDeviceLeve() {
        DEVICE_LEVEL = FuDeviceUtils.judgeDeviceLevelGPU();
    }

    public static void execute() {
        if (DEVICE_LEVEL > FuDeviceUtils.DEVICE_LEVEL_MID) {
            //高性能设备
            setBlurType();
        }
    }

    private static void setBlurType() {
        //根据有无人脸 + 设备性能 判断开启的磨皮类型
        float faceProcessorGetConfidenceScore = FUAIKit.getInstance().getFaceProcessorGetConfidenceScore(0);
        if (faceProcessorGetConfidenceScore >= 0.95) {
            //高端手机并且检测到人脸开启均匀磨皮，人脸点位质
            if (FURenderKit.getInstance().getFaceBeauty() != null && FURenderKit.getInstance().getFaceBeauty().getBlurType() != FaceBeautyBlurTypeEnum.EquallySkin) {
                FURenderKit.getInstance().getFaceBeauty().setBlurType(FaceBeautyBlurTypeEnum.EquallySkin);
                FURenderKit.getInstance().getFaceBeauty().setEnableBlurUseMask(true);
            }
        } else {
            if (FURenderKit.getInstance().getFaceBeauty() != null && FURenderKit.getInstance().getFaceBeauty().getBlurType() != FaceBeautyBlurTypeEnum.FineSkin) {
                FURenderKit.getInstance().getFaceBeauty().setBlurType(FaceBeautyBlurTypeEnum.FineSkin);
                FURenderKit.getInstance().getFaceBeauty().setEnableBlurUseMask(false);
            }
        }
    }
}
