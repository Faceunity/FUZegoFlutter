import 'package:faceunity_ui_flutter/faceunity_kit.dart';
import 'package:faceunity_ui_flutter/faceunity_ui_flutter.dart';
import 'package:universal_io/io.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/keycenter.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_log_view.dart';
import 'package:zego_express_example_topics_flutter/utils/user_id_helper.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_utils.dart';
import 'dart:math' as math;

class CustomVideoProcessingPage extends StatefulWidget {
  const CustomVideoProcessingPage({Key? key}) : super(key: key);

  @override
  _CustomVideoProcessingPageState createState() =>
      _CustomVideoProcessingPageState();
}

class _CustomVideoProcessingPageState extends State<CustomVideoProcessingPage> {
  var _roomID = 'custom_video_process';
  var _streamID = 'custom_video_process_s';
  static const _title = '自定义渲染';
  late ZegoRoomState _roomState;
  late ZegoPublisherState _publisherState;
  late ZegoPlayerState _playerState;
  late ZegoVideoBufferType _bufferType;

  Widget? _previewViewWidget;
  Widget? _playViewWidget;

  late ZegoDelegate _zegoDelegate;

  bool showFaceunityWidget = true;
  bool isFrontCamera = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    
    _roomID += "_${(math.Random().nextInt(10000) + 1).toString()}";
    _streamID += "_${(math.Random().nextInt(10000) + 1).toString()}";
    _zegoDelegate = ZegoDelegate();

    _roomState = ZegoRoomState.Disconnected;
    _publisherState = ZegoPublisherState.NoPublish;
    _playerState = ZegoPlayerState.NoPlay;

    _bufferType = ZegoVideoBufferType.GLTexture2D;
    if (Platform.isAndroid) {
      _bufferType = ZegoVideoBufferType.GLTexture2D;
    } else if (Platform.isIOS || Platform.isMacOS) {
      _bufferType = ZegoVideoBufferType.CVPixelBuffer;
    }

    _zegoDelegate.setZegoEventCallback(
        onRoomStateUpdate: onRoomStateUpdate,
        onPublisherStateUpdate: onPublisherStateUpdate,
        onPlayerStateUpdate: onPlayerStateUpdate,
    );
    _zegoDelegate.createEngine().then((value) {
      _zegoDelegate.loginRoom(_roomID);
      _zegoDelegate.enableCustomVideoProcessing(true,
          config: ZegoCustomVideoProcessConfig(_bufferType));
    });
    // 默认使用前置相机
    FaceUnityKit.setCameraPosition(true);
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
    if (streamID == _streamID) {
      setState(() {
        _publisherState = state;
      });
    }
  }

  void onPlayerStateUpdate(String streamID, ZegoPlayerState state,
      int errorCode, Map<String, dynamic> extendedData) {
    if (streamID == _streamID) {
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
        _streamID,
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
      _zegoDelegate.stopPlaying(_streamID);
    } else {
      _zegoDelegate
          .startPlaying(
        _streamID,
      )
          .then((widget) {
        setState(() {
          _playViewWidget = widget;
        });
      });
    }
  }

  void onVideoBufferTypeChanged(ZegoVideoBufferType? type) {
    if (type != null) {
      if ((type != ZegoVideoBufferType.GLTexture2D && Platform.isAndroid) ||
          (type != ZegoVideoBufferType.CVPixelBuffer &&
              (Platform.isIOS || Platform.isMacOS))) {
        ZegoUtils.showAlert(context, 'Demo 暂时不支持');
        ZegoLog().addLog('❌ Demo 暂时不支持');
        return;
      }
      _bufferType = type;
      _zegoDelegate.stopPlaying(_streamID);
      _zegoDelegate.stopPublishing();

      _zegoDelegate.enableCustomVideoProcessing(true,
          config: ZegoCustomVideoProcessConfig(_bufferType));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: Icon(Icons.face, color: showFaceunityWidget ? Colors.blueAccent : Colors.grey,),
            onPressed: () {
              setState(() {
                showFaceunityWidget = !showFaceunityWidget;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: Colors.blueAccent),
            onPressed: () {
              isFrontCamera = !isFrontCamera;
              _zegoDelegate.switchCamera(isFrontCamera).then((value) => FaceUnityKit.setCameraPosition(isFrontCamera));
            },
          ),
        ],
      ),
      body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: mainContent(context),
              ),
              Visibility(child: FaceunityUI(), maintainState: true, visible: showFaceunityWidget,),
            ],
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
          customVideoCaptureWidget(),
        ],
      ),
    );
  }

  Widget roomInfoWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("RoomID: $_roomID"),
      Text('RoomState: ${_zegoDelegate.roomStateDesc(_roomState)}'),
      Text('PublishStreamID: $_streamID'),
      Text('PlayStreamID: $_streamID'),
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

  List<DropdownMenuItem<ZegoVideoBufferType>> get videoBufferTypes {
    if (Platform.isAndroid) {
      return [
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.RawData.toString()),
          value: ZegoVideoBufferType.RawData,
        ),
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.GLTexture2D.toString()),
          value: ZegoVideoBufferType.GLTexture2D,
        ),
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.EncodedData.toString()),
          value: ZegoVideoBufferType.EncodedData,
        ),
      ];
    } else if (Platform.isIOS || Platform.isMacOS) {
      return [
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.GLTexture2D.toString()),
          value: ZegoVideoBufferType.RawData,
        ),
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.CVPixelBuffer.toString()),
          value: ZegoVideoBufferType.CVPixelBuffer,
        ),
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.EncodedData.toString()),
          value: ZegoVideoBufferType.EncodedData,
        ),
      ];
    } else {
      return [
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.RawData.toString()),
          value: ZegoVideoBufferType.RawData,
        ),
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.GLTexture2D.toString()),
          value: ZegoVideoBufferType.GLTexture2D,
        ),
        DropdownMenuItem<ZegoVideoBufferType>(
          child: Text(ZegoVideoBufferType.EncodedData.toString()),
          value: ZegoVideoBufferType.EncodedData,
        ),
      ];
    }
  }

  Widget customVideoCaptureWidget() {
    return Container(
      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        children: [
          Text('VideoBufferType'),
          DropdownButton(
            items: videoBufferTypes,
            onChanged: onVideoBufferTypeChanged,
            value: _bufferType,
          ),
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

  ZegoMediaPlayer? _mediaPlayer;

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
        appSign: KeyCenter.instance.appSign);
    await ZegoExpressEngine.createEngineWithProfile(profile);

    ZegoLog().addLog('🚀 Create ZegoExpressEngine');
  }

  Future<void> destroyEngine() async{
    await ZegoExpressEngine.destroyEngine();
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

  Future<void> switchCamera(bool front) {
    if (Platform.isIOS) {
      if(front){
        ZegoExpressEngine.instance.setVideoMirrorMode(ZegoVideoMirrorMode.BothMirror);
      }else{
        ZegoExpressEngine.instance.setVideoMirrorMode(ZegoVideoMirrorMode.NoMirror);
      }
    }
    return ZegoExpressEngine.instance.useFrontCamera(front);
  }

  Future<void> loginRoom(String roomID) async {
    if (roomID.isNotEmpty) {
      // Instantiate a ZegoUser object
      ZegoUser user = ZegoUser(
          UserIdHelper.instance.userID, UserIdHelper.instance.userName);
      // Login Room
      await ZegoExpressEngine.instance.loginRoom(roomID, user);
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
    var publishFunc = (int viewID) async {
      if (Platform.isIOS) {
        ZegoExpressEngine.instance.setVideoMirrorMode(ZegoVideoMirrorMode.BothMirror);
      }
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
    _mediaPlayer?.stop();
    if (_mediaPlayer != null) {
      ZegoExpressEngine.instance.destroyMediaPlayer(_mediaPlayer!);
    }

    ZegoExpressEngine.instance.stopPreview();
    ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<Widget?> startPlaying(String streamID,
      {String? cdnURL, bool needShow = true, String? roomID}) async {
    var playFunc = (int viewID) {
      ZegoCDNConfig? cdnConfig;
      if (cdnURL != null) {
        cdnConfig = ZegoCDNConfig(cdnURL);
      }

      if (needShow) {
        ZegoExpressEngine.instance.startPlayingStream(streamID,
            canvas: ZegoCanvas(viewID, backgroundColor: 0xffffff),
            config: ZegoPlayerConfig(ZegoStreamResourceMode.Default,
                videoCodecID: ZegoVideoCodecID.Default,
                cdnConfig: cdnConfig,
                roomID: roomID));
      } else {
        ZegoExpressEngine.instance.startPlayingStream(
          streamID,
        );
      }

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

  void enableCustomVideoProcessing(bool enable,
      {ZegoCustomVideoProcessConfig? config, ZegoPublishChannel? channel}) {
    ZegoExpressEngine.instance.enableCustomVideoProcessing(
        enable, ZegoCustomVideoProcessConfig(config!.bufferType));
  }
}
