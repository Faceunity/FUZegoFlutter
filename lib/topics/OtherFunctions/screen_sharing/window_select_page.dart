import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class WindowSelectDialog extends StatelessWidget {
  WindowSelectDialog(
      {required this.widowsList,
      required this.iconSize,
      required this.imageSize});

  final Size iconSize;
  final Size imageSize;
  List<ZegoScreenCaptureSourceInfo> widowsList;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Material(
          child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width ~/ imageSize.width,
        children: widowsList.map((value) {
          print(
              'sourceName: ${value.sourceName} iconImage: ${value.iconImage} thumbnailImage: ${value.thumbnailImage}');
          return GestureDetector(
              onTap: () {
                Navigator.of(context).pop(value);
              },
              child: Card(
                child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        value.thumbnailImage != null
                            ? Image(
                                image: value.thumbnailImage!,
                                width: imageSize.width,
                                // height: imageSize.height
                              )
                            : Container(
                                color: Colors.amberAccent,
                              ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            value.iconImage != null
                                ? Image(
                                    image: value.iconImage!,
                                    width: iconSize.width,
                                    height: iconSize.height)
                                : Container(color: Colors.blueAccent),
                            Text(value.sourceName, softWrap: true)
                          ],
                        )
                      ],
                    )),
              ));
        }).toList(),
      )),
    );
  }
}
