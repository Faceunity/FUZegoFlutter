import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_express_example_topics_flutter/topics/OtherFunctions/media_player/media_player.dart';
import 'package:zego_express_example_topics_flutter/utils/zego_log_view.dart';

class MediaPlayerResourceSelectionPage extends StatefulWidget {
  const MediaPlayerResourceSelectionPage({Key? key}) : super(key: key);

  @override
  _MediaPlayerResourceSelectionPageState createState() =>
      _MediaPlayerResourceSelectionPageState();
}

class _MediaPlayerResourceSelectionPageState
    extends State<MediaPlayerResourceSelectionPage> {
  final _netResource = {
    "sample_bgm.mp3": "https://storage.zego.im/demo/sample_astrix.mp3",
    "sample_network.mp4": "https://storage.zego.im/demo/201808270915.mp4"
  };
  var _localResource = <String, String>{};
  var _localResourceType = <String, ZegoAlphaLayoutType>{};
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    var pre = kIsWeb ? './assets/' : 'assert://';
    _localResource = {
      "sample.mp3": "${pre}resources/audio/sample2.mp3",
      "test.wav": "${pre}resources/audio/test2.wav",
      "ad.mp4": "${pre}resources/video/ad2.mp4",
      "complex_lr.mp4": "${pre}resources/video/complex_lr.mp4",
    };
    _localResourceType = {
      "sample.mp3": ZegoAlphaLayoutType.None,
      "test.wav": ZegoAlphaLayoutType.None,
      "ad.mp4": ZegoAlphaLayoutType.None,
      "complex_lr.mp4": ZegoAlphaLayoutType.Right,
    };
    if (!kIsWeb) {
      _writeAssertToLocal();
    }
  }

  Widget resourceListWidget(BuildContext context, Map map) {
    return SizedBox(
        height: map.length * 45.0,
        child: ListView.separated(
            padding: EdgeInsets.all(0),
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              String text = map.keys.toList()[index];
              return SizedBox(
                  height: 40,
                  child: TextButton(
                      child: Container(
                          padding: EdgeInsets.only(left: 20),
                          alignment: Alignment.centerLeft,
                          height: 40,
                          width: MediaQuery.of(context).size.width,
                          child: Text(text)),
                      onPressed: () {
                        ZegoLog().addLog("${map[text]}");
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (BuildContext context) {
                          return MediaPlayerPage(
                            url: map[text],
                            layoutType: _localResourceType[text] ?? ZegoAlphaLayoutType.None,
                            isVideo: text.contains("mp4"),
                          );
                        }));
                      }));
            },
            separatorBuilder: (context, index) {
              return Divider(
                height: 4,
              );
            },
            itemCount: map.length));
  }

  Widget titleWidget(BuildContext context, String title) {
    return ListTile(
        tileColor: Colors.grey[300],
        title: Text(
          title,
          style: TextStyle(color: Colors.grey[600]),
        ));
  }

  Widget urlInputWidget() {
    return Padding(
        padding: EdgeInsets.only(left: 15),
        child: Row(
          children: [
            Padding(padding: EdgeInsets.only(right: 20), child: Text('URL')),
            Expanded(
                child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(10.0),
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff0e88eb)))),
            )),
            TextButton(onPressed: () {}, child: Text("ENTER"))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    var appWidget = kIsWeb ? [] : [urlInputWidget()];
    return Scaffold(
        appBar: AppBar(
          title: Text('Select Resource'),
        ),
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(
          children: [
            titleWidget(context, "net resource"),
            resourceListWidget(context, _netResource),
            titleWidget(context, "loacl resource"),
            resourceListWidget(context, _localResource),
            ...appWidget
          ],
        ))));
  }

  void _writeAssertToLocal() async {
    var path = await getApplicationDocumentsDirectory();

    var lacalFilePath = path.path + '/';

    for (var key in _localResource.keys) {
      var img = File(lacalFilePath + key);
      if (!img.existsSync()) {
        var data = await rootBundle
            .load('resources/${key.contains('mp4') ? 'video' : 'audio'}/$key');
        img = await img.writeAsBytes(data.buffer.asUint8List());
        ZegoLog().addLog(img.path);
        ZegoLog().addLog(img.existsSync().toString());
      }
      _localResource[key] = img.path;
    }
    setState(() {});
  }
}
