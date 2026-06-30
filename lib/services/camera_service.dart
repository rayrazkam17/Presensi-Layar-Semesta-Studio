import 'package:camera/camera.dart';

class CameraService {
  static Future<List<CameraDescription>> getCameras() async {
    return await availableCameras();
  }
}