#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "zego_express_engine/ZegoCustomVideoDefine.h"
#include "zego_express_engine/ZegoCustomVideoCaptureManager.h"
#include "zego_express_engine/ZegoMediaPlayerVideoManager.h"
#include "zego_express_engine/ZegoCustomVideoRenderManager.h"
#include "zego_express_engine/ZegoCustomVideoProcessManager.h"

#include <chrono>

class Test : public IZegoFlutterCustomVideoCaptureHandler {
  public:
      virtual void onStart(ZGFlutterPublishChannel channel) override { int a = channel;
    }
      virtual void onStop(ZGFlutterPublishChannel channel) override { int a = channel;
    }
      virtual void onEncodedDataTrafficControl(ZGFlutterTrafficControlInfo trafficControlInfo,
          ZGFlutterPublishChannel channel) override {
          int a = channel;
    }
};

class MediaPlayerTest : public IZegoFlutterMediaPlayerVideoHandler {
  public:
    virtual void onVideoFrame(int mediaPlayerIndex, const unsigned char ** data,
                              unsigned int * dataLength, ZGFlutterVideoFrameParam param) override {
        std::chrono::time_point<std::chrono::system_clock, std::chrono::microseconds> tpMicro =
            std::chrono::time_point_cast<std::chrono::microseconds>(
                std::chrono::system_clock::now());
        time_t totalMicroSeconds = tpMicro.time_since_epoch().count();

        long long currentTime = ((long long)totalMicroSeconds) / 1000;
        ZegoCustomVideoCaptureManager::getInstance()->sendCustomVideoCaptureRawData(
            data[0], dataLength[0], param, currentTime);
    }

    virtual void onVideoFrame(int /*mediaPlayerIndex*/, const unsigned char ** /*data*/,
                              unsigned int * /*dataLength*/, ZGFlutterVideoFrameParam /*param*/,
                              const char * /*extraInfo*/) override {
        int a = 0;
    }
};

class CustomProcess : public IZegoFlutterCustomVideoProcessHandler {
  public:
    virtual void onCapturedUnprocessedRawData(const unsigned char ** data,
                                              unsigned int * dataLength,
                                              ZGFlutterVideoFrameParam param,
                                              unsigned long long referenceTimeMillisecond,
                                              ZGFlutterPublishChannel channel) override {
        ZegoCustomVideoProcessManager::getInstance()->sendCustomVideoProcessedRawData(
            data, dataLength, param, referenceTimeMillisecond, channel);
    }
};

class CustomRender : public IZegoFlutterCustomVideoRenderHandler {
  public:
    virtual void onCapturedVideoFrameRawData(unsigned char ** data,
                                             unsigned int * dataLength,
                                             ZGFlutterVideoFrameParam param,
                                             ZGFlutterVideoFlipMode flipMode,
                                             ZGFlutterPublishChannel channel) override {
        int a = dataLength[0];
    }

    virtual void onRemoteVideoFrameRawData(unsigned char ** data, unsigned int * dataLength,
                                           ZGFlutterVideoFrameParam param,
                                           const std::string & streamID) override {
        int a = dataLength[0];
    }

    virtual void onRemoteVideoFrameEncodedData(const unsigned char* data,
        unsigned int dataLength,
        ZGFlutterVideoEncodedFrameParam param,
        unsigned long long referenceTimeMillisecond,
        const std::string& streamID) override {
        int a = dataLength;
    }
};

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  ZegoCustomVideoCaptureManager::getInstance()->setCustomVideoCaptureHandler(
      std::make_shared<Test>());
  ZegoMediaPlayerVideoManager::getInstance()->setVideoHandler(std::make_shared<MediaPlayerTest>());
  ZegoCustomVideoProcessManager::getInstance()->setCustomVideoProcessHandler(
      std::make_shared<CustomProcess>());
  ZegoCustomVideoRenderManager::getInstance()->setCustomVideoRenderHandler(
      std::make_shared<CustomRender>());
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
