//
//  global_setting_page.dart
//  zego-express-example-topics-flutter
//
//  Created by Patrick Fu on 2020/11/23.
//  Copyright © 2020 Zego. All rights reserved.
//

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/keycenter.dart';

import 'package:zego_express_example_topics_flutter/utils/zego_config.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_log_view.dart';
import 'package:zego_express_example_topics_flutter/utils/user_id_helper.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_utils.dart';

class GlobalSettingPage extends StatefulWidget {
  @override
  _GlobalSettingPageState createState() => _GlobalSettingPageState();
}

class _GlobalSettingPageState extends State<GlobalSettingPage> {
  final TextEditingController _appIDEdController = TextEditingController();
  final TextEditingController _userIDEdController = TextEditingController();
  final TextEditingController _userNameEdController = TextEditingController();
  final TextEditingController _appSignEdController = TextEditingController();
  final TextEditingController _tokenEdController = TextEditingController();

  String _version = '';

  ZegoScenario _scenario = ZegoConfig.instance.scenario;
  bool _enablePlatformView = false;

  bool _isCameraPermissionGranted = false;
  bool _isMicrophonePermissionGranted = false;

  @override
  void initState() {
    super.initState();

    ZegoExpressEngine.getVersion().then((value) {
      setState(() => _version = value);
    });

    if (KeyCenter.instance.appID > 0) {
      _appIDEdController.text = KeyCenter.instance.appID.toString();
    }

    if (UserIdHelper.instance.userID.isNotEmpty) {
      _userIDEdController.text = UserIdHelper.instance.userID;
    }

    _userNameEdController.text = UserIdHelper.instance.userName;

    if (KeyCenter.instance.appSign.isNotEmpty) {
      _appSignEdController.text = KeyCenter.instance.appSign;
    }
    if (KeyCenter.instance.token.isNotEmpty) {
      _tokenEdController.text = KeyCenter.instance.token;
    }

    _enablePlatformView = ZegoConfig.instance.enablePlatformView;

    if (Platform.isAndroid || Platform.isIOS) {
      Permission.camera.status.then((value) => setState(() =>
          _isCameraPermissionGranted = value == PermissionStatus.granted));
      Permission.microphone.status.then((value) => setState(() =>
          _isMicrophonePermissionGranted = value == PermissionStatus.granted));
    } else {
      _isCameraPermissionGranted = true;
      _isMicrophonePermissionGranted = true;
    }
  }

  Future<void> requestCameraPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      PermissionStatus cameraStatus = await Permission.camera.request();
      ZegoLog().addLog('requestCameraPermission:$cameraStatus');
      setState(() => _isCameraPermissionGranted = cameraStatus.isGranted);
    }
  }

  Future<void> requestMicrophonePermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      PermissionStatus microphoneStatus = await Permission.microphone.request();
      ZegoLog().addLog('requestMicrophonePermission:$microphoneStatus');
      setState(
          () => _isMicrophonePermissionGranted = microphoneStatus.isGranted);
    }
  }

  Future<bool?> _onWillPop() {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Do you need to save the settings before exiting?'),
            actions: <Widget>[
              TextButton(
                child: Text('NO, EXIT'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              TextButton(
                child: Text('OK, SAVE'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                  _onSaveButtonClicked();
                },
              ),
            ],
          );
        });
  }

  void _onSaveButtonClicked() {
    String strAppID = _appIDEdController.text.trim();
    String userID = _userIDEdController.text.trim();
    String userName = _userNameEdController.text.trim();
    String appSign = _appSignEdController.text.trim();
    String token = _tokenEdController.text.trim();

    int appID = int.tryParse(strAppID) ?? 0;

    if (!_isCameraPermissionGranted) {
      ZegoUtils.showAlert(context,
          'Camera permission is not granted, please click the camera icon to request permission');
      return;
    }

    if (!_isMicrophonePermissionGranted) {
      ZegoUtils.showAlert(context,
          'Microphone permission is not granted, please click the mic icon to request permission');
      return;
    }

    KeyCenter.instance.appID = appID;
    UserIdHelper.instance.userName = userName;
    UserIdHelper.instance.userID = userID;
    KeyCenter.instance.appSign = appSign;
    KeyCenter.instance.token = token;
    ZegoConfig.instance.scenario = this._scenario;
    ZegoConfig.instance.enablePlatformView = this._enablePlatformView;
  }

  bool get _needAskSave {
    bool needAskSave = false;
    if (!_isCameraPermissionGranted || !_isMicrophonePermissionGranted) {
      needAskSave = true;
    }

    String strAppID = _appIDEdController.text.trim();
    String userID = _userIDEdController.text.trim();
    String userName = _userNameEdController.text.trim();
    String appSign = _appSignEdController.text.trim();
    String token = _tokenEdController.text.trim();

    int appID = int.tryParse(strAppID) ?? 0;
    if (!needAskSave && appID != KeyCenter.instance.appID) {
      needAskSave = true;
    }
    if (!needAskSave && userID != UserIdHelper.instance.userID) {
      needAskSave = true;
    }
    if (!needAskSave && userName != UserIdHelper.instance.userName) {
      needAskSave = true;
    }
    if (!needAskSave && token != KeyCenter.instance.token) {
      needAskSave = true;
    }
    if (!needAskSave && appSign != KeyCenter.instance.appSign) {
      needAskSave = true;
    }
    if (!needAskSave && ZegoConfig.instance.scenario != this._scenario) {
      needAskSave = true;
    }
    if (!needAskSave &&
        ZegoConfig.instance.enablePlatformView != this._enablePlatformView) {
      needAskSave = true;
    }
    return needAskSave;
  }

  // ----- Widgets -----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('Setting'),
        actions: [
          Offstage(
            offstage: kIsWeb,
            child: IconButton(
                icon: Icon(Icons.share),
                onPressed: () => ZegoUtils.shareLog(context)),
          ),
          IconButton(icon: Icon(Icons.save), onPressed: _onSaveButtonClicked)
        ],
      ),
      body: SafeArea(
          child: WillPopScope(
              onWillPop: () async {
                if (!_needAskSave) {
                  return true;
                }
                return await _onWillPop() ?? false;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: <Widget>[
                      appIDWidget(),
                      appSignOrTokenWidget(),
                      userInfoWidget(),
                      checkPermissionWidget(),
                      selectScenarioWidget(),
                      selectRendererWidget(),
                    ],
                  ),
                ),
              ))),
    );
  }

  Widget checkPermissionWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 20.0)),
        Text("Permission status: (Press icon to request)"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                IconButton(
                    icon: _isCameraPermissionGranted
                        ? Icon(Icons.camera_alt)
                        : Icon(Icons.camera_alt_outlined),
                    iconSize: 50.0,
                    onPressed: requestCameraPermission),
                Text(_isCameraPermissionGranted ? '✅' : '❗️')
              ],
            ),
            SizedBox(width: 50),
            Row(
              children: [
                IconButton(
                    icon: _isMicrophonePermissionGranted
                        ? Icon(Icons.mic)
                        : Icon(Icons.mic_none),
                    iconSize: 50.0,
                    onPressed: requestMicrophonePermission),
                Text(_isMicrophonePermissionGranted ? '✅' : '❗️')
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget userInfoWidget() {
    return Column(children: [
      Padding(padding: const EdgeInsets.only(top: 10.0)),
      Row(
        children: <Widget>[
          Text('User ID: '),
          Padding(padding: const EdgeInsets.only(left: 10.0)),
          Expanded(
              child: TextField(
            controller: _userIDEdController,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.only(left: 10.0, top: 12.0, bottom: 12.0),
              hintText: 'Please enter UserID',
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff0e88eb))),
            ),
          )),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10.0),
      ),
      Row(
        children: <Widget>[
          Text('User Name: '),
          Padding(padding: const EdgeInsets.only(top: 10.0)),
          Expanded(
              child: TextField(
            controller: _userNameEdController,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.only(left: 10.0, top: 12.0, bottom: 12.0),
              hintText: 'Please enter UserName',
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff0e88eb))),
            ),
          )),
        ],
      ),
    ]);
  }

  Widget appIDWidget() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.only(top: 20.0)),
        Row(
          children: <Widget>[
            Text('Native SDK Version: '),
            Expanded(child: Text('$_version')),
          ],
        ),
        Row(
          children: <Widget>[
            Text('AppID:'),
            GestureDetector(
              child: Icon(Icons.help_outline),
              onTap: () {
                ZegoUtils.showAlert(context,
                    'Developers can get appID from admin console, please apply on https://console.zego.im/dashboard');
              },
            ),
          ],
        ),
        TextField(
          controller: _appIDEdController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.only(left: 10.0, top: 12.0, bottom: 12.0),
            hintText: 'Please enter AppID',
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xff0e88eb))),
          ),
        ),
      ],
    );
  }

  Widget appSignOrTokenWidget() {
    if (kIsWeb) {
      return _tokenWidget();
    } else {
      return _appSignWidget();
    }
  }

  Widget _appSignWidget() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.only(top: 10.0)),
        Row(
          children: <Widget>[
            Text('AppSign:'),
            GestureDetector(
              child: Icon(Icons.help_outline),
              onTap: () {
                ZegoUtils.showAlert(context,
                    'Developers can get appSign from admin console, please apply on  https://console.zego.im/dashboard');
              },
            ),
          ],
        ),
        TextField(
          controller: _appSignEdController,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.only(left: 10.0, top: 12.0, bottom: 12.0),
            hintText: 'Please enter AppSign',
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xff0e88eb))),
          ),
        ),
      ],
    );
  }

  Widget _tokenWidget() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.only(top: 10.0)),
        Row(
          children: <Widget>[
            Text('Token:'),
            GestureDetector(
              child: Icon(Icons.help_outline),
              onTap: () {
                ZegoUtils.showAlert(context,
                    'Web only support token, Developers can get token from admin console, please apply on  https://console.zego.im/dashboard');
              },
            ),
          ],
        ),
        TextField(
          controller: _tokenEdController,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.only(left: 10.0, top: 12.0, bottom: 12.0),
            hintText: 'Please enter token',
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xff0e88eb))),
          ),
        ),
      ],
    );
  }

  Widget selectScenarioWidget() {
    return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Row(
          children: [
            Text('Scenario'),
            GestureDetector(
              child: Icon(Icons.help_outline),
              onTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Tips'),
                        content: Text(
                            'You should choose the appropriate scenario according to your actual situation, '
                            'for the differences between scenarios and how to choose a suitable scenario, please refer to the document'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Back'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text('Jump'),
                            onPressed: () {
                              launch(
                                  'https://docs.zegocloud.com/article/14940');
                            },
                          )
                        ],
                      );
                    });
              },
            ),
            Spacer(),
            DropdownButton(
                value: _scenario,
                items: ZegoScenario.values.where((element) {
                  var index = ZegoScenario.values.indexOf(element);
                  if (index < 3 || (kIsWeb && (index == 7 || index > 8))) {
                    return false;
                  }
                  return true;
                }).map((value) {
                  return DropdownMenuItem<ZegoScenario>(
                      child: Text(
                        value.toString(),
                      ),
                      value: value);
                }).toList(),
                onChanged: (ZegoScenario? scenario) {
                  if (scenario != null) {
                    setState(() {
                      _scenario = scenario;
                    });
                  }
                })
          ],
        ));
  }

  Widget selectRendererWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 20.0)),
      Text('Rendering options'),
      Text('(Ways to render video frames)', style: TextStyle(fontSize: 10.0)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Offstage(
            offstage: kIsWeb,
            child: ChoiceChip(
              label: Text('TextureRenderer'),
              selected: !this._enablePlatformView,
              onSelected: (value) =>
                  setState(() => this._enablePlatformView = !value),
            ),
          ),
          ChoiceChip(
            label: Text('PlatformView'),
            selected: this._enablePlatformView,
            onSelected: (value) =>
                setState(() => this._enablePlatformView = value),
          ),
        ],
      ),
    ]);
  }
}
