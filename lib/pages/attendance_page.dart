import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/attendance_service.dart';
import '../services/storage_service.dart';
import '../widgets/camera_capture_widget.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({
    super.key,
  });

  @override
  State<AttendancePage> createState() =>
      _AttendancePageState();
}

class _AttendancePageState
    extends State<AttendancePage> {
  // =========================================================
  // SERVICES
  // =========================================================

  final AttendanceService
      _attendanceService =
      AttendanceService();

  final StorageService
      _storageService =
      StorageService();

  // =========================================================
  // IMAGE
  // =========================================================

  Uint8List? _approvedImage;

  // Membuat ulang kamera setelah absensi berhasil.
  int _cameraInstance = 0;

  // =========================================================
  // SUBMIT
  // =========================================================

  bool _submitting = false;

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),

          backgroundColor:
              error
                  ? Theme.of(context)
                      .colorScheme
                      .error
                  : Colors
                      .green
                      .shade700,
        ),
      );
  }

  // =========================================================
  // PHOTO PATH
  // =========================================================

  String _buildPhotoPath({
    required String userId,
    required bool checkIn,
  }) {
    final nowUtc =
        DateTime.now().toUtc();

    final nowWib =
        nowUtc.add(
      const Duration(
        hours: 7,
      ),
    );

    final month =
        nowWib.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final day =
        nowWib.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final type =
        checkIn
            ? 'checkin'
            : 'checkout';

    return '${nowWib.year}/'
        '$month/'
        '$day/'
        '$userId/'
        '${type}_${nowUtc.millisecondsSinceEpoch}.jpg';
  }

  // =========================================================
  // SUBMIT ATTENDANCE
  // =========================================================

  Future<void> _submitAttendance({
    required bool checkIn,
  }) async {
    final image =
        _approvedImage;

    if (image == null) {
      _showMessage(
        'Ambil foto lalu tekan '
        '"Gunakan Foto" terlebih dahulu.',
        error: true,
      );

      return;
    }

    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      // =====================================================
      // USER
      // =====================================================

      final user =
          Supabase.instance
              .client
              .auth
              .currentUser;

      if (user == null) {
        throw Exception(
          'Sesi login tidak ditemukan. '
          'Silakan login kembali.',
        );
      }

      // =====================================================
      // CHECK IN VALIDATION
      // =====================================================

      if (checkIn) {
        final alreadyCheckedIn =
            await _attendanceService
                .hasCheckedInToday();

        if (alreadyCheckedIn) {
          _showMessage(
            'Anda sudah melakukan absen masuk hari ini.',
            error: true,
          );

          return;
        }
      }

      // =====================================================
      // CHECK OUT VALIDATION
      // =====================================================

      else {
        final alreadyCheckedIn =
            await _attendanceService
                .hasCheckedInToday();

        if (!alreadyCheckedIn) {
          _showMessage(
            'Anda belum melakukan absen masuk hari ini.',
            error: true,
          );

          return;
        }

        final alreadyCheckedOut =
            await _attendanceService
                .hasCheckedOutToday();

        if (alreadyCheckedOut) {
          _showMessage(
            'Anda sudah melakukan absen keluar hari ini.',
            error: true,
          );

          return;
        }
      }

      // =====================================================
      // PHOTO PATH
      // =====================================================

      final filePath =
          _buildPhotoPath(
        userId:
            user.id,

        checkIn:
            checkIn,
      );

      // =====================================================
      // UPLOAD PHOTO
      // =====================================================

      final uploadedPath =
          await _storageService
              .uploadAttendancePhoto(
        bytes:
            image,

        fileName:
            filePath,
      );

      // =====================================================
      // SAVE DATABASE
      // =====================================================

      if (checkIn) {
        await _attendanceService
            .checkIn(
          photoPath:
              uploadedPath,
        );
      } else {
        await _attendanceService
            .checkOut(
          photoPath:
              uploadedPath,
        );
      }

      if (!mounted) {
        return;
      }

      // =====================================================
      // RESET
      // =====================================================

      setState(() {
        _approvedImage = null;

        _cameraInstance++;
      });

      // =====================================================
      // SUCCESS
      // =====================================================

      _showMessage(
        checkIn
            ? 'Absen masuk berhasil disimpan.'
            : 'Absen keluar berhasil disimpan.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // =========================================================
  // ATTENDANCE BUTTONS
  // =========================================================

  Widget _buildAttendanceButtons(
    bool isMobile,
  ) {
    final checkInButton =
        SizedBox(
      height: 54,

      child: FilledButton.icon(
        onPressed:
            _submitting
                ? null
                : () {
                    _submitAttendance(
                      checkIn: true,
                    );
                  },

        icon: const Icon(
          Icons.login_rounded,
        ),

        label: const Text(
          'ABSEN MASUK',
        ),
      ),
    );

    final checkOutButton =
        SizedBox(
      height: 54,

      child: OutlinedButton.icon(
        onPressed:
            _submitting
                ? null
                : () {
                    _submitAttendance(
                      checkIn: false,
                    );
                  },

        icon: const Icon(
          Icons.logout_rounded,
        ),

        label: const Text(
          'ABSEN KELUAR',
        ),
      ),
    );

    // =======================================================
    // MOBILE
    // =======================================================

    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: [
          checkInButton,

          const SizedBox(
            height: 12,
          ),

          checkOutButton,
        ],
      );
    }

    // =======================================================
    // DESKTOP
    // =======================================================

    return Row(
      children: [
        Expanded(
          child:
              checkInButton,
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child:
              checkOutButton,
        ),
      ],
    );
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

    final safeBottom =
        MediaQuery.paddingOf(
      context,
    ).bottom;

    return Scaffold(
      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title:
            const Text(
          'Absensi',
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,

              // Padding bawah dibuat besar supaya
              // tombol tidak dimakan navigation bar HP.
              padding:
                  EdgeInsets.fromLTRB(
                isMobile
                    ? 14
                    : 24,

                18,

                isMobile
                    ? 14
                    : 24,

                40 +
                    safeBottom,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 760,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [
                      // =====================================
                      // TITLE
                      // =====================================

                      Text(
                        'Ambil Foto Kehadiran',

                        textAlign:
                            TextAlign.center,

                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Pastikan wajah terlihat jelas '
                        'dan berada di tengah kamera.',

                        textAlign:
                            TextAlign.center,

                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .bodyMedium,
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // =====================================
                      // CAMERA
                      // =====================================

                      CameraCaptureWidget(
                        key:
                            ValueKey(
                          _cameraInstance,
                        ),

                        onImageCaptured:
                            (
                          imageBytes,
                        ) {
                          setState(() {
                            _approvedImage =
                                imageBytes;
                          });
                        },

                        onImageReset:
                            () {
                          setState(() {
                            _approvedImage =
                                null;
                          });
                        },
                      ),

                      // =====================================
                      // IMAGE READY
                      // =====================================

                      if (_approvedImage !=
                          null) ...[
                        const SizedBox(
                          height: 12,
                        ),

                        Container(
                          padding:
                              const EdgeInsets.all(
                            14,
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
                              14,
                            ),

                            border:
                                Border.all(
                              color:
                                  Colors.green
                                      .withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),

                          child:
                              const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Icon(
                                Icons
                                    .check_circle_rounded,

                                color:
                                    Colors.green,
                              ),

                              SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child:
                                    Text(
                                  'Foto telah dipilih. '
                                  'Silakan pilih Absen Masuk '
                                  'atau Absen Keluar.',

                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // ===================================
                        // ATTENDANCE BUTTONS
                        // ===================================

                        _buildAttendanceButtons(
                          isMobile,
                        ),

                        // ===================================
                        // LOADING
                        // ===================================

                        if (_submitting) ...[
                          const SizedBox(
                            height: 18,
                          ),

                          const LinearProgressIndicator(),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            'Mengirim data absensi...',

                            textAlign:
                                TextAlign.center,
                          ),
                        ],
                      ],

                      // =====================================
                      // BOTTOM SPACE
                      // =====================================

                      const SizedBox(
                        height: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}