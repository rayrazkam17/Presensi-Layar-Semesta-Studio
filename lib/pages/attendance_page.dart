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
  final AttendanceService
      _attendanceService =
      AttendanceService();

  final StorageService
      _storageService =
      StorageService();

  Uint8List? _approvedImage;

  bool _submitting = false;

  int _cameraInstance = 0;

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(
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
  // SUBMIT
  // =========================================================

  Future<void> _submitAttendance({
    required bool checkIn,
  }) async {
    final image =
        _approvedImage;

    if (image == null) {
      _showMessage(
        'Ambil foto lalu tekan Gunakan Foto terlebih dahulu.',
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
      final user =
          Supabase.instance
              .client
              .auth
              .currentUser;

      if (user == null) {
        throw Exception(
          'Sesi login tidak ditemukan.',
        );
      }

      // =====================================================
      // CHECK-IN
      // =====================================================

      if (checkIn) {
        final checkedIn =
            await _attendanceService
                .hasCheckedInToday();

        if (checkedIn) {
          _showMessage(
            'Anda sudah absen masuk hari ini.',
            error: true,
          );

          return;
        }
      }

      // =====================================================
      // CHECK-OUT
      // =====================================================

      else {
        final checkedIn =
            await _attendanceService
                .hasCheckedInToday();

        if (!checkedIn) {
          _showMessage(
            'Anda belum melakukan absen masuk.',
            error: true,
          );

          return;
        }

        final checkedOut =
            await _attendanceService
                .hasCheckedOutToday();

        if (checkedOut) {
          _showMessage(
            'Anda sudah absen keluar hari ini.',
            error: true,
          );

          return;
        }
      }

      final path =
          _buildPhotoPath(
        userId:
            user.id,

        checkIn:
            checkIn,
      );

      final uploadedPath =
          await _storageService
              .uploadAttendancePhoto(
        bytes:
            image,

        fileName:
            path,
      );

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

      setState(() {
        _approvedImage =
            null;

        _cameraInstance++;
      });

      _showMessage(
        checkIn
            ? 'Absen masuk berhasil.'
            : 'Absen keluar berhasil.',
      );
    } catch (e) {
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
  // BUTTONS
  // =========================================================

  Widget _buildAttendanceButtons() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .stretch,

      children: [
        SizedBox(
          height:
              54,

          child:
              FilledButton.icon(
            onPressed:
                _submitting
                    ? null
                    : () {
                        _submitAttendance(
                          checkIn: true,
                        );
                      },

            icon:
                const Icon(
              Icons.login_rounded,
            ),

            label:
                const Text(
              'ABSEN MASUK',
            ),
          ),
        ),

        const SizedBox(
          height:
              12,
        ),

        SizedBox(
          height:
              54,

          child:
              OutlinedButton.icon(
            onPressed:
                _submitting
                    ? null
                    : () {
                        _submitAttendance(
                          checkIn: false,
                        );
                      },

            icon:
                const Icon(
              Icons.logout_rounded,
            ),

            label:
                const Text(
              'ABSEN KELUAR',
            ),
          ),
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
    final width =
        MediaQuery.sizeOf(
      context,
    ).width;

    final isMobile =
        width < 700;

    final bottomInset =
        MediaQuery.viewPaddingOf(
      context,
    ).bottom;

    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'Absensi',
        ),
      ),

      body:
          SafeArea(
        bottom:
            false,

        child:
            ListView(
          // =================================================
          // PENTING UNTUK IOS
          // =================================================

          physics:
              const AlwaysScrollableScrollPhysics(
            parent:
                BouncingScrollPhysics(),
          ),

          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,

          padding:
              EdgeInsets.fromLTRB(
            isMobile
                ? 16
                : 24,

            20,

            isMobile
                ? 16
                : 24,

            // Toolbar Safari + Home indicator.
            130 +
                bottomInset,
          ),

          children: [
            Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth:
                      760,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,

                  children: [
                    // =========================================
                    // TITLE
                    // =========================================

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
                      height:
                          8,
                    ),

                    Text(
                      'Pastikan wajah terlihat jelas dan '
                      'berada di tengah kamera.',

                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height:
                          24,
                    ),

                    // =========================================
                    // CAMERA
                    // =========================================

                    CameraCaptureWidget(
                      key:
                          ValueKey(
                        _cameraInstance,
                      ),

                      onImageCaptured:
                          (
                        bytes,
                      ) {
                        setState(() {
                          _approvedImage =
                              bytes;
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

                    // =========================================
                    // PHOTO READY
                    // =========================================

                    if (_approvedImage !=
                        null) ...[
                      const SizedBox(
                        height:
                            10,
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
                            alpha:
                                0.08,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),

                        child:
                            const Row(
                          children: [
                            Icon(
                              Icons
                                  .check_circle_rounded,

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
                                'Foto telah siap. '
                                'Silakan pilih jenis absensi.',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),

                      _buildAttendanceButtons(),

                      if (_submitting) ...[
                        const SizedBox(
                          height:
                              16,
                        ),

                        const LinearProgressIndicator(),

                        const SizedBox(
                          height:
                              8,
                        ),

                        const Text(
                          'Mengirim data absensi...',

                          textAlign:
                              TextAlign.center,
                        ),
                      ],
                    ],

                    const SizedBox(
                      height:
                          40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}