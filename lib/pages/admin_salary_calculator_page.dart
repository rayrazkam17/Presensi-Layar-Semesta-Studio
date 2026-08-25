import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/attendance_service.dart';

class AdminSalaryCalculatorPage
    extends StatefulWidget {
  final String userId;
  final String employeeName;

  const AdminSalaryCalculatorPage({
    super.key,
    required this.userId,
    required this.employeeName,
  });

  @override
  State<AdminSalaryCalculatorPage>
      createState() =>
          _AdminSalaryCalculatorPageState();
}

class _AdminSalaryCalculatorPageState
    extends State<AdminSalaryCalculatorPage> {
  // =========================================================
  // SERVICE
  // =========================================================

  final AttendanceService _attendanceService =
      AttendanceService();

  // =========================================================
  // CONTROLLER
  // =========================================================

  final TextEditingController
      _dailySalaryController =
      TextEditingController();

  // =========================================================
  // DATE
  // =========================================================

  late DateTime _startDate;
  late DateTime _endDate;

  // =========================================================
  // STATE
  // =========================================================

  bool _loading = false;
  bool _hasResult = false;

  // =========================================================
  // RESULT
  // =========================================================

  int _attendanceDays = 0;

  // Lembur dihitung KALI.
  int _overtimeCount = 0;

  double _dailySalary = 0;

  double _attendanceSalary = 0;

  // Tambahan shift kedua.
  double _overtimeSalary = 0;

  double _grandTotal = 0;

  List<Map<String, dynamic>> _attendanceData = [];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _endDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Default periode 1 bulan terakhir.
    _startDate = _endDate.subtract(
      const Duration(
        days: 30,
      ),
    );
  }

  // =========================================================
  // SELECT START DATE
  // =========================================================

  Future<void> _selectStartDate() async {
    final selected =
        await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(
        2024,
        1,
        1,
      ),
      lastDate: DateTime.now(),
      helpText: 'PILIH TANGGAL AWAL',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;

      if (_endDate.isBefore(
        _startDate,
      )) {
        _endDate = selected;
      }

      _hasResult = false;
    });
  }

  // =========================================================
  // SELECT END DATE
  // =========================================================

  Future<void> _selectEndDate() async {
    final selected =
        await showDatePicker(
      context: context,
      initialDate:
          _endDate.isBefore(_startDate)
              ? _startDate
              : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      helpText: 'PILIH TANGGAL AKHIR',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
      _hasResult = false;
    });
  }

  // =========================================================
  // CALCULATE
  // =========================================================

  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();

    if (_endDate.isBefore(
      _startDate,
    )) {
      _showMessage(
        'Tanggal akhir tidak boleh sebelum tanggal awal.',
        error: true,
      );

      return;
    }

    final dailySalary =
        _parseMoney(
      _dailySalaryController.text,
    );

    if (dailySalary <= 0) {
      _showMessage(
        'Masukkan gaji per hari terlebih dahulu.',
        error: true,
      );

      return;
    }

    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
      _hasResult = false;
    });

    try {
      final attendance =
          await _attendanceService
              .getEmployeeAttendanceByRange(
        userId: widget.userId,
        startDate: _startDate,
        endDate: _endDate,
      );

      // =====================================================
      // HITUNG HARI MASUK
      //
      // Set dipakai supaya satu tanggal hanya dihitung sekali.
      // =====================================================

      final attendanceDates =
          <String>{};

      // =====================================================
      // HITUNG LEMBUR
      //
      // is_overtime = true
      // berarti pegawai mengambil shift kedua.
      //
      // 1 record lembur = 1 kali lembur.
      // =====================================================

      int overtimeCount = 0;

      for (final item in attendance) {
        final date =
            item['attendance_date']
                ?.toString();

        final checkIn =
            item['check_in'];

        // ===================================================
        // HADIR
        // ===================================================

        if (date != null &&
            date.trim().isNotEmpty &&
            checkIn != null) {
          attendanceDates.add(
            date,
          );
        }

        // ===================================================
        // LEMBUR / SHIFT KEDUA
        // ===================================================

        if (item['is_overtime'] ==
            true) {
          overtimeCount++;
        }
      }

      final attendanceDays =
          attendanceDates.length;

      // =====================================================
      // GAJI KEHADIRAN
      //
      // contoh:
      // 24 × 100.000
      // =====================================================

      final attendanceSalary =
          attendanceDays *
              dailySalary;

      // =====================================================
      // TAMBAHAN LEMBUR
      //
      // Karena shift pertama SUDAH masuk dalam attendanceDays,
      // lembur hanya menambah 1 × gaji harian lagi.
      //
      // contoh:
      // 5 kali × 100.000
      // =====================================================

      final overtimeSalary =
          overtimeCount *
              dailySalary;

      // =====================================================
      // TOTAL
      // =====================================================

      final grandTotal =
          attendanceSalary +
              overtimeSalary;

      if (!mounted) {
        return;
      }

      setState(() {
        _attendanceData = attendance;

        _attendanceDays =
            attendanceDays;

        _overtimeCount =
            overtimeCount;

        _dailySalary =
            dailySalary;

        _attendanceSalary =
            attendanceSalary;

        _overtimeSalary =
            overtimeSalary;

        _grandTotal =
            grandTotal;

        _hasResult = true;
      });
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
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // PARSE MONEY
  // =========================================================

  double _parseMoney(
    String text,
  ) {
    final cleaned =
        text.replaceAll(
      RegExp(
        r'[^0-9]',
      ),
      '',
    );

    return double.tryParse(
          cleaned,
        ) ??
        0;
  }

  // =========================================================
  // FORMAT RUPIAH
  // =========================================================

  String _rupiah(
    num value,
  ) {
    final number =
        value.round();

    final text =
        number.toString();

    final result =
        StringBuffer();

    for (int i = 0;
        i < text.length;
        i++) {
      if (i > 0 &&
          (text.length - i) %
                  3 ==
              0) {
        result.write('.');
      }

      result.write(
        text[i],
      );
    }

    return 'Rp${result.toString()}';
  }

  // =========================================================
  // FORMAT INPUT GAJI
  // =========================================================

  void _formatSalaryInput(
    String value,
  ) {
    final number =
        _parseMoney(value);

    if (number <= 0) {
      return;
    }

    final formatted =
        _rupiah(number)
            .replaceFirst(
              'Rp',
              '',
            );

    if (_dailySalaryController.text ==
        formatted) {
      return;
    }

    _dailySalaryController.value =
        TextEditingValue(
      text: formatted,
      selection:
          TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }

  // =========================================================
  // DATE TEXT
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
  // DATE FIELD
  // =========================================================

  Widget _dateField({
    required String title,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap:
          _loading
              ? null
              : onTap,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child: InputDecorator(
        decoration:
            InputDecoration(
          labelText: title,
          prefixIcon:
              const Icon(
            Icons
                .calendar_month_rounded,
          ),
          suffixIcon:
              const Icon(
            Icons
                .arrow_drop_down_rounded,
          ),
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
        child: Text(
          _dateText(value),
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final colors =
        Theme.of(context)
            .colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            colors.primaryContainer
                .withValues(
          alpha: 0.35,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              colors.primary
                  .withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(
              color:
                  colors.primary
                      .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color:
                  colors.primary,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium,
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  value,
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  subtitle,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SALARY ROW
  // =========================================================

  Widget _salaryRow({
    required String title,
    required String calculation,
    required String value,
    bool grandTotal = false,
  }) {
    final primary =
        Theme.of(context)
            .colorScheme
            .primary;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 15,
      ),
      decoration:
          const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Color(
              0xFFE6E6E6,
            ),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      TextStyle(
                    fontSize:
                        grandTotal
                            ? 17
                            : 15,
                    fontWeight:
                        grandTotal
                            ? FontWeight.bold
                            : FontWeight
                                .w600,
                  ),
                ),

                if (calculation
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    calculation,
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Text(
            value,
            style:
                TextStyle(
              fontSize:
                  grandTotal
                      ? 19
                      : 15,
              fontWeight:
                  FontWeight.bold,
              color:
                  grandTotal
                      ? primary
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RESULT
  // =========================================================

  Widget _buildResult() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .stretch,
      children: [
        const SizedBox(
          height: 30,
        ),

        // ===================================================
        // RESULT TITLE
        // ===================================================

        Text(
          'Hasil Perhitungan',
          style:
              Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          '${_dateText(_startDate)} - '
          '${_dateText(_endDate)}',
        ),

        const SizedBox(
          height: 20,
        ),

        // ===================================================
        // SUMMARY
        // ===================================================

        LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final mobile =
                constraints.maxWidth <
                    600;

            final attendanceCard =
                _summaryCard(
              icon:
                  Icons
                      .event_available_rounded,
              title:
                  'Hari Masuk',
              value:
                  '$_attendanceDays hari',
              subtitle:
                  'Jumlah hari pegawai hadir',
            );

            final overtimeCard =
                _summaryCard(
              icon:
                  Icons.more_time_rounded,
              title:
                  'Lembur',
              value:
                  '$_overtimeCount kali',
              subtitle:
                  '1 lembur = tambahan 1× gaji harian',
            );

            if (mobile) {
              return Column(
                children: [
                  attendanceCard,

                  const SizedBox(
                    height: 12,
                  ),

                  overtimeCard,
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child:
                      attendanceCard,
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child:
                      overtimeCard,
                ),
              ],
            );
          },
        ),

        const SizedBox(
          height: 24,
        ),

        // ===================================================
        // SALARY DETAILS
        // ===================================================

        Container(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            8,
          ),
          decoration:
              BoxDecoration(
            color:
                Theme.of(context)
                    .colorScheme
                    .surface,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border:
                Border.all(
              color:
                  Theme.of(context)
                      .colorScheme
                      .outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons
                        .payments_rounded,
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  Text(
                    'Rincian Gaji',
                    style:
                        Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // GAJI KEHADIRAN
              // =================================================

              _salaryRow(
                title:
                    'Gaji Kehadiran',
                calculation:
                    '$_attendanceDays hari × '
                    '${_rupiah(_dailySalary)}',
                value:
                    _rupiah(
                  _attendanceSalary,
                ),
              ),

              // =================================================
              // LEMBUR
              // =================================================

              _salaryRow(
                title:
                    'Tambahan Lembur',
                calculation:
                    '$_overtimeCount kali × '
                    '${_rupiah(_dailySalary)}',
                value:
                    _rupiah(
                  _overtimeSalary,
                ),
              ),

              // =================================================
              // TOTAL
              // =================================================

              _salaryRow(
                title:
                    'TOTAL GAJI',
                calculation:
                    '${_rupiah(_attendanceSalary)} + '
                    '${_rupiah(_overtimeSalary)}',
                value:
                    _rupiah(
                  _grandTotal,
                ),
                grandTotal:
                    true,
              ),
            ],
          ),
        ),

        // ===================================================
        // INFO
        // ===================================================

        const SizedBox(
          height: 16,
        ),

        Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.blue
                    .withValues(
              alpha: 0.06,
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border:
                Border.all(
              color:
                  Colors.blue
                      .withValues(
                alpha: 0.15,
              ),
            ),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color:
                    Colors.blue,
              ),

              SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  'Hari lembur sudah termasuk dalam hari masuk. '
                  'Karena lembur berarti bekerja 2 shift, '
                  'setiap 1 kali lembur mendapat tambahan '
                  '1× gaji harian.',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          '${_attendanceData.length} data presensi '
          'ditemukan pada periode ini.',
          textAlign:
              TextAlign.center,
          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
        ),
      ],
    );
  }

  // =========================================================
  // EMPTY RESULT
  // =========================================================

  Widget _buildNoAttendanceWarning() {
    if (!_hasResult ||
        _attendanceDays >
            0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          const EdgeInsets.only(
        top: 18,
      ),
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
      ),
      child:
          const Row(
        children: [
          Icon(
            Icons
                .event_busy_rounded,
            color:
                Colors.orange,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              'Tidak ditemukan presensi masuk pada periode tersebut.',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _dailySalaryController
        .dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final media =
        MediaQuery.sizeOf(
      context,
    );

    final isMobile =
        media.width < 700;

    final bottomSafe =
        MediaQuery.viewPaddingOf(
      context,
    ).bottom;

    return Scaffold(
      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title:
            const Text(
          'Hitung Gaji',
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        bottom: false,

        child: ListView(
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

            90 +
                bottomSafe,
          ),

          children: [
            Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 720,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,

                  children: [
                    // =========================================
                    // EMPLOYEE
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
                                  alpha: 0.40,
                                ),
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius:
                                25,
                            child:
                                Text(
                              widget.employeeName
                                      .trim()
                                      .isNotEmpty
                                  ? widget
                                      .employeeName[
                                          0]
                                      .toUpperCase()
                                  : '?',

                              style:
                                  const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 13,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Kalkulator Gaji',

                                  style:
                                      Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                ),

                                const SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  widget
                                      .employeeName,

                                  style:
                                      Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    // =========================================
                    // PERIOD
                    // =========================================

                    Text(
                      'Periode Presensi',

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
                      height: 6,
                    ),

                    const Text(
                      'Pilih rentang tanggal yang ingin dihitung.',
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    if (isMobile) ...[
                      _dateField(
                        title:
                            'Tanggal Awal',
                        value:
                            _startDate,
                        onTap:
                            _selectStartDate,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _dateField(
                        title:
                            'Tanggal Akhir',
                        value:
                            _endDate,
                        onTap:
                            _selectEndDate,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child:
                                _dateField(
                              title:
                                  'Tanggal Awal',
                              value:
                                  _startDate,
                              onTap:
                                  _selectStartDate,
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child:
                                _dateField(
                              title:
                                  'Tanggal Akhir',
                              value:
                                  _endDate,
                              onTap:
                                  _selectEndDate,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(
                      height: 28,
                    ),

                    // =========================================
                    // SALARY
                    // =========================================

                    Text(
                      'Gaji Pegawai',

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
                      height: 6,
                    ),

                    const Text(
                      'Masukkan nominal gaji untuk satu shift / satu hari kerja.',
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                          _dailySalaryController,

                      enabled:
                          !_loading,

                      keyboardType:
                          TextInputType.number,

                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                      ],

                      onChanged:
                          _formatSalaryInput,

                      textInputAction:
                          TextInputAction.done,

                      onSubmitted:
                          (_) {
                        _calculate();
                      },

                      decoration:
                          InputDecoration(
                        labelText:
                            'Gaji Per Hari / Shift',

                        hintText:
                            'Contoh: 100.000',

                        prefixText:
                            'Rp ',

                        prefixIcon:
                            const Icon(
                          Icons
                              .payments_rounded,
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
                      height: 22,
                    ),

                    // =========================================
                    // BUTTON
                    // =========================================

                    SizedBox(
                      height:
                          55,

                      child:
                          FilledButton.icon(
                        onPressed:
                            _loading
                                ? null
                                : _calculate,

                        icon:
                            _loading
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
                                        .calculate_rounded,
                                  ),

                        label:
                            Text(
                          _loading
                              ? 'MENGHITUNG...'
                              : 'HITUNG GAJI',
                        ),
                      ),
                    ),

                    // =========================================
                    // EMPTY WARNING
                    // =========================================

                    _buildNoAttendanceWarning(),

                    // =========================================
                    // RESULT
                    // =========================================

                    if (_hasResult &&
                        _attendanceDays >
                            0)
                      _buildResult(),
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