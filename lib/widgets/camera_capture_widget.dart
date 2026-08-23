import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
    } else if (state == AppLifecycleState.resumed &&
        _cameras.isNotEmpty) {
      _initializeCamera(
        preferredCamera:
            _cameras[_selectedCameraIndex],
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
      // =====================================================
      // GET CAMERA LIST
      // =====================================================

      if (_cameras.isEmpty) {
        _cameras =
            await availableCameras();
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
      // USE REQUESTED CAMERA
      // =====================================================

      if (preferredCamera != null) {
        cameraToUse =
            preferredCamera;

        final index =
            _cameras.indexWhere(
          (camera) =>
              camera.name ==
              preferredCamera.name,
        );

        if (index >= 0) {
          _selectedCameraIndex =
              index;
        }
      }

      // =====================================================
      // DEFAULT FRONT CAMERA
      // =====================================================

      else {
        final frontIndex =
            _cameras.indexWhere(
          (camera) =>
              camera.lensDirection ==
              CameraLensDirection.front,
        );

        _selectedCameraIndex =
            frontIndex >= 0
                ? frontIndex
                : 0;

        cameraToUse =
            _cameras[_selectedCameraIndex];
      }

      // =====================================================
      // DISPOSE OLD CONTROLLER
      // =====================================================

      final oldController =
          _controller;

      _controller = null;

      await oldController?.dispose();

      // =====================================================
      // CREATE NEW CONTROLLER
      // =====================================================

      final newController =
          CameraController(
        cameraToUse,

        // High sudah cukup jelas untuk bukti presensi.
        ResolutionPreset.high,

        enableAudio: false,
      );

      _controller =
          newController;

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
  // CAPTURE PHOTO
  // =========================================================

  Future<void> _capturePhoto() async {
    final controller =
        _controller;

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

      final bytes =
          await picture.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _capturedImage =
            bytes;

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
    if (_cameras.length < 2 ||
        _switchingCamera) {
      return;
    }

    setState(() {
      _switchingCamera =
          true;

      _cameraError =
          null;
    });

    try {
      // =====================================================
      // Cari kamera dengan arah berbeda.
      //
      // Jadi tidak hanya pindah index sembarangan jika
      // device punya banyak kamera belakang.
      // =====================================================

      final currentCamera =
          _cameras[_selectedCameraIndex];

      final targetDirection =
          currentCamera.lensDirection ==
                  CameraLensDirection.front
              ? CameraLensDirection.back
              : CameraLensDirection.front;

      final targetIndex =
          _cameras.indexWhere(
        (camera) =>
            camera.lensDirection ==
            targetDirection,
      );

      if (targetIndex < 0) {
        _showMessage(
          'Kamera lain tidak tersedia.',
        );

        return;
      }

      _selectedCameraIndex =
          targetIndex;

      await _initializeCamera(
        preferredCamera:
            _cameras[targetIndex],
      );
    } finally {
      if (mounted) {
        setState(() {
          _switchingCamera =
              false;
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
      _capturedImage =
          null;

      _imageApproved =
          false;

      _cameraError =
          null;
    });
  }

  // =========================================================
  // APPROVE
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
      _imageApproved =
          true;
    });
  }

  // =========================================================
  // ERROR MESSAGE
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
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
  }

  // =========================================================
  // LIVE CAMERA PREVIEW
  //
  // INI BAGIAN PENTING.
  //
  // Jangan gunakan BoxFit.cover karena cover akan
  // memotong sisi video sehingga terlihat seperti zoom.
  //
  // Kita menggunakan BoxFit.contain agar SELURUH VIEW
  // kamera terlihat.
  // =========================================================

  Widget _buildCameraPreview(
    CameraController controller,
  ) {
    final previewSize =
        controller.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(
        controller,
      );
    }

    // Camera preview biasanya diberikan dalam orientation
    // sensor landscape.
    //
    // Untuk tampilan portrait kita balik width & height.
    final previewWidth =
        previewSize.height;

    final previewHeight =
        previewSize.width;

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        return ColoredBox(
          color: Colors.black,

          child: Center(
            child: FittedBox(
              // =============================================
              // PENTING
              //
              // contain = TIDAK CROP / TIDAK ZOOM
              // =============================================

              fit: BoxFit.contain,

              child: SizedBox(
                width:
                    previewWidth,

                height:
                    previewHeight,

                child:
                    CameraPreview(
                  controller,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // CAMERA FRAME
  //
  // FIXED 3:4 PORTRAIT
  // =========================================================

  Widget _buildCameraFrame(
    CameraController controller,
  ) {
    return AspectRatio(
      // =====================================================
      // WIDTH : HEIGHT
      //
      // 3 : 4
      // =====================================================

      aspectRatio: 3 / 4,

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          20,
        ),

        child: Stack(
          fit: StackFit.expand,

          children: [
            // =================================================
            // LIVE CAMERA / RESULT
            // =================================================

            ColoredBox(
              color:
                  Colors.black,

              child:
                  _capturedImage ==
                          null
                      ? _buildCameraPreview(
                          controller,
                        )
                      : Image.memory(
                          _capturedImage!,

                          // Untuk hasil foto juga jangan crop.
                          fit:
                              BoxFit.contain,

                          gaplessPlayback:
                              true,
                        ),
            ),

            // =================================================
            // FACE GUIDE
            // =================================================

            if (_capturedImage ==
                null)
              IgnorePointer(
                child: Center(
                  child:
                      FractionallySizedBox(
                    widthFactor:
                        0.52,

                    heightFactor:
                        0.58,

                    child:
                        Container(
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          100,
                        ),

                        border:
                            Border.all(
                          color:
                              Colors.white
                                  .withValues(
                            alpha:
                                0.65,
                          ),

                          width:
                              2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // =================================================
            // SWITCH CAMERA
            // =================================================

            if (_capturedImage ==
                null)
              Positioned(
                top:
                    12,

                right:
                    12,

                child:
                    Material(
                  color:
                      Colors.black54,

                  shape:
                      const CircleBorder(),

                  child:
                      IconButton(
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
                                width:
                                    20,

                                height:
                                    20,

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

            // =================================================
            // INFO
            // =================================================

            Positioned(
              left:
                  12,

              right:
                  12,

              bottom:
                  12,

              child:
                  Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      12,

                  vertical:
                      8,
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

                child:
                    Text(
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

                    fontSize:
                        13,
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
      width:
          double.infinity,

      height:
          54,

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

        label:
            Text(
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
        final isNarrow =
            constraints.maxWidth <
                430;

        // ===================================================
        // MOBILE
        // ===================================================

        if (isNarrow) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,

            children: [
              SizedBox(
                height:
                    52,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      _retakePhoto,

                  icon:
                      const Icon(
                    Icons
                        .refresh_rounded,
                  ),

                  label:
                      const Text(
                    'ULANGI FOTO',
                  ),
                ),
              ),

              const SizedBox(
                height:
                    10,
              ),

              SizedBox(
                height:
                    52,

                child:
                    FilledButton.icon(
                  onPressed:
                      _approvePhoto,

                  icon:
                      const Icon(
                    Icons
                        .check_rounded,
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
              child:
                  SizedBox(
                height:
                    52,

                child:
                    OutlinedButton.icon(
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
            ),

            const SizedBox(
              width:
                  12,
            ),

            Expanded(
              child:
                  SizedBox(
                height:
                    52,

                child:
                    FilledButton.icon(
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
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(
      this,
    );

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
    final screenWidth =
        MediaQuery.sizeOf(
      context,
    ).width;

    final isMobile =
        screenWidth < 700;

    // Supaya kamera tidak terlalu besar memenuhi layar HP.
    final maxWidth =
        isMobile
            ? 420.0
            : 620.0;

    // =======================================================
    // LOADING
    // =======================================================

    if (_loading) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical:
              48,
        ),

        child:
            Center(
          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              CircularProgressIndicator(),

              SizedBox(
                height:
                    16,
              ),

              Text(
                'Menyiapkan kamera...',
              ),
            ],
          ),
        ),
      );
    }

    // =======================================================
    // CAMERA ERROR
    // =======================================================

    if (_cameraError != null ||
        _controller == null ||
        !_controller!
            .value
            .isInitialized) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical:
              32,
        ),

        child:
            Center(
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  450,
            ),

            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                const Icon(
                  Icons
                      .no_photography_outlined,

                  size:
                      55,
                ),

                const SizedBox(
                  height:
                      16,
                ),

                Text(
                  _cameraError ??
                      'Kamera belum siap.',

                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(
                  height:
                      16,
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

    final controller =
        _controller!;

    // =======================================================
    // CAMERA READY
    // =======================================================

    return Center(
      child:
          ConstrainedBox(
        constraints:
            BoxConstraints(
          maxWidth:
              maxWidth,
        ),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            // =================================================
            // CAMERA 3:4
            // =================================================

            _buildCameraFrame(
              controller,
            ),

            const SizedBox(
              height:
                  16,
            ),

            // =================================================
            // CAPTURE / RESULT BUTTONS
            // =================================================

            if (_capturedImage ==
                null)
              _buildCaptureButton()
            else
              _buildResultButtons(),

            // =================================================
            // APPROVED
            // =================================================

            if (_imageApproved) ...[
              const SizedBox(
                height:
                    14,
              ),

              Container(
                padding:
                    const EdgeInsets.all(
                  12,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.green
                          .withValues(
                    alpha:
                        0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),

                  border:
                      Border.all(
                    color:
                        Colors.green
                            .withValues(
                      alpha:
                          0.25,
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
                    ),

                    SizedBox(
                      width:
                          10,
                    ),

                    Expanded(
                      child:
                          Text(
                        'Foto siap digunakan untuk absensi',

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
              height:
                  24,
            ),
          ],
        ),
      ),
    );
  }
}