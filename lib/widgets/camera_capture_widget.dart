import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraCaptureWidget extends StatefulWidget {
  final ValueChanged<Uint8List>? onImageCaptured;
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
    extends State<CameraCaptureWidget>
    with WidgetsBindingObserver {
  // =========================================================
  // CAMERA
  // =========================================================

  CameraController? _controller;

  List<CameraDescription> _cameras = const [];

  int _selectedCameraIndex = 0;

  // =========================================================
  // STATE
  // =========================================================

  bool _loading = true;
  bool _capturing = false;
  bool _switchingCamera = false;

  String? _cameraError;

  Uint8List? _capturedImage;

  bool _imageApproved = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeCamera();
  }

  // =========================================================
  // APP LIFECYCLE
  // =========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    }

    if (state == AppLifecycleState.resumed &&
        _cameras.isNotEmpty) {
      _initializeCamera(
        preferredCamera:
            _cameras[_selectedCameraIndex],
        keepCapturedImage: true,
      );
    }
  }

  // =========================================================
  // FIND BEST CAMERA
  // =========================================================

  int _findBestCamera(
    CameraLensDirection direction,
  ) {
    final candidates = <int>[];

    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == direction) {
        candidates.add(i);
      }
    }

    if (candidates.isEmpty) {
      return 0;
    }

    if (candidates.length == 1) {
      return candidates.first;
    }

    int bestIndex = candidates.first;
    int bestScore = -999;

    for (final index in candidates) {
      final name =
          _cameras[index].name.toLowerCase();

      int score = 0;

      // Kamera utama.
      if (name.contains('main')) {
        score += 60;
      }

      if (name.contains('wide')) {
        score += 50;
      }

      if (name.contains('front')) {
        score += 40;
      }

      if (name.contains('back')) {
        score += 40;
      }

      if (name.contains('rear')) {
        score += 40;
      }

      // Hindari kamera tambahan.
      if (name.contains('macro')) {
        score -= 100;
      }

      if (name.contains('tele')) {
        score -= 100;
      }

      if (name.contains('depth')) {
        score -= 100;
      }

      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
    }

    return bestIndex;
  }

  // =========================================================
  // INITIALIZE CAMERA
  // =========================================================

  Future<void> _initializeCamera({
    CameraDescription? preferredCamera,
    bool keepCapturedImage = false,
  }) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _cameraError = null;
      });
    }

    try {
      // =====================================================
      // GET CAMERA LIST
      // =====================================================

      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }

      if (_cameras.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;

          _cameraError =
              'Kamera tidak ditemukan pada perangkat ini.';
        });

        return;
      }

      CameraDescription cameraToUse;

      // =====================================================
      // PREFERRED CAMERA
      // =====================================================

      if (preferredCamera != null) {
        final index = _cameras.indexWhere(
          (camera) =>
              camera.name == preferredCamera.name,
        );

        if (index >= 0) {
          _selectedCameraIndex = index;
        }

        cameraToUse =
            _cameras[_selectedCameraIndex];
      }

      // =====================================================
      // DEFAULT = FRONT CAMERA
      // =====================================================

      else {
        _selectedCameraIndex =
            _findBestCamera(
          CameraLensDirection.front,
        );

        cameraToUse =
            _cameras[_selectedCameraIndex];
      }

      // =====================================================
      // DISPOSE OLD CONTROLLER
      // =====================================================

      final oldController = _controller;

      _controller = null;

      await oldController?.dispose();

      // =====================================================
      // RESOLUTION
      //
      // WEB:
      // low -> meminta 320 x 240 = 4:3.
      //
      // Ini sengaja supaya stream kamera cocok dengan
      // live view portrait 3:4 dan tidak perlu crop besar.
      //
      // Android/iOS native tetap high.
      // =====================================================

      final resolutionPreset =
          kIsWeb
              ? ResolutionPreset.low
              : ResolutionPreset.high;

      final newController =
          CameraController(
        cameraToUse,
        resolutionPreset,
        enableAudio: false,
      );

      _controller = newController;

      await newController.initialize();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        _loading = false;
        _cameraError = null;

        if (!keepCapturedImage) {
          _capturedImage = null;
          _imageApproved = false;
        }
      });
    } on CameraException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _cameraError =
            _cameraErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _cameraError =
            'Gagal membuka kamera: $e';
      });
    }
  }

  // =========================================================
  // CROP FOTO MENJADI 3:4
  // =========================================================

  Uint8List _cropToThreeFour(
    Uint8List bytes,
  ) {
    final decoded =
        img.decodeImage(bytes);

    if (decoded == null) {
      return bytes;
    }

    final source =
        img.bakeOrientation(decoded);

    // =======================================================
    // PASTIKAN ORIENTASI PORTRAIT
    // =======================================================

    img.Image portraitSource = source;

    if (source.width > source.height) {
      portraitSource =
          img.copyRotate(
        source,
        angle: 90,
      );
    }

    const targetRatio = 3 / 4;

    final sourceRatio =
        portraitSource.width /
            portraitSource.height;

    int cropWidth;
    int cropHeight;

    // =======================================================
    // FOTO TERLALU LEBAR
    // =======================================================

    if (sourceRatio > targetRatio) {
      cropHeight =
          portraitSource.height;

      cropWidth =
          (cropHeight * targetRatio)
              .round();
    }

    // =======================================================
    // FOTO TERLALU TINGGI
    // =======================================================

    else {
      cropWidth =
          portraitSource.width;

      cropHeight =
          (cropWidth / targetRatio)
              .round();
    }

    cropWidth =
        cropWidth
            .clamp(
              1,
              portraitSource.width,
            )
            .toInt();

    cropHeight =
        cropHeight
            .clamp(
              1,
              portraitSource.height,
            )
            .toInt();

    final x =
        ((portraitSource.width -
                    cropWidth) /
                2)
            .round();

    final y =
        ((portraitSource.height -
                    cropHeight) /
                2)
            .round();

    final cropped =
        img.copyCrop(
      portraitSource,
      x: x,
      y: y,
      width: cropWidth,
      height: cropHeight,
    );

    return Uint8List.fromList(
      img.encodeJpg(
        cropped,
        quality: 90,
      ),
    );
  }

  // =========================================================
  // CAPTURE
  // =========================================================

  Future<void> _capturePhoto() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _capturing) {
      return;
    }

    setState(() {
      _capturing = true;
      _cameraError = null;
    });

    try {
      final picture =
          await controller.takePicture();

      final originalBytes =
          await picture.readAsBytes();

      final processedBytes =
          _cropToThreeFour(
        originalBytes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _capturedImage =
            processedBytes;

        _imageApproved =
            false;
      });
    } on CameraException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraError =
            'Gagal mengambil foto: '
            '${e.description ?? e.code}';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraError =
            'Gagal mengambil foto: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  // =========================================================
  // SWITCH CAMERA
  // =========================================================

  Future<void> _switchCamera() async {
    if (_switchingCamera ||
        _cameras.length < 2) {
      return;
    }

    setState(() {
      _switchingCamera = true;
      _cameraError = null;
    });

    try {
      final currentCamera =
          _cameras[_selectedCameraIndex];

      final targetDirection =
          currentCamera.lensDirection ==
                  CameraLensDirection.front
              ? CameraLensDirection.back
              : CameraLensDirection.front;

      final targetIndex =
          _findBestCamera(
        targetDirection,
      );

      _selectedCameraIndex =
          targetIndex;

      await _initializeCamera(
        preferredCamera:
            _cameras[targetIndex],
      );
    } finally {
      if (mounted) {
        setState(() {
          _switchingCamera = false;
        });
      }
    }
  }

  // =========================================================
  // RETAKE
  // =========================================================

  void _retakePhoto() {
    widget.onImageReset?.call();

    setState(() {
      _capturedImage = null;
      _imageApproved = false;
      _cameraError = null;
    });
  }

  // =========================================================
  // APPROVE PHOTO
  // =========================================================

  void _approvePhoto() {
    final image =
        _capturedImage;

    if (image == null) {
      return;
    }

    widget.onImageCaptured?.call(
      image,
    );

    setState(() {
      _imageApproved = true;
    });
  }

  // =========================================================
  // CAMERA ERROR MESSAGE
  // =========================================================

  String _cameraErrorMessage(
    CameraException error,
  ) {
    switch (error.code) {
      case 'CameraAccessDenied':
        return 'Izin kamera ditolak. '
            'Izinkan akses kamera lalu coba lagi.';

      case 'CameraAccessDeniedWithoutPrompt':
        return 'Akses kamera pernah ditolak. '
            'Aktifkan izin kamera melalui pengaturan browser.';

      case 'CameraAccessRestricted':
        return 'Akses kamera dibatasi pada perangkat ini.';

      default:
        return 'Kamera tidak dapat digunakan '
            '(${error.code}). '
            '${error.description ?? ''}';
    }
  }

  // =========================================================
  // CAMERA PREVIEW
  //
  // IgnorePointer:
  // Gesture swipe pada kamera tetap bisa digunakan
  // untuk scroll halaman di Safari iOS.
  // =========================================================

  Widget _buildCameraPreview(
    CameraController controller,
  ) {
    return IgnorePointer(
      ignoring: true,
      child: CameraPreview(
        controller,
      ),
    );
  }

  // =========================================================
  // FACE GUIDE
  // =========================================================

  Widget _buildFaceGuide() {
    return IgnorePointer(
      ignoring: true,
      child: Center(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            // =================================================
            // GUIDE TIDAK MOLOr
            // =================================================

            final guideWidth =
                constraints.maxWidth *
                    0.48;

            final guideHeight =
                guideWidth * 1.28;

            return Container(
              width: guideWidth,
              height: guideHeight,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  guideWidth,
                ),
                border: Border.all(
                  color:
                      Colors.white
                          .withValues(
                    alpha: 0.78,
                  ),
                  width: 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // FIXED LIVE VIEW 3:4
  // =========================================================

  Widget _buildCameraFrame(
    CameraController controller,
  ) {
    return AspectRatio(
      // =====================================================
      // PATEN 3:4 PORTRAIT
      // =====================================================

      aspectRatio: 3 / 4,

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(18),

        child: Stack(
          fit: StackFit.expand,

          children: [
            // =================================================
            // LIVE CAMERA
            // =================================================

            if (_capturedImage == null)
              ColoredBox(
                color: Colors.black,

                child:
                    _buildCameraPreview(
                  controller,
                ),
              )

            // =================================================
            // RESULT PHOTO
            // =================================================

            else
              ColoredBox(
                color: Colors.black,

                child: Image.memory(
                  _capturedImage!,

                  // Foto sudah 3:4 sehingga tidak perlu cover.
                  fit: BoxFit.contain,

                  gaplessPlayback: true,
                ),
              ),

            // =================================================
            // FACE GUIDE
            // =================================================

            if (_capturedImage == null)
              _buildFaceGuide(),

            // =================================================
            // SWITCH CAMERA
            // =================================================

            if (_capturedImage == null)
              Positioned(
                top: 10,
                right: 10,

                child: Material(
                  color: Colors.black54,
                  shape:
                      const CircleBorder(),

                  child: IconButton(
                    tooltip:
                        'Ganti Kamera',

                    onPressed:
                        _cameras.length >
                                    1 &&
                                !_switchingCamera
                            ? _switchCamera
                            : null,

                    icon:
                        _switchingCamera
                            ? const SizedBox(
                                width: 18,
                                height: 18,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .cameraswitch_rounded,
                                color:
                                    Colors.white,
                              ),
                  ),
                ),
              ),

            // =================================================
            // BOTTOM INFO
            // =================================================

            Positioned(
              left: 10,
              right: 10,
              bottom: 10,

              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.black54,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: Text(
                    _capturedImage == null
                        ? 'Posisikan wajah di tengah kamera'
                        : 'Periksa foto sebelum digunakan',

                    textAlign:
                        TextAlign.center,

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontWeight:
                          FontWeight.w600,

                      fontSize:
                          12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CAPTURE BUTTON
  // =========================================================

  Widget _buildCaptureButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,

      child: FilledButton.icon(
        onPressed:
            _capturing
                ? null
                : _capturePhoto,

        icon: _capturing
            ? const SizedBox(
                width: 19,
                height: 19,

                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.camera_alt_rounded,
              ),

        label: Text(
          _capturing
              ? 'Mengambil Foto...'
              : 'AMBIL FOTO',
        ),
      ),
    );
  }

  // =========================================================
  // RESULT BUTTONS
  // =========================================================

  Widget _buildResultButtons() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final isSmall =
            constraints.maxWidth < 430;

        // ===================================================
        // MOBILE
        // ===================================================

        if (isSmall) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              SizedBox(
                height: 50,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      _retakePhoto,

                  icon:
                      const Icon(
                    Icons.refresh_rounded,
                  ),

                  label:
                      const Text(
                    'ULANGI FOTO',
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              SizedBox(
                height: 50,

                child:
                    FilledButton.icon(
                  onPressed:
                      _approvePhoto,

                  icon:
                      const Icon(
                    Icons.check_rounded,
                  ),

                  label:
                      const Text(
                    'GUNAKAN FOTO',
                  ),
                ),
              ),
            ],
          );
        }

        // ===================================================
        // DESKTOP
        // ===================================================

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      _retakePhoto,

                  icon:
                      const Icon(
                    Icons.refresh_rounded,
                  ),

                  label:
                      const Text(
                    'Ulangi',
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: SizedBox(
                height: 50,

                child:
                    FilledButton.icon(
                  onPressed:
                      _approvePhoto,

                  icon:
                      const Icon(
                    Icons.check_rounded,
                  ),

                  label:
                      const Text(
                    'Gunakan Foto',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoading() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 35,
      ),

      child: Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            CircularProgressIndicator(),

            SizedBox(
              height: 12,
            ),

            Text(
              'Menyiapkan kamera...',
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildError() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 24,
      ),

      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 420,
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                Icons
                    .no_photography_outlined,

                size: 48,

                color:
                    Theme.of(context)
                        .colorScheme
                        .error,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                _cameraError ??
                    'Kamera belum siap.',

                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 14,
              ),

              FilledButton.icon(
                onPressed:
                    _initializeCamera,

                icon:
                    const Icon(
                  Icons.refresh_rounded,
                ),

                label:
                    const Text(
                  'Coba Lagi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    _controller?.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // =======================================================
    // LOADING
    // =======================================================

    if (_loading) {
      return _buildLoading();
    }

    // =======================================================
    // ERROR
    // =======================================================

    if (_cameraError != null ||
        _controller == null ||
        !_controller!
            .value
            .isInitialized) {
      return _buildError();
    }

    // =======================================================
    // SCREEN SIZE
    // =======================================================

    final media =
        MediaQuery.sizeOf(context);

    final screenWidth =
        media.width;

    final screenHeight =
        media.height;

    final isMobile =
        screenWidth < 700;

    // =======================================================
    // RESPONSIVE CAMERA WIDTH
    //
    // Karena frame sekarang 3:4, jangan terlalu lebar.
    //
    // Tujuan:
    // tombol AMBIL FOTO tetap dekat dan mudah terlihat.
    // =======================================================

    final double cameraWidth;

    if (isMobile) {
      // HP sangat pendek.
      if (screenHeight < 650) {
        cameraWidth = 225;
      }

      // iPhone kecil / SE.
      else if (screenHeight < 740) {
        cameraWidth = 240;
      }

      // HP medium.
      else if (screenHeight < 850) {
        cameraWidth = 255;
      }

      // HP modern / tinggi.
      else {
        cameraWidth = 270;
      }
    }

    // Tablet / desktop.
    else {
      cameraWidth = 390;
    }

    // =======================================================
    // CAMERA CONTENT
    // =======================================================

    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(
          maxWidth: cameraWidth,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            // =================================================
            // FIXED 3:4 LIVE VIEW
            // =================================================

            _buildCameraFrame(
              _controller!,
            ),

            const SizedBox(
              height: 10,
            ),

            // =================================================
            // CAPTURE / RESULT BUTTON
            // =================================================

            if (_capturedImage == null)
              _buildCaptureButton()
            else
              _buildResultButtons(),

            // =================================================
            // PHOTO APPROVED
            // =================================================

            if (_imageApproved) ...[
              const SizedBox(
                height: 10,
              ),

              Container(
                padding:
                    const EdgeInsets.all(
                  10,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.green
                          .withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),

                  border:
                      Border.all(
                    color:
                        Colors.green
                            .withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),

                child:
                    const Row(
                  children: [
                    Icon(
                      Icons
                          .verified_rounded,

                      color:
                          Colors.green,

                      size: 20,
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        'Foto siap digunakan',

                        style:
                            TextStyle(
                          color:
                              Colors.green,

                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(
              height: 14,
            ),
          ],
        ),
      ),
    );
  }
}