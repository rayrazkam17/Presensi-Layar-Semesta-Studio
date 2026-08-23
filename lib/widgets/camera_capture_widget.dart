import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraCaptureWidget extends StatefulWidget {
  final ValueChanged<Uint8List>? onImageCaptured;
  final VoidCallback? onImageReset;

  const CameraCaptureWidget({
    super.key,
    this.onImageCaptured,
    this.onImageReset,
  });

  @override
  State<CameraCaptureWidget> createState() => _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState extends State<CameraCaptureWidget>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];

  int _selectedCameraIndex = 0;

  bool _loading = true;
  bool _capturing = false;
  bool _switchingCamera = false;

  String? _cameraError;

  Uint8List? _capturedImage;
  bool _imageApproved = false;

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;

    if (cameraController == null ||
        !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed &&
        _cameras.isNotEmpty) {
      _initializeCamera(
        preferredCamera: _cameras[_selectedCameraIndex],
        keepCapturedImage: true,
      );
    }
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
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }

      if (_cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _cameraError =
              'Kamera tidak ditemukan pada perangkat ini.';
        });

        return;
      }

      CameraDescription cameraToUse;

      // Kalau kamera tertentu diberikan,
      // gunakan kamera tersebut.
      if (preferredCamera != null) {
        cameraToUse = preferredCamera;

        final preferredIndex = _cameras.indexWhere(
          (camera) => camera.name == preferredCamera.name,
        );

        if (preferredIndex >= 0) {
          _selectedCameraIndex = preferredIndex;
        }
      } else {
        // Cari kamera depan secara otomatis.
        final frontCameraIndex = _cameras.indexWhere(
          (camera) =>
              camera.lensDirection == CameraLensDirection.front,
        );

        _selectedCameraIndex =
            frontCameraIndex >= 0 ? frontCameraIndex : 0;

        cameraToUse = _cameras[_selectedCameraIndex];
      }

      // Dispose controller lama.
      final oldController = _controller;

      _controller = null;

      await oldController?.dispose();

      // Buat controller baru.
      final newController = CameraController(
        cameraToUse,
        ResolutionPreset.high,
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
      if (!mounted) return;

      setState(() {
        _loading = false;
        _cameraError = _cameraErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _cameraError =
            'Gagal membuka kamera: $e';
      });
    }
  }

  // =========================================================
  // CAMERA ERROR MESSAGE
  // =========================================================

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
        return 'Izin kamera ditolak. '
            'Izinkan akses kamera lalu coba lagi.';

      case 'CameraAccessDeniedWithoutPrompt':
        return 'Akses kamera pernah ditolak. '
            'Aktifkan izin kamera dari pengaturan browser/perangkat.';

      case 'CameraAccessRestricted':
        return 'Akses kamera dibatasi pada perangkat ini.';

      default:
        return 'Kamera tidak dapat digunakan '
            '(${error.code}). '
            '${error.description ?? ''}';
    }
  }

  // =========================================================
  // CAPTURE PHOTO
  // =========================================================

  Future<void> _capturePhoto() async {
    final cameraController = _controller;

    if (cameraController == null ||
        !cameraController.value.isInitialized ||
        cameraController.value.isTakingPicture ||
        _capturing) {
      return;
    }

    setState(() {
      _capturing = true;
      _cameraError = null;
    });

    try {
      final image =
          await cameraController.takePicture();

      final bytes =
          await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _capturedImage = bytes;
        _imageApproved = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      setState(() {
        _cameraError =
            'Gagal mengambil foto: '
            '${e.description ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;

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
  // SWITCH FRONT / BACK CAMERA
  // =========================================================

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 ||
        _switchingCamera) {
      return;
    }

    setState(() {
      _switchingCamera = true;
      _cameraError = null;
    });

    try {
      final nextIndex =
          (_selectedCameraIndex + 1) %
              _cameras.length;

      _selectedCameraIndex = nextIndex;

      await _initializeCamera(
        preferredCamera:
            _cameras[nextIndex],
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
    final image = _capturedImage;

    if (image == null) return;

    widget.onImageCaptured?.call(image);

    setState(() {
      _imageApproved = true;
    });
  }

  // =========================================================
  // CALCULATE CAMERA RATIO
  // =========================================================

  double _cameraPreviewAspectRatio(
    CameraController controller,
  ) {
    final value = controller.value;

    final isLandscape =
        value.deviceOrientation ==
                DeviceOrientation.landscapeLeft ||
            value.deviceOrientation ==
                DeviceOrientation.landscapeRight;

    return isLandscape
        ? value.aspectRatio
        : 1 / value.aspectRatio;
  }

  // =========================================================
  // CAMERA PREVIEW
  //
  // BoxFit.cover dipakai agar kamera memenuhi frame
  // tanpa membuat gambar gepeng.
  // =========================================================

  Widget _buildCoverCameraPreview(
    CameraController controller,
  ) {
    final previewAspectRatio =
        _cameraPreviewAspectRatio(controller);

    const virtualHeight = 1000.0;

    final virtualWidth =
        virtualHeight *
            previewAspectRatio;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: virtualWidth,
          height: virtualHeight,
          child: CameraPreview(
            controller,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CAMERA FRAME
  // =========================================================

  Widget _buildCameraFrame({
    required CameraController controller,
    required double frameAspectRatio,
  }) {
    return AspectRatio(
      aspectRatio: frameAspectRatio,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: _capturedImage == null
                  ? _buildCoverCameraPreview(
                      controller,
                    )
                  : Image.memory(
                      _capturedImage!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
            ),

            // ===============================================
            // FACE GUIDE
            // ===============================================

            if (_capturedImage == null)
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: 180,
                    height: 230,
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        100,
                      ),
                      border:
                          Border.all(
                        color: Colors.white
                            .withValues(
                          alpha: 0.55,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

            // ===============================================
            // SWITCH CAMERA BUTTON
            // ===============================================

            if (_capturedImage == null)
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black54,
                  shape:
                      const CircleBorder(),
                  child: IconButton(
                    tooltip:
                        _cameras.length > 1
                            ? 'Ganti kamera'
                            : 'Hanya satu kamera tersedia',
                    onPressed:
                        _cameras.length > 1 &&
                                !_switchingCamera
                            ? _switchCamera
                            : null,
                    icon:
                        _switchingCamera
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
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

            // ===============================================
            // CAMERA INFO
            // ===============================================

            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(
                  color:
                      Colors.black54,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    _capturedImage ==
                            null
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
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final isMobile =
        screenWidth < 700;

    // Mobile portrait
    // width : height = 3 : 4
    final frameAspectRatio =
        isMobile ? 3 / 4 : 4 / 3;

    final maxPreviewWidth =
        isMobile ? 440.0 : 700.0;

    // =======================================================
    // LOADING
    // =======================================================

    if (_loading) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 48,
        ),
        child: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Menyiapkan kamera...',
              ),
            ],
          ),
        ),
      );
    }

    // =======================================================
    // ERROR
    // =======================================================

    if (_cameraError != null ||
        _controller == null ||
        !_controller!
            .value
            .isInitialized) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 480,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons
                      .no_photography_outlined,
                  size: 52,
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  _cameraError ??
                      'Kamera belum siap.',
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 16,
                ),
                FilledButton.icon(
                  onPressed:
                      _initializeCamera,
                  icon:
                      const Icon(
                    Icons
                        .refresh_rounded,
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

    final cameraController =
        _controller!;

    // =======================================================
    // CAMERA READY
    // =======================================================

    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(
          maxWidth:
              maxPreviewWidth,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            _buildCameraFrame(
              controller:
                  cameraController,
              frameAspectRatio:
                  frameAspectRatio,
            ),

            const SizedBox(
              height: 16,
            ),

            if (_cameraError !=
                null) ...[
              Text(
                _cameraError!,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Theme.of(
                    context,
                  )
                          .colorScheme
                          .error,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],

            // =================================================
            // TAKE PHOTO BUTTON
            // =================================================

            if (_capturedImage ==
                null)
              SizedBox(
                width:
                    double.infinity,
                height: 52,
                child:
                    FilledButton.icon(
                  onPressed:
                      _capturing
                          ? null
                          : _capturePhoto,
                  icon:
                      _capturing
                          ? const SizedBox(
                              width:
                                  20,
                              height:
                                  20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .camera_alt_rounded,
                            ),
                  label: Text(
                    _capturing
                        ? 'Mengambil Foto...'
                        : 'Ambil Foto',
                  ),
                ),
              )

            // =================================================
            // RETAKE / USE PHOTO
            // =================================================

            else
              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton
                            .icon(
                      onPressed:
                          _retakePhoto,
                      icon:
                          const Icon(
                        Icons
                            .refresh_rounded,
                      ),
                      label:
                          const Text(
                        'Ulangi',
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        FilledButton
                            .icon(
                      onPressed:
                          _approvePhoto,
                      icon:
                          const Icon(
                        Icons
                            .check_rounded,
                      ),
                      label:
                          const Text(
                        'Gunakan Foto',
                      ),
                    ),
                  ),
                ],
              ),

            // =================================================
            // APPROVED STATUS
            // =================================================

            if (_imageApproved) ...[
              const SizedBox(
                height: 12,
              ),
              const Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Icon(
                    Icons
                        .verified_rounded,
                    color:
                        Colors.green,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(
                      'Foto siap digunakan untuk absensi',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .w600,
                        color:
                            Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}