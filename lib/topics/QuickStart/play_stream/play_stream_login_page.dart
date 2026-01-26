import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/keycenter.dart';
import 'package:zego_express_example_topics_flutter/topics/QuickStart/play_stream/play_stream_page.dart';
import 'package:zego_express_example_topics_flutter/utils/token_helper.dart';

import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/utils/user_id_helper.dart';

class PlayStreamLoginPage extends StatefulWidget {
  @override
  _PlayStreamLoginPageState createState() => _PlayStreamLoginPageState();
}

class _PlayStreamLoginPageState extends State<PlayStreamLoginPage> {
  final TextEditingController _roomIdTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _roomIdTextController.text = '0002';
  }

  @override
  void dispose() {
    super.dispose();

    // Can destroy the engine when you don't need audio and video calls
    //
    // Destroy engine will automatically logout room and stop publishing/playing stream.
    ZegoExpressEngine.destroyEngine();
  }

  // Step1: Create ZegoExpressEngine
  Future<void> _createEngine() async {
    ZegoEngineProfile profile = ZegoEngineProfile(
        KeyCenter.instance.appID, ZegoConfig.instance.scenario,
        enablePlatformView: ZegoConfig.instance.enablePlatformView,
        appSign: kIsWeb ? null : KeyCenter.instance.appSign);
    await ZegoExpressEngine.createEngineWithProfile(profile);
  }

  // Step2 LoginRoom
  Future<void> _loginRoom() async {
    String roomID = _roomIdTextController.text.trim();

    ZegoUser user =
        ZegoUser(UserIdHelper.instance.userID, UserIdHelper.instance.userName);

    ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();
    if (kIsWeb) {
      config.token = await TokenHelper.instance.getToken(roomID);
      config.isUserStatusNotify = true;
    }

    var result = await ZegoExpressEngine.instance
        .loginRoom(roomID, user, config: config);
    if (result.errorCode == 0) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (BuildContext context) {
        int screenWidthPx = MediaQuery.of(context).size.width.toInt() *
            MediaQuery.of(context).devicePixelRatio.toInt();
        int screenHeightPx = (MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    56.0)
                .toInt() *
            MediaQuery.of(context).devicePixelRatio.toInt();

        return PlayStreamPage(screenWidthPx, screenHeightPx, roomID);
      }));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录房间失败, errorCode: ${result.errorCode}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PlayStream'),
      ),
      body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                ),
                Row(
                  children: <Widget>[
                    Text('RoomID: '),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                ),
                TextField(
                  controller: _roomIdTextController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(
                        left: 10.0, top: 12.0, bottom: 12.0),
                    hintText: 'Please enter the room ID:',
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      color: Colors.grey,
                    )),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                      color: Color(0xff0e88eb),
                    )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                ),
                Text(
                  'RoomID represents the identification of a room, it needs to ensure that the RoomID is globally unique, and no longer than 255 bytes',
                  maxLines: 2,
                  style: TextStyle(fontSize: 12.0, color: Colors.black45),
                  // maxLines: 2,
                  softWrap: true,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                ),
                Container(
                  padding: const EdgeInsets.all(0.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Color(0xff0e88eb),
                  ),
                  width: 240.0,
                  height: 60.0,
                  child: CupertinoButton(
                    child: Text(
                      'Login Room',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      await _createEngine();
                      await _loginRoom();
                    },
                  ),
                )
              ],
            ),
          )),
    );
  }
}
