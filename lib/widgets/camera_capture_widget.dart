import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureWidget extends StatefulWidget {

  final Function(Uint8List imageBytes)? onImageCaptured;

  final VoidCallback? onImageReset;

  const CameraCaptureWidget({
    super.key,
    this.onImageCaptured,
    this.onImageReset,
  });

  @override
  State<CameraCaptureWidget> createState() =>
      _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState
    extends State<CameraCaptureWidget> {

  CameraController? controller;

  List<CameraDescription> cameras = [];

  int selectedCameraIndex = 0;

  bool loading = true;

  Uint8List? capturedImage;

  bool imageApproved = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      cameras = await availableCameras();

      print('CAMERAS: $cameras');

      if (cameras.isEmpty) {
        print('Tidak ada kamera');
        return;
      }

      controller = CameraController(
        cameras[selectedCameraIndex],
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );

      print('Controller dibuat');

      await controller!.initialize();

      print('Controller initialized');

      if (!mounted) return;

      setState(() {
        loading = false;
        capturedImage = null;
        imageApproved = false;
      });
    } catch (e, s) {
      print('ERROR CAMERA');
      print(e);
      print(s);

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> capturePhoto() async {
    try {
      if (controller == null) return;

      if (!controller!.value.isInitialized) return;

      final image = await controller!.takePicture();

      final bytes = await image.readAsBytes();

      setState(() {
        capturedImage = bytes;
        imageApproved = false;
      });

    } catch (e) {
      print(e);
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) {
      return;
    }

    setState(() {
      loading = true;
    });

    selectedCameraIndex =
        (selectedCameraIndex + 1) % cameras.length;

    await controller?.dispose();

    controller = CameraController(
      cameras[selectedCameraIndex],
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    await controller!.initialize();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> retakePhoto() async {

    widget.onImageReset?.call();

    setState(() {
      capturedImage = null;
      imageApproved = false;
      loading = true;
    });

    await controller?.dispose();

    controller = null;

    await initCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;

final previewWidth =
    screenWidth > 700
        ? 700.0
        : screenWidth * 0.95;
        
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller == null) {
      return const Center(
        child: Text('Controller NULL'),
      );
    }

    if (!controller!.value.isInitialized) {
      return const Center(
        child: Text('Camera belum initialize'),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        SizedBox(
  width: previewWidth,
  child: Stack(
    children: [

      AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
        decoration: BoxDecoration(
          border: Border.all(),
        ),
        child: capturedImage == null
            ? CameraPreview(controller!)
            : Image.memory(
                capturedImage!,
                fit: BoxFit.cover,
              ),
      ),
    ),

      if (capturedImage == null)
        FloatingActionButton.small(
          heroTag: "switch_camera",
          backgroundColor:
              cameras.length > 1
                  ? Colors.black54
                  : Colors.grey,
          onPressed:
              cameras.length > 1
                  ? switchCamera
                  : null,
          child: Tooltip(
            message: cameras.length > 1
                ? "Ganti Kamera"
                : "Hanya tersedia satu kamera",
            child: const Icon(
              Icons.cameraswitch,
              color: Colors.white,
            ),
          ),
        ),
    ],
  ),
),

        const SizedBox(height: 20),

        if (capturedImage == null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(previewWidth, 55),
            ),
            onPressed: capturePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text("Ambil Foto"),
          ),

        if (capturedImage != null)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [

              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: retakePhoto,
                  child: const Text("Ulangi"),
                ),
              ),

              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () {

                    if (capturedImage != null) {
                      widget.onImageCaptured?.call(capturedImage!);
                    }

                    setState(() {
                      imageApproved = true;
                    });

                  },
                  child: const Text("Gunakan Foto"),
                ),
              ),
            ],
          ),

        if (imageApproved)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              "Foto Dipilih",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.green,
              ),
            ),
          ),
           ],
        ),
      ),
    );
  }
}