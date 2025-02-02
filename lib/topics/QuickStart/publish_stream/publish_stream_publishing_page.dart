import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/topics/QuickStart/publish_stream/publish_stream_settings_page.dart';

import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_log_view.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_utils.dart';

class PublishStreamPublishingPage extends StatefulWidget {
  final int screenWidthPx;
  final int screenHeightPx;
  final String roomID;

  PublishStreamPublishingPage(
      this.screenWidthPx, this.screenHeightPx, this.roomID);

  @override
  _PublishStreamPublishingPageState createState() =>
      _PublishStreamPublishingPageState();
}

class _PublishStreamPublishingPageState
    extends State<PublishStreamPublishingPage> {
  String _title = 'PublishStream';
  bool _isPublishing = false;

  int _previewViewID = -1;
  Widget? _previewViewWidget;
  late ZegoCanvas _previewCanvas;

  int _publishWidth = 0;
  int _publishHeight = 0;
  double _publishVideoFPS = 0.0;
  double _publishAudioFPS = 0.0;
  double _publishVideoBitrate = 0.0;
  double _publishAudioBitrate = 0.0;
  double _totalSendBytes = 0;
  int _rtt = 0;
  bool _isHardwareEncode = false;
  String _videoCodecID = '';
  String _networkQuality = '';

  bool _isUseMic = true;
  bool _isUseFrontCamera = true;
  bool _isEnableCamera = true;
  bool _isEnableWatermark = false;

  String? _appDocumentsPath;

  TextEditingController _streamIdTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _streamIdTextController.text = '0002';

    setPublisherCallback();

    if (_previewViewID == -1) {
      ZegoExpressEngine.instance.createCanvasView((viewID) {
        _previewViewID = viewID;
        startPreview(_previewViewID);
      }).then((widget) {
        _previewViewWidget = widget;
        setState(() {});
      });
    } else {
      startPreview(_previewViewID);
    }

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        getExternalStorageDirectories(type: StorageDirectory.pictures)
            .then((dir) => _appDocumentsPath = dir?.first.path);
      } else {
        getApplicationDocumentsDirectory()
            .then((dir) => _appDocumentsPath = dir.path);
      }
    }

    ZegoExpressEngine.instance.setDummyCaptureImagePath("flutter-asset://resources/images/ZegoLogo.png", ZegoPublishChannel.Main);
  }

  void setPublisherCallback() {
    // Set the publisher state callback
    ZegoExpressEngine.onPublisherStateUpdate = (String streamID,
        ZegoPublisherState state,
        int errorCode,
        Map<String, dynamic> extendedData) {
      ZegoLog().addLog(
          '🚩 [onPublisherStateUpdate] streamID: $streamID, state: $state, error: $errorCode, extendedData: $extendedData');

      if (errorCode == 0) {
        setState(() {
          _isPublishing = true;
          _title = 'Publishing';
        });
      } else {
        ZegoLog()
            .addLog('🚩 [onPublisherStateUpdate] Publish error: $errorCode');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'onPublisherStateUpdate, state: $state, errorCode: $errorCode')));
      }
    };

    // Set the publisher quality callback
    ZegoExpressEngine.onPublisherQualityUpdate =
        (String streamID, ZegoPublishStreamQuality quality) {
      setState(() {
        _publishVideoFPS = quality.videoSendFPS;
        _publishAudioFPS = quality.audioSendFPS;
        _publishVideoBitrate = quality.videoKBPS;
        _publishAudioBitrate = quality.audioKBPS;
        _totalSendBytes = quality.totalSendBytes;
        _rtt = quality.rtt;
        _isHardwareEncode = quality.isHardwareEncode;
        _videoCodecID = quality.videoCodecID.toString();

        switch (quality.level) {
          case ZegoStreamQualityLevel.Excellent:
            _networkQuality = '☀️';
            break;
          case ZegoStreamQualityLevel.Good:
            _networkQuality = '⛅️️';
            break;
          case ZegoStreamQualityLevel.Medium:
            _networkQuality = '☁️';
            break;
          case ZegoStreamQualityLevel.Bad:
            _networkQuality = '🌧';
            break;
          case ZegoStreamQualityLevel.Die:
            _networkQuality = '❌';
            break;
          default:
            break;
        }
      });
    };

    // Set the publisher video size changed callback
    ZegoExpressEngine.onPublisherVideoSizeChanged =
        (int width, int height, ZegoPublishChannel channel) {
      ZegoLog().addLog(
          '🚩 [onPublisherVideoSizeChanged] width: $width, height: $height, channel: $channel');
      setState(() {
        _publishWidth = width;
        _publishHeight = height;
      });
    };

    ZegoExpressEngine.onPublisherCapturedAudioFirstFrame = () {
      ZegoLog().addLog('🚩 [onPublisherCapturedAudioFirstFrame]');
    };

    ZegoExpressEngine.onPublisherCapturedVideoFirstFrame =
        (ZegoPublishChannel channel) {
      ZegoLog()
          .addLog('🚩 [onPublisherCapturedVideoFirstFrame] channel: $channel');
    };

    ZegoExpressEngine.onPublisherSendAudioFirstFrame = (ZegoPublishChannel channel) {
      ZegoLog().addLog('🚩 [onPublisherSendAudioFirstFrame] channel: $channel');
    };

    ZegoExpressEngine.onPublisherSendVideoFirstFrame =
        (ZegoPublishChannel channel) {
      ZegoLog()
          .addLog('🚩 [onPublisherSendVideoFirstFrame] channel: $channel');
    };

    ZegoExpressEngine.onPublisherRelayCDNStateUpdate =
        (String streamID, List<ZegoStreamRelayCDNInfo> infoList) {
      ZegoLog().addLog(
          '🚩 [onPublisherRelayCDNStateUpdate] streamID: $streamID, infoList: $infoList');
    };

    ZegoExpressEngine.onPublisherDummyCaptureImagePathError =(errorCode, path, channel) {
      ZegoLog().addLog(
          '🚩 [onPublisherDummyCaptureImagePathError] errorCode: $errorCode, path: $path, channel: $channel');
    };
  }

  void startPreview(int viewID) {
    // Set the preview canvas
    _previewCanvas = ZegoCanvas.view(viewID);
    _previewCanvas.viewMode = ZegoViewMode.AspectFit;

    // Start preview
    ZegoExpressEngine.instance.startPreview(canvas: _previewCanvas);
  }

  @override
  void dispose() {
    super.dispose();

    if (_isPublishing) {
      // Stop publishing
      ZegoExpressEngine.instance.stopPublishingStream();
    }

    // Stop preview
    ZegoExpressEngine.instance.stopPreview();

    ZegoExpressEngine.instance.enableCamera(true);

    // Unregister publisher callback
    ZegoExpressEngine.onPublisherStateUpdate = null;
    ZegoExpressEngine.onPublisherQualityUpdate = null;
    ZegoExpressEngine.onPublisherVideoSizeChanged = null;
    ZegoExpressEngine.onPublisherCapturedAudioFirstFrame = null;
    ZegoExpressEngine.onPublisherCapturedVideoFirstFrame = null;
    ZegoExpressEngine.onPublisherRelayCDNStateUpdate = null;

    if (_previewViewID != -1) {
      ZegoExpressEngine.instance.destroyCanvasView(_previewViewID);
      _previewViewID = -1;
    }
    // Logout room
    ZegoExpressEngine.instance.logoutRoom(widget.roomID);
  }

  void onPublishButtonPressed() {
    String streamID = _streamIdTextController.text.trim();

    // Start publishing stream
    ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  void onCameraStateChanged() {
    setState(() {
      _isEnableCamera = !_isEnableCamera;
    });
    ZegoExpressEngine.instance.enableCamera(_isEnableCamera);
  }

  void onFrontCameraStateChanged() {
    setState(() {
      _isUseFrontCamera = !_isUseFrontCamera;
    });
    ZegoExpressEngine.instance.useFrontCamera(_isUseFrontCamera);
  }

  void onMicStateChanged() {
    setState(() {
      _isUseMic = !_isUseMic;
    });
    ZegoExpressEngine.instance.muteMicrophone(!_isUseMic);
  }

  void onSnapshotButtonClicked() {
    ZegoExpressEngine.instance.takePublishStreamSnapshot().then((result) {
      ZegoLog().addLog(
          '[takePublishStreamSnapshot], errorCode: ${result.errorCode}, is null image?: ${result.image != null ? "false" : "true"}');
      String path = _appDocumentsPath != null
          ? _appDocumentsPath! +
              '/' +
              'tmp_snapshot_${DateTime.now().microsecondsSinceEpoch}.png'
          : '';
      ZegoUtils.showImage(context, result.image, path: path);
    });
  }

  void onWatermarkButtonClicked() {
    setState(() {
      _isEnableWatermark = !_isEnableWatermark;
    });
    String imagePath = 'flutter-asset://' + 'resources/images/ZegoLogo.png';

    ZegoWatermark watermark =
        ZegoWatermark(imagePath, Rect.fromLTRB(0, 0, 192, 36));
    ZegoExpressEngine.instance.setPublishWatermark(
        watermark: _isEnableWatermark ? watermark : null,
        isPreviewVisible: true);
  }

  Widget prepareToolWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
            ),
            Row(
              children: <Widget>[
                Text(
                  'StreamID: ',
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
            ),
            TextField(
              controller: _streamIdTextController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                      left: 10.0, top: 12.0, bottom: 12.0),
                  hintText: 'Please enter streamID',
                  hintStyle:
                      TextStyle(color: Color.fromRGBO(255, 255, 255, 0.8)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
            ),
            Text(
              'StreamID must be globally unique and the length should not exceed 255 bytes',
              style: TextStyle(color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
            ),
            Container(
              padding: const EdgeInsets.all(0.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Color(0xee0e88eb),
              ),
              width: 240.0,
              height: 60.0,
              child: CupertinoButton(
                child: Text(
                  'Start Publishing',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: onPublishButtonPressed,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget publishingToolWidget() {
    return Container(
      padding: EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          bottom: MediaQuery.of(context).padding.bottom + 20.0),
      child: Column(
        children: <Widget>[
          SizedBox(height: 10),
          Column(
            children: [
              Row(children: <Widget>[
                Text(
                  'RoomID: ${widget.roomID} |  StreamID: ${_streamIdTextController.text.trim()}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'Rendering with: ${ZegoConfig.instance.enablePlatformView ? 'PlatformView' : 'TextureRenderer'}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'Resolution: $_publishWidth x $_publishHeight',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'VideoSendFPS: ${_publishVideoFPS.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'AudioSendFPS: ${_publishAudioFPS.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'VideoBitrate: ${_publishVideoBitrate.toStringAsFixed(2)} kb/s',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'AudioBitrate: ${_publishAudioBitrate.toStringAsFixed(2)} kb/s',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'TotalSendBytes: ${(_totalSendBytes / 1024 / 1024).toStringAsFixed(2)} MB',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'RTT: $_rtt ms',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'HardwareEncode: ${_isHardwareEncode ? '✅' : '❎'}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'VideoCodecID: $_videoCodecID',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
              Row(children: <Widget>[
                Text(
                  'NetworkQuality: $_networkQuality',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ]),
            ],
          ),
          Expanded(child: SizedBox()),
          Row(
            children: <Widget>[
              SizedBox(width: 10.0),
              CupertinoButton(
                padding: const EdgeInsets.all(0.0),
                pressedOpacity: 1.0,
                borderRadius: BorderRadius.circular(0.0),
                child: Icon(
                    _isEnableCamera
                        ? Icons.camera_enhance
                        : Icons.camera_enhance_outlined,
                    size: 44.0,
                    color: Colors.white),
                onPressed: onCameraStateChanged,
              ),
              SizedBox(width: 10.0),
              CupertinoButton(
                padding: const EdgeInsets.all(0.0),
                pressedOpacity: 1.0,
                borderRadius: BorderRadius.circular(0.0),
                child: Icon(
                    _isUseFrontCamera
                        ? Icons.flip_camera_android
                        : Icons.flip_camera_android_outlined,
                    size: 44.0,
                    color: Colors.white),
                onPressed: onFrontCameraStateChanged,
              ),
              SizedBox(width: 10.0),
              Offstage(
                offstage: kIsWeb,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(0.0),
                  pressedOpacity: 1.0,
                  borderRadius: BorderRadius.circular(0.0),
                  child: Icon(_isUseMic ? Icons.mic : Icons.mic_none,
                      size: 44.0, color: Colors.white),
                  onPressed: onMicStateChanged,
                ),
              ),
              SizedBox(width: 10.0),
              Offstage(
                offstage: kIsWeb,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(0.0),
                  pressedOpacity: 1.0,
                  borderRadius: BorderRadius.circular(0.0),
                  child: Icon(Icons.camera, size: 44.0, color: Colors.white),
                  onPressed: onSnapshotButtonClicked,
                ),
              ),
              SizedBox(width: 10.0),
              Offstage(
                offstage: kIsWeb,
                child: CupertinoButton(
                  padding: const EdgeInsets.all(0.0),
                  pressedOpacity: 1.0,
                  borderRadius: BorderRadius.circular(0.0),
                  child: Icon(
                      _isEnableWatermark
                          ? Icons.branding_watermark_outlined
                          : Icons.branding_watermark,
                      size: 44.0,
                      color: Colors.white),
                  onPressed: onWatermarkButtonClicked,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void onSettingsButtonClicked() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) {
              return PublishStreamSettingsPage();
            },
            fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text(_title)),
        floatingActionButton: Offstage(
          offstage: kIsWeb,
          child: CupertinoButton(
              padding: const EdgeInsets.all(0.0),
              pressedOpacity: 1.0,
              borderRadius: BorderRadius.circular(0.0),
              child: Icon(Icons.settings, size: 44, color: Colors.white),
              onPressed: onSettingsButtonClicked),
        ),
        body: Stack(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              child: _previewViewWidget,
            ),
            _isPublishing ? publishingToolWidget() : prepareToolWidget(),
          ],
        ));
  }
}
