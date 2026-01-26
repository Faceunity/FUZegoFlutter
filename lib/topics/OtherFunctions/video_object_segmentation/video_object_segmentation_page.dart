
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/keycenter.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_log_view.dart';
import 'package:zego_express_example_topics_flutter/utils/user_id_helper.dart';
import 'package:zego_express_example_topics_flutter/utils/token_helper.dart';

class VideoObjectSegmentPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _VideoObjectSegmentPageState();
}

class _VideoObjectSegmentPageState extends State<VideoObjectSegmentPage> {

  final _roomID = 'video_object_segment';
  final _streamID = 'video_object_segment_s';
  final _title = '视频主体分割';

  late bool _enableVideoObjectSegmentation;

  late ZegoRoomState _roomState;
  late ZegoPublisherState _publisherState;
  late ZegoPlayerState _playerState;

  late ZegoObjectSegmentationType _objectSegmentationType;
  late ZegoBackgroundProcessType _backgroundProcessType;
  late ZegoBackgroundBlurLevel _backgroundBlurLevel;

  late ZegoDelegate _zegoDelegate;

  Widget? _previewViewWidget;
  Widget? _playViewWidget;

  late TextEditingController _publishStreamIDController;
  late TextEditingController _playStreamIDController;
  late TextEditingController _backgroundColorController;

  late ZegoObjectSegmentationConfig _objectSegmentationConfig;

  @override
  void initState() {
    super.initState();

    _zegoDelegate = ZegoDelegate();

    _roomState = ZegoRoomState.Disconnected;
    _publisherState = ZegoPublisherState.NoPublish;
    _playerState = ZegoPlayerState.NoPlay;

    _enableVideoObjectSegmentation = false;
    _objectSegmentationType = ZegoObjectSegmentationType.AnyBackground;
    _backgroundBlurLevel = ZegoBackgroundBlurLevel.Medium;
    _backgroundProcessType = ZegoBackgroundProcessType.Transparent;
    _objectSegmentationConfig = ZegoObjectSegmentationConfig.defaultConfig();

    _publishStreamIDController = TextEditingController();
    _publishStreamIDController.text = _streamID;

    _playStreamIDController = TextEditingController();
    _playStreamIDController.text = _streamID;

    _backgroundColorController = TextEditingController();
    _backgroundColorController.text = '000000';

    _zegoDelegate.setZegoEventCallback(
        onRoomStateUpdate: onRoomStateUpdate,
        onPublisherStateUpdate: onPublisherStateUpdate,
        onPlayerStateUpdate: onPlayerStateUpdate);

    _zegoDelegate.createEngine().then((value) {
      _zegoDelegate.enableHardwareEncoder(true);
      _zegoDelegate.enableHardwareDecoder(true);
      _zegoDelegate.loginRoom(_roomID);
    });
  }

  @override
  void dispose() {
    _zegoDelegate.dispose();
    _zegoDelegate.clearZegoEventCallback();
    if (_roomState == ZegoRoomState.Connected) {
      _zegoDelegate
          .logoutRoom(_roomID)
          .then((value) => _zegoDelegate.destroyEngine());
    } else {
      _zegoDelegate.destroyEngine();
    }

    super.dispose();
  }

  void onEnableVideoObjectSegmentationSwitchChanged(bool enable) async {
    _enableVideoObjectSegmentation = enable;
    String colorStr = _backgroundColorController.text.trim();
    int color = int.parse(colorStr, radix: 16);

    String imageName = 'ZegoLogo.png';
    _objectSegmentationConfig.objectSegmentationType = _objectSegmentationType;
    _objectSegmentationConfig.backgroundConfig.color = color;
    _objectSegmentationConfig.backgroundConfig.imageURL = await _writeAssertToLocal(imageName);
    _objectSegmentationConfig.backgroundConfig.processType = _backgroundProcessType;
    _objectSegmentationConfig.backgroundConfig.blurLevel = _backgroundBlurLevel;

    _zegoDelegate.enableVideoObjectSegmentation(enable, _objectSegmentationConfig);

    setState(() {});
  }

  void onUpdateBackgroundConfiguration() {
    onEnableVideoObjectSegmentationSwitchChanged(_enableVideoObjectSegmentation);
  }

  void onObjectSegmentationTypeChanged(ZegoObjectSegmentationType type) {
    _objectSegmentationType = type;

    onEnableVideoObjectSegmentationSwitchChanged(_enableVideoObjectSegmentation);
    
    setState(() {});
  }

  void onBackgroundProcessTypeChanged(ZegoBackgroundProcessType type) {
    _backgroundProcessType = type;

    setState(() {});
  }

  void onBackgroundBlurLevelChanged(ZegoBackgroundBlurLevel level) {
    _backgroundBlurLevel = level;

    setState(() {});
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

  Widget viewWidget() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('resources/images/video_object_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              height: MediaQuery.of(context).size.height * 0.5,
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 15,
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.transparent,
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
                            color: Colors.transparent,
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

  Widget roomInfoWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("RoomID: $_roomID"),
      Text('RoomState: ${_zegoDelegate.roomStateDesc(_roomState)}')
    ]);
  }

  Widget videoObjectSegmentationConfigWidget(context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      child: Column(
        children: [
          Row(children: [
            Text('Enable video object segmentation'),
            Expanded(child: Container()),
            Switch(
              value: _enableVideoObjectSegmentation,
              onChanged: onEnableVideoObjectSegmentationSwitchChanged)
            ],
          ),
          Row(children: [
            Expanded(child: Text('Object segmentation type')),
            DropdownButton(
              value: _objectSegmentationType,
              items: [
                DropdownMenuItem(
                  child: Text("Any", style: TextStyle(fontSize: 12.0)),
                  value: ZegoObjectSegmentationType.AnyBackground,
                ),
                DropdownMenuItem(
                  child: Text("Green Screen", style: TextStyle(fontSize: 12.0)),
                  value: ZegoObjectSegmentationType.GreenScreenBackground
                )
              ],
              onChanged: (ZegoObjectSegmentationType? type) {
                if (type == null) {
                  return;
                }
                onObjectSegmentationTypeChanged(type);
              })
          ]),
          Row(children: [
            Expanded(child: Text('Backgrouund process type')),
            DropdownButton(
              value: _backgroundProcessType,
              items: [
                DropdownMenuItem(
                  child: Text("Transparent", style: TextStyle(fontSize: 12.0)),
                  value: ZegoBackgroundProcessType.Transparent,
                ),
                DropdownMenuItem(
                  child: Text("Color", style: TextStyle(fontSize: 12.0)),
                  value: ZegoBackgroundProcessType.Color,
                ),
                DropdownMenuItem(
                  child: Text("Blur", style: TextStyle(fontSize: 12.0)),
                  value: ZegoBackgroundProcessType.Blur,
                ),
                DropdownMenuItem(
                  child: Text("Image", style: TextStyle(fontSize: 12.0)),
                  value: ZegoBackgroundProcessType.Image,
                ),
              ],
              onChanged: (ZegoBackgroundProcessType? type) {
                if (type == null) {
                  return;
                }
                onBackgroundProcessTypeChanged(type);
              })
          ]),
          Row(children: [
            Expanded(child: Text('Backgrouund color value')),
            Expanded(
              child: TextField(
              controller: _backgroundColorController,
              style: TextStyle(fontSize: 11),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
                  ))
          ]),
          Row(children: [
            Expanded(child: Text('Backgrouund blur level')),
            DropdownButton(
              value: _backgroundBlurLevel,
              items: [
                DropdownMenuItem(
                  child: Text("Low", style: TextStyle(fontSize: 12.0)),
                  value: ZegoBackgroundBlurLevel.Low,
                ),
                DropdownMenuItem(
                  child: Text("Medium", style: TextStyle(fontSize: 12.0)),
                  value: ZegoBackgroundBlurLevel.Medium,
                ),
                DropdownMenuItem(
                  child: Text("High", style: TextStyle(fontSize: 12.0)),
                  value: ZegoBackgroundBlurLevel.High,
                ),
              ],
              onChanged: (ZegoBackgroundBlurLevel? level) {
                if (level == null) {
                  return;
                }
                onBackgroundBlurLevelChanged(level);
              })
          ]),
          Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: CupertinoButton.filled(
                  child: Text('Update Background Configuration',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: onUpdateBackgroundConfiguration,
                  padding: EdgeInsets.all(10.0)))
        ],
      ),
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
          videoObjectSegmentationConfigWidget(context)
        ],
      ),
    );
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

  Future<String> _writeAssertToLocal(String key) async {
    var path = await getApplicationDocumentsDirectory();

    var lacalFilePath = path.path + '/';

    var img = File(lacalFilePath + key);
    if (!img.existsSync()) {
      var data = await rootBundle
          .load('resources/images/$key');
      img = await img.writeAsBytes(data.buffer.asUint8List());
      ZegoLog().addLog(img.path);
      ZegoLog().addLog(img.existsSync().toString());
    }

    return img.path;
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

  final bool _alphaBlend = true;

  late int _preViewID;
  late int _playViewID;

  Widget? preWidget;
  Widget? playWidget;
  ZegoDelegate()
      : _preViewID = -1,
        _playViewID = -1;

  dispose() {
    if (_preViewID != -1) {
      ZegoExpressEngine.instance.destroyCanvasView(_preViewID);
      _preViewID = -1;
    }
    if (_playViewID != -1) {
      ZegoExpressEngine.instance.destroyCanvasView(_playViewID);
      _playViewID = -1;
    }
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

    ZegoExpressEngine.onVideoObjectSegmentationStateChanged = (state, channel, errorCode) {
      ZegoLog().addLog(
          '🚩 📥 Video object segmentation state changed. state: $state, errorCode: $errorCode, channel: $channel');
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

  Future<void> enableHardwareEncoder(bool enable)async {
    await ZegoExpressEngine.instance.enableHardwareEncoder(enable);
    
    ZegoLog().addLog('🚪 Enable hardware encoder, enable: $enable');
  }

  Future<void> enableHardwareDecoder(bool enable)async {
    await ZegoExpressEngine.instance.enableHardwareDecoder(enable);
    
    ZegoLog().addLog('🚪 Enable hardware decoder, enable: $enable');
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
          .startPreview(canvas: ZegoCanvas(viewID, backgroundColor: 0, alphaBlend: _alphaBlend));
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
          canvas: ZegoCanvas(viewID, backgroundColor: 0, alphaBlend: _alphaBlend),
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

  Future<void> enableVideoObjectSegmentation(bool enable, ZegoObjectSegmentationConfig config) async {
    await ZegoExpressEngine.instance
        .enableVideoObjectSegmentation(enable, config, ZegoPublishChannel.Main);
    ZegoLog().addLog('📥 Enable video object segmentation, enable: $enable');
    
    ZegoAlphaLayoutType type = ZegoAlphaLayoutType.Bottom;
    await ZegoExpressEngine.instance.enableAlphaChannelVideoEncoder(enable, type);

    ZegoLog().addLog('📥 Enable alpha channel video encoder, enable: $enable');
  }
}
