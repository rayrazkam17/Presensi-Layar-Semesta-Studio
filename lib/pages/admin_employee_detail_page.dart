import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/attendance_service.dart';

import 'admin_salary_calculator_page.dart';

class AdminEmployeeDetailPage extends StatefulWidget {
  final String userId;
  final String nama;
  final String role;
  final int month;
  final int year;

  const AdminEmployeeDetailPage({
    super.key,
    required this.userId,
    required this.nama,
    required this.role,
    required this.month,
    required this.year,
  });

  @override
  State<AdminEmployeeDetailPage> createState() =>
      _AdminEmployeeDetailPageState();
}

class _AdminEmployeeDetailPageState
    extends State<AdminEmployeeDetailPage> {
  // =========================================================
  // SERVICE
  // =========================================================

  final AttendanceService attendanceService =
      AttendanceService();

  late Future<List<Map<String, dynamic>>>
      attendanceFuture;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadAttendance();
  }

  // =========================================================
  // LOAD ATTENDANCE
  // =========================================================

  void _loadAttendance() {
    attendanceFuture =
        attendanceService.getEmployeeAttendance(
      userId: widget.userId,
      month: widget.month,
      year: widget.year,
    );
  }

  // =========================================================
  // REFRESH
  // =========================================================

  void refreshData() {
    setState(() {
      _loadAttendance();
    });
  }

  // =========================================================
  // OPEN SALARY CALCULATOR
  // =========================================================

  Future<void> _openSalaryCalculator() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminSalaryCalculatorPage(
          userId: widget.userId,
          employeeName: widget.nama,
        ),
      ),
    );
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      );

      return DateFormat(
        'dd MMM yyyy',
        'id_ID',
      ).format(date);
    } catch (_) {
      return '-';
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String formatTime(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      return DateFormat(
        'HH:mm',
        'id_ID',
      ).format(date);
    } catch (_) {
      return '-';
    }
  }

  // =========================================================
  // TO DOUBLE
  // =========================================================

  double toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // =========================================================
  // FORMAT WORK DURATION
  // =========================================================

  String formatWorkDuration(
    dynamic value,
  ) {
    final totalHours =
        toDouble(value);

    final totalMinutes =
        (totalHours * 60).round();

    final hours =
        totalMinutes ~/ 60;

    final minutes =
        totalMinutes % 60;

    if (hours == 0 &&
        minutes == 0) {
      return '-';
    }

    if (hours == 0) {
      return '$minutes menit';
    }

    if (minutes == 0) {
      return '$hours jam';
    }

    return '$hours jam $minutes menit';
  }

  // =========================================================
  // SIGNED PHOTO URL
  // =========================================================

  Future<String?> getPhotoSignedUrl(
    String? photoPath,
  ) async {
    if (photoPath == null ||
        photoPath.isEmpty) {
      return null;
    }

    try {
      return await Supabase
          .instance
          .client
          .storage
          .from(
            'attendance-photos',
          )
          .createSignedUrl(
            photoPath,
            60 * 10,
          );
    } catch (e) {
      debugPrint(
        'Gagal membuat signed URL: $e',
      );

      return null;
    }
  }

  // =========================================================
  // PHOTO DIALOG
  // =========================================================

  void showAttendancePhotoDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final checkInPhoto =
        item['check_in_photo']
            ?.toString();

    final checkOutPhoto =
        item['check_out_photo']
            ?.toString();

    final isAutoCheckout =
        item['is_auto_checkout'] ==
            true;

    final isManual =
        item['is_manual'] == true;

    showDialog(
      context: context,

      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title:
              const Text(
            'Bukti Foto Presensi',
          ),

          content:
              SizedBox(
            width: 420,

            child:
                FutureBuilder<
                    List<String?>>(
              future: Future.wait([
                getPhotoSignedUrl(
                  checkInPhoto,
                ),
                getPhotoSignedUrl(
                  checkOutPhoto,
                ),
              ]),

              builder: (
                context,
                snapshot,
              ) {
                // =============================================
                // LOADING
                // =============================================

                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const SizedBox(
                    height: 180,

                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                // =============================================
                // ERROR
                // =============================================

                if (snapshot.hasError) {
                  return Text(
                    'Gagal memuat bukti foto:\n'
                    '${snapshot.error}',
                  );
                }

                final urls =
                    snapshot.data ??
                        [
                          null,
                          null,
                        ];

                final checkInUrl =
                    urls[0];

                final checkOutUrl =
                    urls[1];

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      // =======================================
                      // MANUAL INFO
                      // =======================================

                      if (isManual) ...[
                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets.all(
                            12,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.orange
                                    .withValues(
                              alpha:
                                  0.08,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),

                            border:
                                Border.all(
                              color:
                                  Colors.orange
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
                                    .admin_panel_settings_rounded,

                                color:
                                    Colors.orange,
                              ),

                              SizedBox(
                                width:
                                    8,
                              ),

                              Expanded(
                                child:
                                    Text(
                                  'Presensi ini dimasukkan secara manual oleh admin.',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height:
                              18,
                        ),
                      ],

                      // =======================================
                      // CHECK IN
                      // =======================================

                      const Text(
                        'Foto Check-in',

                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      if (checkInUrl !=
                          null)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),

                          child:
                              Image.network(
                            checkInUrl,

                            width:
                                double.infinity,

                            height:
                                220,

                            fit:
                                BoxFit.cover,

                            errorBuilder: (
                              _,
                              error,
                              stackTrace,
                            ) {
                              debugPrint(
                                'Gagal load foto check-in: $error',
                              );

                              return const Padding(
                                padding:
                                    EdgeInsets.all(
                                  8,
                                ),

                                child:
                                    Text(
                                  'Foto check-in tidak dapat dimuat',
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Text(
                          isManual
                              ? 'Tidak ada foto karena presensi dimasukkan oleh admin.'
                              : 'Foto check-in belum tersedia',
                        ),

                      const SizedBox(
                        height: 20,
                      ),

                      // =======================================
                      // CHECK OUT
                      // =======================================

                      const Text(
                        'Foto Check-out',

                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      if (checkOutUrl !=
                          null)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),

                          child:
                              Image.network(
                            checkOutUrl,

                            width:
                                double.infinity,

                            height:
                                220,

                            fit:
                                BoxFit.cover,

                            errorBuilder: (
                              _,
                              error,
                              stackTrace,
                            ) {
                              debugPrint(
                                'Gagal load foto check-out: $error',
                              );

                              return const Padding(
                                padding:
                                    EdgeInsets.all(
                                  8,
                                ),

                                child:
                                    Text(
                                  'Foto check-out tidak dapat dimuat',
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Text(
                          isManual
                              ? 'Tidak ada foto karena presensi dimasukkan oleh admin.'
                              : isAutoCheckout
                                  ? 'Tidak ada foto keluar karena sistem melakukan auto checkout.'
                                  : 'Foto check-out belum tersedia',
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child:
                  const Text(
                'Tutup',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),

      child:
          Row(
        children: [
          SizedBox(
            width: 80,

            child:
                Text(
              '$label :',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            child:
                Text(
              value,

              style:
                  TextStyle(
                color:
                    valueColor,

                fontWeight:
                    valueColor !=
                            null
                        ? FontWeight
                            .w600
                        : FontWeight
                            .normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _buildStatusBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            9,

        vertical:
            5,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          100,
        ),

        border:
            Border.all(
          color:
              color.withValues(
            alpha:
                0.25,
          ),
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,

            size:
                14,

            color:
                color,
          ),

          const SizedBox(
            width:
                5,
          ),

          Text(
            text,

            style:
                TextStyle(
              color:
                  color,

              fontSize:
                  11,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MOBILE ATTENDANCE CARD
  // =========================================================

  Widget _buildMobileAttendanceCard(
    Map<String, dynamic> item,
  ) {
    final isOvertime =
        item['is_overtime'] == true;

    final isAutoCheckout =
        item['is_auto_checkout'] ==
            true;

    final isManual =
        item['is_manual'] == true;

    final manualReason =
        item['manual_reason']
            ?.toString();

    final hasCheckInPhoto =
        item['check_in_photo'] != null &&
            item['check_in_photo']
                .toString()
                .isNotEmpty;

    final hasCheckOutPhoto =
        item['check_out_photo'] != null &&
            item['check_out_photo']
                .toString()
                .isNotEmpty;

    final hasAnyPhoto =
        hasCheckInPhoto ||
            hasCheckOutPhoto;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child:
          Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            // =================================================
            // DATE
            // =================================================

            Text(
              formatDate(
                item[
                    'attendance_date'],
              ),

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,

                fontSize:
                    16,
              ),
            ),

            // =================================================
            // BADGES
            // =================================================

            if (isManual ||
                isOvertime ||
                isAutoCheckout) ...[
              const SizedBox(
                height:
                    10,
              ),

              Wrap(
                spacing:
                    7,

                runSpacing:
                    7,

                children: [
                  if (isManual)
                    _buildStatusBadge(
                      icon:
                          Icons
                              .edit_calendar_rounded,

                      text:
                          'MANUAL ADMIN',

                      color:
                          Colors.orange,
                    ),

                  if (isOvertime)
                    _buildStatusBadge(
                      icon:
                          Icons
                              .more_time_rounded,

                      text:
                          'LEMBUR',

                      color:
                          Colors.purple,
                    ),

                  if (isAutoCheckout)
                    _buildStatusBadge(
                      icon:
                          Icons
                              .schedule_send_rounded,

                      text:
                          'AUTO CHECKOUT',

                      color:
                          Colors.blueGrey,
                    ),
                ],
              ),
            ],

            const Divider(
              height:
                  24,
            ),

            _buildInfoRow(
              'Masuk',
              formatTime(
                item['check_in'],
              ),
            ),

            _buildInfoRow(
              'Keluar',
              formatTime(
                item['check_out'],
              ),
            ),

            _buildInfoRow(
              'Durasi',
              formatWorkDuration(
                item[
                    'total_work_hours'],
              ),
            ),

            _buildInfoRow(
              'Lembur',
              isOvertime
                  ? 'Ya'
                  : 'Tidak',
            ),

            _buildInfoRow(
              'Status',
              isManual
                  ? 'Presensi Manual Admin'
                  : isAutoCheckout
                      ? 'Auto Checkout'
                      : 'Checkout Manual',

              valueColor:
                  isManual
                      ? Colors.orange
                      : isAutoCheckout
                          ? Colors.orange
                          : Colors.green,
            ),

            // =================================================
            // MANUAL REASON
            // =================================================

            if (isManual &&
                manualReason !=
                    null &&
                manualReason
                    .trim()
                    .isNotEmpty)
              _buildInfoRow(
                'Alasan',
                manualReason,
                valueColor:
                    Colors.orange,
              ),

            const SizedBox(
              height:
                  8,
            ),

            // =================================================
            // PHOTO
            // =================================================

            Align(
              alignment:
                  Alignment.centerRight,

              child:
                  hasAnyPhoto
                      ? TextButton.icon(
                          icon:
                              const Icon(
                            Icons
                                .photo_outlined,
                          ),

                          label:
                              const Text(
                            'Lihat Bukti',
                          ),

                          onPressed:
                              () {
                            showAttendancePhotoDialog(
                              context,
                              item,
                            );
                          },
                        )
                      : Text(
                          isManual
                              ? 'Presensi Manual'
                              : isAutoCheckout
                                  ? 'Tidak ada foto keluar'
                                  : '-',

                          style:
                              TextStyle(
                            color:
                                isManual
                                    ? Colors.orange
                                    : null,

                            fontWeight:
                                isManual
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DESKTOP ATTENDANCE TABLE
  // =========================================================

  Widget _buildAttendanceTable(
    List<Map<String, dynamic>> records,
  ) {
    return Card(
      child:
          Column(
        children: [
          // =================================================
          // HEADER
          // =================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  12,

              vertical:
                  14,
            ),

            child:
                const Row(
              children: [
                Expanded(
                  flex:
                      3,

                  child:
                      Text(
                    'Tanggal',

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  flex:
                      2,

                  child:
                      Text(
                    'Masuk',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  flex:
                      2,

                  child:
                      Text(
                    'Keluar',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  flex:
                      3,

                  child:
                      Text(
                    'Durasi',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  flex:
                      2,

                  child:
                      Text(
                    'Lembur',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  flex:
                      3,

                  child:
                      Text(
                    'Status',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  flex:
                      2,

                  child:
                      Text(
                    'Bukti',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height:
                1,
          ),

          // =================================================
          // ROWS
          // =================================================

          ...records.map(
            (
              item,
            ) {
              final isOvertime =
                  item['is_overtime'] ==
                      true;

              final isAutoCheckout =
                  item[
                          'is_auto_checkout'] ==
                      true;

              final isManual =
                  item['is_manual'] ==
                      true;

              final hasCheckInPhoto =
                  item['check_in_photo'] !=
                          null &&
                      item['check_in_photo']
                          .toString()
                          .isNotEmpty;

              final hasCheckOutPhoto =
                  item['check_out_photo'] !=
                          null &&
                      item['check_out_photo']
                          .toString()
                          .isNotEmpty;

              final hasAnyPhoto =
                  hasCheckInPhoto ||
                      hasCheckOutPhoto;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      12,

                  vertical:
                      14,
                ),

                child:
                    Row(
                  children: [
                    Expanded(
                      flex:
                          3,

                      child:
                          Text(
                        formatDate(
                          item[
                              'attendance_date'],
                        ),
                      ),
                    ),

                    Expanded(
                      flex:
                          2,

                      child:
                          Text(
                        formatTime(
                          item[
                              'check_in'],
                        ),

                        textAlign:
                            TextAlign.center,
                      ),
                    ),

                    Expanded(
                      flex:
                          2,

                      child:
                          Text(
                        formatTime(
                          item[
                              'check_out'],
                        ),

                        textAlign:
                            TextAlign.center,
                      ),
                    ),

                    Expanded(
                      flex:
                          3,

                      child:
                          Text(
                        formatWorkDuration(
                          item[
                              'total_work_hours'],
                        ),

                        textAlign:
                            TextAlign.center,
                      ),
                    ),

                    Expanded(
                      flex:
                          2,

                      child:
                          Text(
                        isOvertime
                            ? 'Ya'
                            : 'Tidak',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              isOvertime
                                  ? Colors.purple
                                  : null,

                          fontWeight:
                              isOvertime
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ),

                    Expanded(
                      flex:
                          3,

                      child:
                          Text(
                        isManual
                            ? 'Manual Admin'
                            : isAutoCheckout
                                ? 'Auto'
                                : 'Manual',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color:
                              isManual
                                  ? Colors.orange
                                  : isAutoCheckout
                                      ? Colors.orange
                                      : Colors.green,

                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    Expanded(
                      flex:
                          2,

                      child:
                          hasAnyPhoto
                              ? TextButton(
                                  onPressed:
                                      () {
                                    showAttendancePhotoDialog(
                                      context,
                                      item,
                                    );
                                  },

                                  child:
                                      const Text(
                                    'Lihat',
                                  ),
                                )
                              : Text(
                                  isManual
                                      ? 'Manual'
                                      : isAutoCheckout
                                          ? 'Tidak ada'
                                          : '-',

                                  textAlign:
                                      TextAlign.center,

                                  style:
                                      TextStyle(
                                    color:
                                        isManual
                                            ? Colors.orange
                                            : null,
                                  ),
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
    final periode =
        DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(
      DateTime(
        widget.year,
        widget.month,
      ),
    ).toUpperCase();

    final bottomSafeArea =
        MediaQuery.viewPaddingOf(
      context,
    ).bottom;

    return Scaffold(
      // =====================================================
      // APP BAR
      // =====================================================

      appBar:
          AppBar(
        title:
            const Text(
          'Detail Presensi Pegawai',
        ),

        actions: [
          IconButton(
            tooltip:
                'Refresh',

            icon:
                const Icon(
              Icons.refresh,
            ),

            onPressed:
                refreshData,
          ),
        ],
      ),

      // =====================================================
      // FLOATING BUTTON HITUNG GAJI
      // =====================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _openSalaryCalculator,

        icon:
            const Icon(
          Icons.calculate_rounded,
        ),

        label:
            const Text(
          'Hitung Gaji',
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,

      // =====================================================
      // BODY
      // =====================================================

      body:
          FutureBuilder<
              List<
                  Map<
                      String,
                      dynamic>>>(
        future:
            attendanceFuture,

        builder: (
          context,
          snapshot,
        ) {
          // =================================================
          // LOADING
          // =================================================

          if (snapshot
                  .connectionState ==
              ConnectionState
                  .waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // =================================================
          // ERROR
          // =================================================

          if (snapshot.hasError) {
            return Center(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),

                child:
                    Text(
                  'Gagal memuat detail:\n'
                  '${snapshot.error}',

                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final records =
              snapshot.data ??
                  [];

          // =================================================
          // TOTAL HADIR
          // =================================================

          final totalHadir =
              records.length;

          // =================================================
          // TOTAL LEMBUR
          //
          // Sekarang memakai satuan "KALI".
          // =================================================

          final totalLembur =
              records.where(
            (
              item,
            ) =>
                item['is_overtime'] ==
                true,
          ).length;

          // =================================================
          // TOTAL JAM KERJA
          // =================================================

          final totalJamKerja =
              records.fold<double>(
            0,

            (
              sum,
              item,
            ) =>
                sum +
                toDouble(
                  item[
                      'total_work_hours'],
                ),
          );

          // =================================================
          // RESPONSIVE
          // =================================================

          return LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final isMobile =
                  constraints
                          .maxWidth <
                      700;

              final padding =
                  isMobile
                      ? 12.0
                      : 16.0;

              return SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(
                  parent:
                      BouncingScrollPhysics(),
                ),

                // Memberi ruang agar FAB tidak menutupi
                // card terakhir.
                padding:
                    EdgeInsets.fromLTRB(
                  padding,
                  padding,
                  padding,
                  110 +
                      bottomSafeArea,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    // =========================================
                    // EMPLOYEE SUMMARY
                    // =========================================

                    Card(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius:
                                      25,

                                  child:
                                      Text(
                                    widget.nama
                                            .trim()
                                            .isNotEmpty
                                        ? widget
                                            .nama[
                                                0]
                                            .toUpperCase()
                                        : '?',

                                    style:
                                        const TextStyle(
                                      fontSize:
                                          18,

                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      13,
                                ),

                                Expanded(
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [
                                      Text(
                                        widget.nama,

                                        style:
                                            const TextStyle(
                                          fontSize:
                                              20,

                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height:
                                            3,
                                      ),

                                      Text(
                                        'Role: ${widget.role}',
                                      ),

                                      Text(
                                        'Periode: $periode',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height:
                                  18,
                            ),

                            const Divider(),

                            const SizedBox(
                              height:
                                  8,
                            ),

                            // =================================
                            // SUMMARY
                            // =================================

                            _buildInfoRow(
                              'Hadir',
                              '$totalHadir hari',
                            ),

                            _buildInfoRow(
                              'Lembur',
                              '$totalLembur kali',
                              valueColor:
                                  totalLembur >
                                          0
                                      ? Colors.purple
                                      : null,
                            ),

                            _buildInfoRow(
                              'Jam Kerja',
                              formatWorkDuration(
                                totalJamKerja,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // =========================================
                    // RIWAYAT TITLE
                    // =========================================

                    Row(
                      children: [
                        const Expanded(
                          child:
                              Text(
                            'RIWAYAT PRESENSI',

                            style:
                                TextStyle(
                              fontSize:
                                  18,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        Text(
                          '${records.length} data',

                          style:
                              Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // =========================================
                    // EMPTY
                    // =========================================

                    if (records.isEmpty)
                      const Padding(
                        padding:
                            EdgeInsets.only(
                          top:
                              40,
                        ),

                        child:
                            Center(
                          child:
                              Column(
                            children: [
                              Icon(
                                Icons
                                    .event_busy_rounded,

                                size:
                                    46,
                              ),

                              SizedBox(
                                height:
                                    10,
                              ),

                              Text(
                                'Belum ada riwayat presensi '
                                'pada periode ini',

                                textAlign:
                                    TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )

                    // =========================================
                    // MOBILE
                    // =========================================

                    else if (isMobile)
                      Column(
                        children:
                            records
                                .map(
                                  (
                                    item,
                                  ) =>
                                      _buildMobileAttendanceCard(
                                    item,
                                  ),
                                )
                                .toList(),
                      )

                    // =========================================
                    // DESKTOP
                    // =========================================

                    else
                      _buildAttendanceTable(
                        records,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}