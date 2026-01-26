import 'package:faceunity_plugin/faceunity_plugin.dart';

class FaceUnityKit {
  static void setCameraPosition(bool front) async {
    await FaceunityPlugin.setCameraPosition(front);
  }
}