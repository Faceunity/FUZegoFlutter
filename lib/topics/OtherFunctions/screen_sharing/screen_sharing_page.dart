import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/keycenter.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/screen_sharing/window_select_page.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_log_view.dart';
import 'package:zego_express_example_topics_flutter/utils/user_id_helper.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_utils.dart';
import 'package:zego_express_example_topics_flutter/utils/token_helper.dart';

class ScreenSharingPage extends StatefulWidget {
  const ScreenSharingPage({Key? key}) : super(key: key);

  @override
  _ScreenSharingPageState createState() => _ScreenSharingPageState();
}

class _ScreenSharingPageState extends State<ScreenSharingPage> {
  final _roomID = 'screen_sharing';
  final _streamID = 'screen_sharing_s';
  final _title = '屏幕共享';
  late ZegoRoomState _roomState;
  late ZegoPublisherState _publisherState;
  late ZegoPlayerState _playerState;

  Widget? _previewViewWidget;
  Widget? _playViewWidget;

  late TextEditingController _publishStreamIDController;
  late TextEditingController _playStreamIDController;

  late bool _enableScreenSharing;

  late ZegoDelegate _zegoDelegate;

  // windows mac
  late List<ZegoScreenCaptureSourceInfo> _list;
  late Size _iconSize;
  late Size _imageSize;
  late String _sourceName;
  late String _captureRectInfo;
  late bool _enableCursorVisible;
  late bool _enableWindowActivate;
  late TextEditingController _topEditingController;
  late TextEditingController _leftEditingController;
  late TextEditingController _widthEditingController;
  late TextEditingController _heightEditingController;

  // iOS
  late bool _isApp;
  late bool _isCaptureVideo;
  late bool _isCaptureAudio;
  late TextEditingController _micVolumeEditingController;
  late TextEditingController _appVolumeEditingController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _zegoDelegate = ZegoDelegate();

    _roomState = ZegoRoomState.Disconnected;
    _publisherState = ZegoPublisherState.NoPublish;
    _playerState = ZegoPlayerState.NoPlay;

    _publishStreamIDController = TextEditingController();
    _publishStreamIDController.text = _streamID;

    _playStreamIDController = TextEditingController();
    _playStreamIDController.text = _streamID;

    _enableScreenSharing = false;
    _sourceName = 'Select';
    _captureRectInfo = "0,0,0,0";
    _isApp = true;
    _enableCursorVisible = true;
    _enableWindowActivate = false;
    _topEditingController = TextEditingController();
    _leftEditingController = TextEditingController();
    _widthEditingController = TextEditingController();
    _heightEditingController = TextEditingController();
    _isCaptureVideo = true;
    _isCaptureAudio = true;
    _micVolumeEditingController = TextEditingController(text: '100');
    _appVolumeEditingController = TextEditingController(text: '100');

    _zegoDelegate.setZegoEventCallback(
        onRoomStateUpdate: onRoomStateUpdate,
        onPublisherStateUpdate: onPublisherStateUpdate,
        onPlayerStateUpdate: onPlayerStateUpdate);

    _zegoDelegate.createEngine().then((value) {
      _zegoDelegate.loginRoom(_roomID);
      if (Platform.isAndroid || Platform.isIOS || kIsWeb) {
        _zegoDelegate.createScreenCaptureSource();
      }
    });
  }

  @override
  void dispose() {
    _zegoDelegate.dispose();
    _zegoDelegate.clearZegoEventCallback();
    _zegoDelegate.destroyScreenCaptureSource();
    if (_roomState == ZegoRoomState.Connected) {
      _zegoDelegate
          .logoutRoom(_roomID)
          .then((value) => _zegoDelegate.destroyEngine());
    } else {
      _zegoDelegate.destroyEngine();
    }

    super.dispose();
  }

  // zego express callback

  void onRoomStateUpdate(String roomID, ZegoRoomState state, int errorCode,
      Map<String, dynamic> extendedData) {
    if (roomID == _roomID) {
      setState(() {
        _roomState = state;
      });
    }
  }

  void onPublisherStateUpdate(String streamID, ZegoPublisherState state,
      int errorCode, Map<String, dynamic> extendedData) {
    if (streamID == _publishStreamIDController.text.trim()) {
      setState(() {
        _publisherState = state;
      });
    }
  }

  void onPlayerStateUpdate(String streamID, ZegoPlayerState state,
      int errorCode, Map<String, dynamic> extendedData) {
    if (streamID == _playStreamIDController.text.trim()) {
      setState(() {
        _playerState = state;
      });
    }
  }

  // widget callback

  void onPublishBtnPress() {
    if (_publisherState == ZegoPublisherState.Publishing) {
      _zegoDelegate.stopPublishing();
    } else {
      _zegoDelegate
          .startPublishing(
        _publishStreamIDController.text.trim(),
      )
          .then((widget) {
        setState(() {
          _previewViewWidget = widget;
        });
      });
    }
  }

  void onPlayBtnPress() {
    if (_playerState != ZegoPlayerState.NoPlay) {
      _zegoDelegate.stopPlaying(_playStreamIDController.text.trim());
    } else {
      _zegoDelegate
          .startPlaying(
        _playStreamIDController.text.trim(),
      )
          .then((widget) {
        setState(() {
          _playViewWidget = widget;
        });
      });
    }
  }

  void onEnableScreenSharingSwitchChanged(bool enable) {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS) &&
        !_zegoDelegate.isScreenCaptureCreate()) {
      ZegoUtils.showAlert(context, 'Need Select Capture Window Firt');
      ZegoLog().addLog('Need Select Capture Window Firt');
      return;
    }
    if (enable) {
      _zegoDelegate.setVideoSource(ZegoVideoSourceType.ScreenCapture);
      _zegoDelegate.setAudioSource(ZegoAudioSourceType.ScreenCapture);
      if (Platform.isIOS) {
        var microphoneVolume = int.tryParse(_micVolumeEditingController.text);
        if (microphoneVolume == null) {
          ZegoUtils.showAlert(context, 'mic volume is not int');
          ZegoLog().addLog('mic volume is not int');
          return;
        }
        var applicationVolume = int.tryParse(_appVolumeEditingController.text);
        if (applicationVolume == null) {
          ZegoUtils.showAlert(context, 'app volume is not int');
          ZegoLog().addLog('app volume is not int');
          return;
        }
        _zegoDelegate.startCapture(
            inApp: _isApp,
            config: ZegoScreenCaptureConfig(_isCaptureVideo, _isCaptureAudio,
                microphoneVolume: microphoneVolume, applicationVolume: applicationVolume));
      } else {
        _zegoDelegate.startCapture(config: ZegoScreenCaptureConfig(_isCaptureVideo, _isCaptureAudio));
      }
    } else {
      _zegoDelegate.stopCapture();
      _zegoDelegate.setVideoSource(ZegoVideoSourceType.Camera);
      _zegoDelegate.setAudioSource(ZegoAudioSourceType.Microphone);
    }

    setState(() {
      _enableScreenSharing = enable;
    });
  }

  void onSelectWindowBtnPressed() async {
    double w = MediaQuery.of(context).size.width / 3.5;
    double h = 100;
    _iconSize = Size(20, 20);
    _imageSize = Size(w, h);
    _zegoDelegate
        .getScreenCaptureSources(w.toInt(), h.toInt(), 20, 20)
        .then((value) async {
      _list = value;
      var result = await showDialog<ZegoScreenCaptureSourceInfo>(
          context: context,
          builder: (context) {
            return WindowSelectDialog(
                widowsList: _list, iconSize: _iconSize, imageSize: _imageSize);
          });
      if (result != null) {
        if (_zegoDelegate.isScreenCaptureCreate()) {
          _zegoDelegate.updateCaptureSource(result.sourceID, result.sourceType);
        } else {
          _zegoDelegate.createScreenCaptureSource(
              sourceId: result.sourceID, sourceType: result.sourceType);
        }
        setState(() {
          _sourceName = result.sourceName;
        });
      }
    });
  }

  void onEnableCursorVisibleSwitchChanged(bool enable) {
    setState(() {
      _enableCursorVisible = enable;
    });
    _zegoDelegate.enableCursorVisible(enable);
  }

  void onEnableWindowActivateSwitchChanged(bool enable) {
    setState(() {
      _enableWindowActivate = enable;
    });
    _zegoDelegate.enableWindowActivate(enable);
  }

  void onGetCaptureSourceRect() async {
    Rect rect = await _zegoDelegate.getCaptureSourceRect() ?? Rect.zero;
    setState(() {
      _captureRectInfo = rect.toString();
    });
  }

  void onIsCaptureVideoSwitchChanged(bool enable) {
    setState(() {
      _isCaptureVideo = enable;
    });
  }

  void onIsCaptureAudioSwitchChanged(bool enable) {
    setState(() {
      _isCaptureAudio = enable;
    });
  }

  void onUpdateCaptureRegionBtnPressed() {
    var left = double.tryParse(_leftEditingController.text);
    var top = double.tryParse(_topEditingController.text);
    var width = double.tryParse(_widthEditingController.text);
    var height = double.tryParse(_heightEditingController.text);
    if (left != null && top != null && width != null && height != null) {
      _zegoDelegate
          .updateCaptureRegion(Rect.fromLTWH(left, top, width, height));
    } else {
      ZegoUtils.showAlert(context, 'left or top or width or height not double');
      ZegoLog().addLog('left or top or width or height not double');
    }
  }

  void onisAppSwitchChanged(bool enable) {
    setState(() {
      _isApp = enable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: mainContent(context),
      )),
    );
  }

  Widget mainContent(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: ZegoLogView(),
            height: MediaQuery.of(context).size.height * 0.1,
          ),
          roomInfoWidget(),
          viewWidget(),
          streamIDWidget(context),
          screenSharingWidget(context)
        ],
      ),
    );
  }

  Widget roomInfoWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("RoomID: $_roomID"),
      Text('RoomState: ${_zegoDelegate.roomStateDesc(_roomState)}')
    ]);
  }

  Widget viewWidget() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 15,
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.grey[300],
                            child: _previewViewWidget,
                          ),
                          preWidgetTopWidget()
                        ],
                        alignment: AlignmentDirectional.topCenter,
                      )),
                  Expanded(flex: 1, child: Container()),
                  Expanded(
                      flex: 15,
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.grey[300],
                            child: _playViewWidget,
                          ),
                          playWidgetTopWidget()
                        ],
                        alignment: AlignmentDirectional.topCenter,
                      )),
                ],
              ))
        ],
      ),
    );
  }

  Widget preWidgetTopWidget() {
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
              child: Text('Local Preview View',
                  style: TextStyle(color: Colors.white))),
          Expanded(child: Container()),
          Padding(padding: EdgeInsets.only(top: 5)),
          Container(
              padding: EdgeInsets.only(left: 10),
              width: MediaQuery.of(context).size.width * 0.4,
              child: CupertinoButton.filled(
                  child: Text(
                    _publisherState == ZegoPublisherState.Publishing
                        ? '✅ StopPublishing'
                        : 'StartPublishing',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: onPublishBtnPress,
                  padding: EdgeInsets.all(10.0)))
        ]));
  }

  // Buttons and titles on the play widget
  Widget playWidgetTopWidget() {
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
              child: Text('Remote Play View',
                  style: TextStyle(color: Colors.white))),
          Expanded(child: Container()),
          Padding(padding: EdgeInsets.only(top: 5)),
          Container(
            padding: EdgeInsets.only(left: 10),
            width: MediaQuery.of(context).size.width * 0.4,
            child: CupertinoButton.filled(
                child: Text(
                  _playerState != ZegoPlayerState.NoPlay
                      ? (_playerState == ZegoPlayerState.Playing
                          ? '✅ StopPlaying'
                          : '❌ StopPlaying')
                      : 'StartPlaying',
                  style: TextStyle(fontSize: 14.0),
                ),
                onPressed: onPlayBtnPress,
                padding: EdgeInsets.all(10.0)),
          )
        ]));
  }

  Widget streamIDWidget(context) {
    return Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Row(
          children: [
            Expanded(
                flex: 15,
                child: Row(children: [
                  Text(
                    'Publish StreamID:',
                    style: TextStyle(fontSize: 11),
                  ),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: TextField(
                        controller: _publishStreamIDController,
                        style: TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10.0),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xff0e88eb)))),
                      ))
                ])),
            Expanded(flex: 1, child: Container()),
            Expanded(
                flex: 15,
                child: Row(children: [
                  Text('play StreamID:', style: TextStyle(fontSize: 11)),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: TextField(
                        controller: _playStreamIDController,
                        style: TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10.0),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xff0e88eb)))),
                      ))
                ]))
          ],
        ));
  }

  Widget mobileConfigWidget(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('captureVideo:'),
            Switch(
                value: _isCaptureVideo,
                onChanged: _zegoDelegate.isStart
                    ? null
                    : onIsCaptureVideoSwitchChanged),
            Text('captureAudio:'),
            Switch(
                value: _isCaptureAudio,
                onChanged: _zegoDelegate.isStart
                    ? null
                    : onIsCaptureAudioSwitchChanged),
            ],
        ),        
      ],
    );
  }

  Widget iOSConfigWidget(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('isApp'),
            Switch(
                onChanged: _zegoDelegate.isStart ? null : onisAppSwitchChanged,
                value: _isApp),
          ],
        ),
        Row(
          children: [
            Text('CaptureConfig: '),
            Expanded(child: Container()),
          ],
        ),
        Row(
          children: [
            Text('Mic Volume:'),
            Expanded(
                child: TextField(
              readOnly: _zegoDelegate.isStart,
              controller: _micVolumeEditingController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
            )),
            Text('App Volume:'),
            Expanded(
                child: TextField(
              readOnly: _zegoDelegate._isStart,
              controller: _appVolumeEditingController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
            )),
          ],
        )
      ],
    );
  }

  Widget windowsAndMacConfigWidget(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Select Capture Window'),
            TextButton(
                onPressed: onSelectWindowBtnPressed, child: Text(_sourceName))
          ],
        ),
        Row(
          children: [
            Text('enableCursorVisible'),
            Expanded(child: Container()),
            Switch(
                value: _enableCursorVisible,
                onChanged: onEnableCursorVisibleSwitchChanged)
          ],
        ),
        Row(
          children: [
            Text('enableWindowActivate'),
            Expanded(child: Container()),
            Switch(
                value: _enableWindowActivate,
                onChanged: onEnableWindowActivateSwitchChanged)
          ],
        ),
        Row(
          children: [
            Text('getCaptureSourceRect'),
            Expanded(child: Container()),
            TextButton(
                onPressed: onGetCaptureSourceRect, child: Text(_captureRectInfo))
          ],
        ),
        Row(
          children: [
            Text('Top:'),
            Expanded(
                child: TextField(
              controller: _topEditingController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
            )),
            Text('Left:'),
            Expanded(
                child: TextField(
              controller: _leftEditingController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
            )),
            Text('Width:'),
            Expanded(
                child: TextField(
              controller: _widthEditingController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
            )),
            Text('Hegiht:'),
            Expanded(
                child: TextField(
              controller: _heightEditingController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
            )),
            Expanded(child: Container()),
            TextButton(
                onPressed: onUpdateCaptureRegionBtnPressed,
                child: Text('updateCaptureRegion')),
          ],
        )
      ],
    );
  }

  Widget screenSharingWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Column(
        children: [
          Offstage(
            child: iOSConfigWidget(context),
            offstage: !Platform.isIOS,
          ),
          Offstage(
            child: mobileConfigWidget(context),
            offstage: !(Platform.isIOS || Platform.isAndroid),
          ),
          Offstage(
            child: windowsAndMacConfigWidget(context),
            offstage: !(Platform.isWindows || Platform.isMacOS) || kIsWeb,
          ),
          Row(
            children: [
              Text('Screen Capture'),
              Expanded(child: Container()),
              Switch(
                  value: _enableScreenSharing,
                  onChanged: onEnableScreenSharingSwitchChanged)
            ],
          ),
        ],
      ),
    );
  }
}

typedef RoomStateUpdateCallback = void Function(
    String, ZegoRoomState, int, Map<String, dynamic>);
typedef PublisherStateUpdateCallback = void Function(
    String, ZegoPublisherState, int, Map<String, dynamic>);
typedef PlayerStateUpdateCallback = void Function(
    String, ZegoPlayerState, int, Map<String, dynamic>);

class ZegoDelegate {
  RoomStateUpdateCallback? _onRoomStateUpdate;
  PublisherStateUpdateCallback? _onPublisherStateUpdate;
  PlayerStateUpdateCallback? _onPlayerStateUpdate;

  late int _preViewID;
  late int _playViewID;
  ZegoScreenCaptureSource? screenCaptureSource;
  late bool _isStart;

  Widget? preWidget;
  Widget? playWidget;
  ZegoDelegate()
      : _preViewID = -1,
        _playViewID = -1,
        _isStart = false;

  dispose() {
    if (_preViewID != -1) {
      ZegoExpressEngine.instance.destroyCanvasView(_preViewID);
      _preViewID = -1;
    }
    if (_playViewID != -1) {
      ZegoExpressEngine.instance.destroyCanvasView(_playViewID);
      _playViewID = -1;
    }
    _isStart = false;
  }

  void _initCallback() {
    ZegoExpressEngine.onRoomStateUpdate = (String roomID, ZegoRoomState state,
        int errorCode, Map<String, dynamic> extendedData) {
      ZegoLog().addLog(
          '🚩 🚪 Room state update, state: $state, errorCode: $errorCode, roomID: $roomID');
      _onRoomStateUpdate?.call(roomID, state, errorCode, extendedData);
    };

    ZegoExpressEngine.onPublisherStateUpdate = (String streamID,
        ZegoPublisherState state,
        int errorCode,
        Map<String, dynamic> extendedData) {
      ZegoLog().addLog(
          '🚩 📤 Publisher state update, state: $state, errorCode: $errorCode, streamID: $streamID');
      if (state == ZegoPublisherState.Publishing && errorCode == 0) {
        ZegoLog().addLog('🚩 📥 Publishing stream success');
      }
      if (errorCode != 0) {
        ZegoLog().addLog('🚩 ❌ 📥 Publishing stream fail');
      }
      _onPublisherStateUpdate?.call(streamID, state, errorCode, extendedData);
    };

    ZegoExpressEngine.onPlayerStateUpdate = (String streamID,
        ZegoPlayerState state,
        int errorCode,
        Map<String, dynamic> extendedData) {
      ZegoLog().addLog(
          '🚩 📥 Player state update, state: $state, errorCode: $errorCode, streamID: $streamID');
      if (state == ZegoPlayerState.Playing && errorCode == 0) {
        ZegoLog().addLog('🚩 📥 Playing stream success');
      }
      if (errorCode != 0) {
        ZegoLog().addLog('🚩 ❌ 📥 Playing stream fail');
      }
      _onPlayerStateUpdate?.call(streamID, state, errorCode, extendedData);
    };

    ZegoExpressEngine.onWindowStateChanged = (source, windowState, windowRect) {
      ZegoLog().addLog(
          '🚩 ❌ 📥 windowState: $windowState , windowRect: $windowRect');
      print('🚩 ❌ 📥 windowState: $windowState , windowRect: $windowRect');
    };

    ZegoExpressEngine.onRectChanged = (source, captureRect) {
      ZegoLog().addLog(
          '🚩 ❌ 📥 captureRect: $captureRect');
      print('🚩 ❌ 📥 captureRect: $captureRect');
    };

    ZegoExpressEngine.onMobileScreenCaptureExceptionOccurred =(exceptionType) {
      ZegoLog().addLog('🚩 ❌ 📥 mobile Screen capture exception occurred: $exceptionType');
    };
  }

  void setZegoEventCallback({
    RoomStateUpdateCallback? onRoomStateUpdate,
    PublisherStateUpdateCallback? onPublisherStateUpdate,
    PlayerStateUpdateCallback? onPlayerStateUpdate,
  }) {
    if (onRoomStateUpdate != null) {
      _onRoomStateUpdate = onRoomStateUpdate;
    }
    if (onPublisherStateUpdate != null) {
      _onPublisherStateUpdate = onPublisherStateUpdate;
    }
    if (onPlayerStateUpdate != null) {
      _onPlayerStateUpdate = onPlayerStateUpdate;
    }
  }

  void clearZegoEventCallback() {
    _onRoomStateUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;

    _onPublisherStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;

    _onPlayerStateUpdate = null;
    ZegoExpressEngine.onPlayerStateUpdate = null;
  }

  Future<void> createEngine({bool? enablePlatformView}) async {
    _initCallback();

    await ZegoExpressEngine.destroyEngine();

    enablePlatformView =
        enablePlatformView ?? ZegoConfig.instance.enablePlatformView;
    ZegoLog().addLog("enablePlatformView :$enablePlatformView");
    ZegoEngineProfile profile = ZegoEngineProfile(
        KeyCenter.instance.appID, ZegoConfig.instance.scenario,
        enablePlatformView: enablePlatformView,
        appSign: kIsWeb ? null : KeyCenter.instance.appSign);
    await ZegoExpressEngine.createEngineWithProfile(profile);

    ZegoLog().addLog('🚀 Create ZegoExpressEngine');
  }

  void destroyEngine() {
    ZegoExpressEngine.destroyEngine();
  }

  String roomStateDesc(ZegoRoomState roomState) {
    String result = 'Unknown';
    switch (roomState) {
      case ZegoRoomState.Disconnected:
        result = "Disconnected 🔴";
        break;
      case ZegoRoomState.Connecting:
        result = "Connecting 🟡";
        break;
      case ZegoRoomState.Connected:
        result = "Connected 🟢";
        break;
      default:
        result = "Unknown";
    }
    return result;
  }

  Future<void> loginRoom(String roomID) async {
    if (roomID.isNotEmpty) {
      // Instantiate a ZegoUser object
      ZegoUser user = ZegoUser(
          UserIdHelper.instance.userID, UserIdHelper.instance.userName);

      // Login Room
      if (kIsWeb) {
        ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();
        config.token = await TokenHelper.instance.getToken(roomID);
        // Login Room WEB only supports token;
        ZegoExpressEngine.instance.loginRoom(roomID, user, config: config);
      } else {
        ZegoExpressEngine.instance.loginRoom(roomID, user);
      }

      ZegoLog().addLog('🚪 Start login room, roomID: $roomID');
    }
  }

  Future<void> logoutRoom(String roomID) async {
    if (roomID.isNotEmpty) {
      await ZegoExpressEngine.instance.logoutRoom(roomID);

      ZegoLog().addLog('🚪 Start logout room, roomID: $roomID');
    }
  }

  Future<Widget?> startPublishing(String streamID, {String? roomID}) async {
    var publishFunc = (int viewID) {
      ZegoExpressEngine.instance
          .startPreview(canvas: ZegoCanvas(viewID, backgroundColor: 0xffffff));
      if (roomID != null) {
        ZegoExpressEngine.instance.startPublishingStream(streamID,
            config: ZegoPublisherConfig(roomID: roomID));
      } else {
        ZegoExpressEngine.instance.startPublishingStream(streamID);
      }
      ZegoLog().addLog('📥 Start publish stream, streamID: $streamID');
    };

    if (streamID.isNotEmpty) {
      if (_preViewID == -1) {
        preWidget = await ZegoExpressEngine.instance.createCanvasView((viewID) {
          _preViewID = viewID;
          publishFunc(_preViewID);
        });
      } else {
        publishFunc(_preViewID);
      }
    }
    return preWidget;
  }

  void stopPublishing() {
    ZegoExpressEngine.instance.stopPreview();
    ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<Widget?> startPlaying(String streamID,
      {String? cdnURL, bool needShow = true, String? roomID}) async {
    var playFunc = (int viewID) {
      // playing encryption stream, need rtc or L3
      ZegoExpressEngine.instance.startPlayingStream(streamID,
          canvas: ZegoCanvas(viewID, backgroundColor: 0xffffff),
          config: ZegoPlayerConfig(ZegoStreamResourceMode.OnlyRTC,
              videoCodecID: ZegoVideoCodecID.Default));

      ZegoLog().addLog('📥 Start publish stream, streamID: $streamID');
    };

    if (streamID.isNotEmpty) {
      if (_playViewID == -1 && needShow) {
        playWidget =
            await ZegoExpressEngine.instance.createCanvasView((viewID) {
          _playViewID = viewID;
          playFunc(_playViewID);
        });
      } else {
        playFunc(_playViewID);
      }
    }
    return playWidget;
  }

  void stopPlaying(String streamID) {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }

  Future<List<ZegoScreenCaptureSourceInfo>> getScreenCaptureSources(
      int thumbnailWidth, int thumbnailHeight, int iconWidth, int iconHeight) {
    return ZegoExpressEngine.instance.getScreenCaptureSources(
        thumbnailWidth, thumbnailHeight, iconWidth, iconHeight);
  }

  bool isScreenCaptureCreate() {
    return screenCaptureSource != null;
  }

  void createScreenCaptureSource(
      {int? sourceId, ZegoScreenCaptureSourceType? sourceType}) async {
    screenCaptureSource = await ZegoExpressEngine.instance
        .createScreenCaptureSource(sourceId: sourceId, sourceType: sourceType);
  }

  void destroyScreenCaptureSource() {
    if (screenCaptureSource != null) {
      ZegoExpressEngine.instance
          .destroyScreenCaptureSource(screenCaptureSource!);
      screenCaptureSource = null;
      _isStart = false;
    }
  }

  void setVideoSource(ZegoVideoSourceType source,
      {int? instanceID, ZegoPublishChannel? channel}) {
    if (instanceID == null) {
      instanceID = screenCaptureSource?.getIndex();
    }
    ZegoExpressEngine.instance
        .setVideoSource(source, instanceID: instanceID, channel: channel);
  }

  void setAudioSource(ZegoAudioSourceType source) {
    ZegoExpressEngine.instance.setAudioSource(source);
  }

  void startCapture({ZegoScreenCaptureConfig? config, bool? inApp = true}) {
    screenCaptureSource?.startCapture(config: config, inApp: inApp);
    _isStart = true;
  }

  void stopCapture() {
    screenCaptureSource?.stopCapture();
    _isStart = false;
  }

  void setExcludeWindowList(List<int> list) {
    screenCaptureSource?.setExcludeWindowList(list);
  }

  void enableCursorVisible(bool visible) {
    screenCaptureSource?.enableCursorVisible(visible);
  }

  void enableWindowActivate(bool active) {
    screenCaptureSource?.enableWindowActivate(active);
  }

  Future<Rect?> getCaptureSourceRect() async {
    return await screenCaptureSource?.getCaptureSourceRect();
  }

  void updateCaptureRegion(Rect rect) {
    screenCaptureSource?.updateCaptureRegion(rect);
  }

  void updateCaptureSource(
      int sourceId, ZegoScreenCaptureSourceType sourceType) {
    screenCaptureSource?.updateCaptureSource(sourceId, sourceType);
  }

  void updateScreenCaptureConfig(ZegoScreenCaptureConfig config) {
    screenCaptureSource?.updateScreenCaptureConfig(config);
  }

  bool get isStart => _isStart;
}
