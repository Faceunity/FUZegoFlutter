package com.faceunity.faceunity_plugin

import android.opengl.EGL14
import android.opengl.GLES20
import android.util.Log
import com.faceunity.core.entity.FURenderInputData
import com.faceunity.core.enumeration.CameraFacingEnum
import com.faceunity.core.enumeration.FUExternalInputEnum
import com.faceunity.core.enumeration.FUInputTextureEnum
import com.faceunity.core.enumeration.FUTransformMatrixEnum
import com.faceunity.core.faceunity.FUAIKit
import com.faceunity.core.faceunity.FURenderKit
import com.faceunity.core.model.facebeauty.FaceBeautyBlurTypeEnum
import com.faceunity.core.program.ProgramTexture2dWithAlpha
import com.faceunity.core.utils.GlUtil
import kotlin.math.abs

/**
 *
 * @author benyq
 * @date 12/5/2023
 *
 */
object FUVideoProcessor {

    private const val TAG = "FUVideoProcessor"

    private var deviceOrientation = 270//手机设备朝向
    private var cameraFacingEnum = CameraFacingEnum.CAMERA_FRONT//相机
    private var enableRender = false
    private var highLeveDeice = false

    private val mTextures = IntArray(1)
    private val mFrameBuffers = IntArray(1)
    private var programTexture2dWithAlpha: ProgramTexture2dWithAlpha? = null

    @JvmStatic
    fun onGLContextCreated() {
        Log.d(TAG, "onGLContextCreated: ${EGL14.eglGetCurrentContext()}")
    }

    /**
     * @param textureId 纹理Id
     * @param width
     * @param height
     */
    @JvmStatic
    fun onProcessVideoFrame(textureId: Int, width: Int, height: Int): Int {
        if (!enableRender || !FaceunityKit.isKitInit) return textureId
        if (highLeveDeice) {
            cheekFaceNum()
        }
        val input : FURenderInputData = FURenderInputData(width, height)
            .apply {
                texture = FURenderInputData.FUTexture(FUInputTextureEnum.FU_ADM_FLAG_COMMON_TEXTURE, textureId)
                renderConfig.apply {
                    externalInputType = FUExternalInputEnum.EXTERNAL_INPUT_TYPE_CAMERA
                    deviceOrientation = this@FUVideoProcessor.deviceOrientation
                    cameraFacing = cameraFacingEnum
                    inputOrientation = FaceunityKit.cameraOrientationMap[cameraFacingEnum] ?: 0
                    if (cameraFacingEnum == CameraFacingEnum.CAMERA_FRONT) {
                        inputTextureMatrix = FUTransformMatrixEnum.CCROT0_FLIPHORIZONTAL
                        inputBufferMatrix = FUTransformMatrixEnum.CCROT0_FLIPHORIZONTAL
                        outputMatrix = FUTransformMatrixEnum.CCROT180
                    }else {
                        inputTextureMatrix = FUTransformMatrixEnum.CCROT0
                        inputBufferMatrix = FUTransformMatrixEnum.CCROT0
                        outputMatrix = FUTransformMatrixEnum.CCROT0_FLIPVERTICAL
                    }
                }
            }
        val newTexId = FURenderKit.getInstance().renderWithInput(input).texture?.texId ?: textureId
        return applyFilter(newTexId, width, height)
    }

    @JvmStatic
    fun onGLContextDestroy() {
        Log.d(TAG, "onGLContextDestroy: ${EGL14.eglGetCurrentContext()}")
        FURenderKit.getInstance().release()
    }

    fun release() {
        mTextures[0] = 0
        mFrameBuffers[0] = 0
        programTexture2dWithAlpha = null
    }

    private fun cheekFaceNum() {
        //根据有无人脸 + 设备性能 判断开启的磨皮类型
        val faceProcessorGetConfidenceScore =
            FUAIKit.getInstance().getFaceProcessorGetConfidenceScore(0)
        if (faceProcessorGetConfidenceScore >= 0.95) {
            //高端手机并且检测到人脸开启均匀磨皮，人脸点位质
            FURenderKit.getInstance().faceBeauty?.let {
                if (it.blurType != FaceBeautyBlurTypeEnum.EquallySkin) {
                    it.blurType = FaceBeautyBlurTypeEnum.EquallySkin
                    it.enableBlurUseMask = true
                }
            }
        } else {
            FURenderKit.getInstance().faceBeauty?.let {
                if (it.blurType != FaceBeautyBlurTypeEnum.FineSkin) {
                    it.blurType = FaceBeautyBlurTypeEnum.FineSkin
                    it.enableBlurUseMask = false
                }
            }
        }
    }

    fun enableRender(enable: Boolean) {
        enableRender = enable
    }


    // 90 -> 0
    // 180 -> 90

    // 0 -> 270
    // 270 -> 180
    fun setDeviceOrientation(deviceOrientation: Int) {
        val newDev = abs(360 + deviceOrientation - 90) % 360
        this.deviceOrientation = newDev
    }

    fun setCameraFacing(front: Boolean) {
        this.cameraFacingEnum = if (front) CameraFacingEnum.CAMERA_FRONT else CameraFacingEnum.CAMERA_BACK
    }

    fun setHighLeveDeice(highLeveDeice: Boolean) {
        this.highLeveDeice = highLeveDeice
    }
    private fun applyFilter(texId: Int, width: Int, height: Int): Int {
        if (mFrameBuffers[0] == 0) {
            GlUtil.createFrameBuffers(mTextures, mFrameBuffers, width, height)
        }
        if (programTexture2dWithAlpha == null) {
            programTexture2dWithAlpha = ProgramTexture2dWithAlpha()
        }
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, mFrameBuffers[0])
        programTexture2dWithAlpha?.drawFrame(texId, GlUtil.IDENTITY_MATRIX, GlUtil.IDENTITY_MATRIX)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        return mTextures[0]
    }
}