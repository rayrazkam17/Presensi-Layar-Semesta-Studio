import 'package:flutter/material.dart';

import '../services/admin_control_service.dart';
import '../services/admin_manual_attendance_service.dart';

class AdminManualAttendancePage
    extends StatefulWidget {
  const AdminManualAttendancePage({
    super.key,
  });

  @override
  State<AdminManualAttendancePage>
      createState() =>
          _AdminManualAttendancePageState();
}

class _AdminManualAttendancePageState
    extends State<AdminManualAttendancePage> {
  final AdminControlService
      _adminControlService =
      AdminControlService();

  final AdminManualAttendanceService
      _manualAttendanceService =
      AdminManualAttendanceService();

  final TextEditingController
      _noteController =
      TextEditingController();

  // =========================================================
  // EMPLOYEES
  // =========================================================

  List<Map<String, dynamic>>
      _employees = [];

  bool _loadingEmployees = true;

  String? _selectedEmployeeId;

  // =========================================================
  // DATE / TIME
  // =========================================================

  DateTime _selectedDate =
      DateTime.now();

  TimeOfDay _checkIn =
      const TimeOfDay(
    hour: 8,
    minute: 0,
  );

  TimeOfDay _checkOut =
      const TimeOfDay(
    hour: 17,
    minute: 0,
  );

  // =========================================================
  // REASON
  // =========================================================

  static const List<String>
      _reasons = [
    'Lupa melakukan absensi',
    'Kendala / error sistem',
    'Kamera / perangkat bermasalah',
    'Presensi dibantu admin',
    'Kendala jaringan / internet',
    'Lainnya',
  ];

  String _selectedReason =
      _reasons.first;

  // =========================================================
  // STATE
  // =========================================================

  bool _saving = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadEmployees();
  }

  // =========================================================
  // LOAD EMPLOYEES
  // =========================================================

  Future<void> _loadEmployees() async {
    setState(() {
      _loadingEmployees = true;
    });

    try {
      final employees =
          await _adminControlService
              .getEmployees();

      if (!mounted) {
        return;
      }

      employees.sort(
        (
          a,
          b,
        ) {
          final nameA =
              a['nama']
                  ?.toString()
                  .toLowerCase() ??
              '';

          final nameB =
              b['nama']
                  ?.toString()
                  .toLowerCase() ??
              '';

          return nameA.compareTo(
            nameB,
          );
        },
      );

      setState(() {
        _employees = employees;

        _loadingEmployees = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingEmployees = false;
      });

      _showMessage(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    }
  }

  // =========================================================
  // SELECT DATE
  // =========================================================

  Future<void> _selectDate() async {
    final selected =
        await showDatePicker(
      context: context,

      initialDate:
          _selectedDate,

      firstDate:
          DateTime(
        2024,
        1,
        1,
      ),

      lastDate:
          DateTime.now(),

      helpText:
          'PILIH TANGGAL PRESENSI',

      cancelText:
          'BATAL',

      confirmText:
          'PILIH',
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  // =========================================================
  // SELECT CHECK IN
  // =========================================================

  Future<void> _selectCheckIn() async {
    final selected =
        await showTimePicker(
      context: context,

      initialTime:
          _checkIn,

      helpText:
          'PILIH JAM MASUK',
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _checkIn = selected;
    });
  }

  // =========================================================
  // SELECT CHECK OUT
  // =========================================================

  Future<void> _selectCheckOut() async {
    final selected =
        await showTimePicker(
      context: context,

      initialTime:
          _checkOut,

      helpText:
          'PILIH JAM KELUAR',
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _checkOut = selected;
    });
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _save({
    bool replaceExisting = false,
  }) async {
    final userId =
        _selectedEmployeeId;

    if (userId == null) {
      _showMessage(
        'Pilih pegawai terlebih dahulu.',
        error: true,
      );

      return;
    }

    final checkInMinutes =
        (_checkIn.hour * 60) +
            _checkIn.minute;

    final checkOutMinutes =
        (_checkOut.hour * 60) +
            _checkOut.minute;

    if (checkOutMinutes <=
        checkInMinutes) {
      _showMessage(
        'Jam keluar harus setelah jam masuk.',
        error: true,
      );

      return;
    }

    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result =
          await _manualAttendanceService
              .saveManualAttendance(
        userId:
            userId,

        date:
            _selectedDate,

        checkIn:
            TimeOfDayData(
          hour:
              _checkIn.hour,

          minute:
              _checkIn.minute,
        ),

        checkOut:
            TimeOfDayData(
          hour:
              _checkOut.hour,

          minute:
              _checkOut.minute,
        ),

        reason:
            _selectedReason,

        note:
            _noteController.text,

        replaceExisting:
            replaceExisting,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        result['message']
                ?.toString() ??
            'Presensi manual berhasil disimpan.',
      );

      _resetForm();
    } on AttendanceAlreadyExistsException catch (e) {
      if (!mounted) {
        return;
      }

      final shouldReplace =
          await _showReplaceConfirmation(
        e.message,
      );

      if (shouldReplace == true &&
          mounted) {
        setState(() {
          _saving = false;
        });

        await _save(
          replaceExisting: true,
        );

        return;
      }
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
          _saving = false;
        });
      }
    }
  }

  // =========================================================
  // REPLACE CONFIRMATION
  // =========================================================

  Future<bool?>
      _showReplaceConfirmation(
    String message,
  ) {
    return showDialog<bool>(
      context: context,

      builder:
          (dialogContext) {
        return AlertDialog(
          icon:
              const Icon(
            Icons.warning_amber_rounded,

            size: 42,

            color: Colors.orange,
          ),

          title:
              const Text(
            'Presensi Sudah Ada',
          ),

          content:
              Text(
            '$message\n\n'
            'Apakah Anda yakin ingin memperbarui jam masuk, '
            'jam keluar, dan keterangan pada data tersebut?\n\n'
            'Foto presensi lama, apabila ada, tidak akan dihapus.',
          ),

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child:
                  const Text(
                'BATAL',
              ),
            ),

            FilledButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
                  const Text(
                'PERBARUI',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // RESET
  // =========================================================

  void _resetForm() {
    setState(() {
      _selectedEmployeeId =
          null;

      _selectedDate =
          DateTime.now();

      _checkIn =
          const TimeOfDay(
        hour: 8,
        minute: 0,
      );

      _checkOut =
          const TimeOfDay(
        hour: 17,
        minute: 0,
      );

      _selectedReason =
          _reasons.first;

      _noteController.clear();
    });
  }

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
  // DATE FORMAT
  // =========================================================

  String _dateText(
    DateTime date,
  ) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // =========================================================
  // TIME FIELD
  // =========================================================

  Widget _timeField({
    required String title,
    required TimeOfDay value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        14,
      ),

      onTap:
          _saving
              ? null
              : onTap,

      child:
          InputDecorator(
        decoration:
            InputDecoration(
          labelText:
              title,

          prefixIcon:
              Icon(
            icon,
          ),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),

        child:
            Text(
          value.format(context),

          style:
              const TextStyle(
            fontSize: 16,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
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

    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'Presensi Manual',
        ),
      ),

      body:
          SafeArea(
        child:
            ListView(
          padding:
              EdgeInsets.fromLTRB(
            isMobile
                ? 16
                : 24,

            20,

            isMobile
                ? 16
                : 24,

            60,
          ),

          children: [
            Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth:
                      720,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    // =========================================
                    // INFORMATION
                    // =========================================

                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(
                                  alpha: 0.45,
                                ),

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),

                      child:
                          const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Icon(
                            Icons
                                .admin_panel_settings_rounded,
                          ),

                          SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                                Text(
                              'Gunakan fitur ini hanya jika pegawai '
                              'tidak dapat melakukan presensi sendiri, '
                              'misalnya lupa absen atau terjadi kendala sistem. '
                              'Presensi akan ditandai sebagai input manual admin.',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(
                      'Data Pegawai',

                      style:
                          Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // =========================================
                    // EMPLOYEE
                    // =========================================

                    if (_loadingEmployees)
                      const Center(
                        child:
                            Padding(
                          padding:
                              EdgeInsets.all(
                            24,
                          ),

                          child:
                              CircularProgressIndicator(),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value:
                            _selectedEmployeeId,

                        isExpanded:
                            true,

                        decoration:
                            InputDecoration(
                          labelText:
                              'Pilih Pegawai',

                          prefixIcon:
                              const Icon(
                            Icons
                                .person_rounded,
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),

                        items:
                            _employees
                                .map(
                          (
                            employee,
                          ) {
                            final id =
                                employee['id']
                                    .toString();

                            final nama =
                                employee['nama']
                                        ?.toString() ??
                                    '-';

                            final email =
                                employee['email']
                                        ?.toString() ??
                                    '';

                            return DropdownMenuItem<
                                String>(
                              value:
                                  id,

                              child:
                                  Text(
                                email.isEmpty
                                    ? nama
                                    : '$nama — $email',

                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ).toList(),

                        onChanged:
                            _saving
                                ? null
                                : (
                                    value,
                                  ) {
                                    setState(() {
                                      _selectedEmployeeId =
                                          value;
                                    });
                                  },
                      ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =========================================
                    // DATE
                    // =========================================

                    InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),

                      onTap:
                          _saving
                              ? null
                              : _selectDate,

                      child:
                          InputDecorator(
                        decoration:
                            InputDecoration(
                          labelText:
                              'Tanggal Presensi',

                          prefixIcon:
                              const Icon(
                            Icons
                                .calendar_month_rounded,
                          ),

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),

                        child:
                            Text(
                          _dateText(
                            _selectedDate,
                          ),

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =========================================
                    // TIME
                    // =========================================

                    if (isMobile) ...[
                      _timeField(
                        title:
                            'Jam Masuk',

                        value:
                            _checkIn,

                        icon:
                            Icons
                                .login_rounded,

                        onTap:
                            _selectCheckIn,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      _timeField(
                        title:
                            'Jam Keluar',

                        value:
                            _checkOut,

                        icon:
                            Icons
                                .logout_rounded,

                        onTap:
                            _selectCheckOut,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child:
                                _timeField(
                              title:
                                  'Jam Masuk',

                              value:
                                  _checkIn,

                              icon:
                                  Icons
                                      .login_rounded,

                              onTap:
                                  _selectCheckIn,
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          Expanded(
                            child:
                                _timeField(
                              title:
                                  'Jam Keluar',

                              value:
                                  _checkOut,

                              icon:
                                  Icons
                                      .logout_rounded,

                              onTap:
                                  _selectCheckOut,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(
                      height: 28,
                    ),

                    Text(
                      'Keterangan',

                      style:
                          Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // =========================================
                    // REASON
                    // =========================================

                    DropdownButtonFormField<String>(
                      value:
                          _selectedReason,

                      decoration:
                          InputDecoration(
                        labelText:
                            'Alasan Presensi Manual',

                        prefixIcon:
                            const Icon(
                          Icons
                              .description_outlined,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),

                      items:
                          _reasons.map(
                        (
                          reason,
                        ) {
                          return DropdownMenuItem<
                              String>(
                            value:
                                reason,

                            child:
                                Text(
                              reason,
                            ),
                          );
                        },
                      ).toList(),

                      onChanged:
                          _saving
                              ? null
                              : (
                                  value,
                                ) {
                                  if (value ==
                                      null) {
                                    return;
                                  }

                                  setState(() {
                                    _selectedReason =
                                        value;
                                  });
                                },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // =========================================
                    // NOTES
                    // =========================================

                    TextField(
                      controller:
                          _noteController,

                      enabled:
                          !_saving,

                      maxLines:
                          4,

                      minLines:
                          3,

                      decoration:
                          InputDecoration(
                        labelText:
                            'Catatan Tambahan',

                        hintText:
                            'Opsional. Contoh: pegawai melapor '
                            'bahwa sistem tidak dapat membuka kamera.',

                        alignLabelWithHint:
                            true,

                        prefixIcon:
                            const Padding(
                          padding:
                              EdgeInsets.only(
                            bottom: 60,
                          ),

                          child:
                              Icon(
                            Icons
                                .notes_rounded,
                          ),
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // =========================================
                    // NO PHOTO INFO
                    // =========================================

                    Container(
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.orange
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
                              Colors.orange
                                  .withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),

                      child:
                          const Row(
                        children: [
                          Icon(
                            Icons
                                .no_photography_rounded,

                            color:
                                Colors.orange,
                          ),

                          SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child:
                                Text(
                              'Presensi manual tidak memerlukan foto. '
                              'Data akan ditandai sebagai presensi yang '
                              'dimasukkan oleh admin.',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // =========================================
                    // SAVE
                    // =========================================

                    SizedBox(
                      height:
                          55,

                      child:
                          FilledButton.icon(
                        onPressed:
                            _saving
                                ? null
                                : () {
                                    _save();
                                  },

                        icon:
                            _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .save_rounded,
                                  ),

                        label:
                            Text(
                          _saving
                              ? 'MENYIMPAN...'
                              : 'SIMPAN PRESENSI MANUAL',
                        ),
                      ),
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

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _noteController.dispose();

    super.dispose();
  }
}