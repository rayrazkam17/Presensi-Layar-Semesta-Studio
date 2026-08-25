import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/admin_control_service.dart';
import '../services/attendance_service.dart';
import '../widgets/current_user_header.dart';

import 'admin_employee_recap_page.dart';
import 'admin_manual_attendance_page.dart';
import 'admin_user_management_page.dart';
import 'login_page.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({
    super.key,
  });

  @override
  State<DashboardAdminPage> createState() =>
      _DashboardAdminPageState();
}

class _DashboardAdminPageState
    extends State<DashboardAdminPage> {
  // =========================================================
  // SERVICES
  // =========================================================

  final AttendanceService _attendanceService =
      AttendanceService();

  final AdminControlService _adminControlService =
      AdminControlService();

  // =========================================================
  // ATTENDANCE FUTURE
  // =========================================================

  late Future<List<Map<String, dynamic>>>
      _attendanceFuture;

  // =========================================================
  // DELETE STATE
  // =========================================================

  String? _deletingAttendanceId;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _attendanceFuture =
        _attendanceService.getAllAttendance();
  }

  // =========================================================
  // REFRESH
  // =========================================================

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(() {
      _attendanceFuture =
          _attendanceService.getAllAttendance();
    });
  }

  // =========================================================
  // REFRESH ASYNC
  // =========================================================

  Future<void> _refreshAsync() async {
    final future =
        _attendanceService.getAllAttendance();

    if (mounted) {
      setState(() {
        _attendanceFuture = future;
      });
    }

    try {
      await future;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          icon: const Icon(
            Icons.logout_rounded,
            size: 40,
          ),
          title: const Text(
            'Logout?',
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun admin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'BATAL',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'LOGOUT',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await Supabase.instance.client.auth.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // OPEN MANUAL ATTENDANCE
  // =========================================================

  Future<void> _openManualAttendance() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminManualAttendancePage(),
      ),
    );

    if (!mounted) {
      return;
    }

    _refresh();
  }

  // =========================================================
  // OPEN USER MANAGEMENT
  // =========================================================

  Future<void> _openUserManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminUserManagementPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    _refresh();
  }

  // =========================================================
  // OPEN RECAP
  // =========================================================

  Future<void> _openRecap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminEmployeeRecapPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    _refresh();
  }

  // =========================================================
  // DELETE ATTENDANCE
  // =========================================================

  Future<void> _deleteAttendance(
    Map<String, dynamic> attendance,
  ) async {
    final id =
        attendance['id']?.toString();

    if (id == null ||
        id.isEmpty) {
      _showMessage(
        'ID presensi tidak ditemukan.',
        error: true,
      );

      return;
    }

    final employeeName =
        _getEmployeeName(
      attendance,
    );

    final attendanceDate =
        _formatAttendanceDate(
      attendance['attendance_date'],
    );

    final isManual =
        attendance['is_manual'] == true;

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            size: 46,
            color: Theme.of(context)
                .colorScheme
                .error,
          ),
          title: const Text(
            'Hapus Data Presensi?',
          ),
          content: Text(
            'Anda akan menghapus data presensi:\n\n'
            'Pegawai: $employeeName\n'
            'Tanggal: $attendanceDate'
            '${isManual ? '\nJenis: Presensi Manual Admin' : ''}'
            '\n\n'
            'Data yang sudah dihapus tidak dapat dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'BATAL',
              ),
            ),
            FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .error,
                foregroundColor:
                    Theme.of(context)
                        .colorScheme
                        .onError,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.delete_forever_rounded,
              ),
              label: const Text(
                'HAPUS',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _deletingAttendanceId = id;
    });

    try {
      await _adminControlService
          .deleteAttendance(
        attendanceId: id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Data presensi $employeeName berhasil dihapus.',
      );

      _refresh();
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
          _deletingAttendanceId = null;
        });
      }
    }
  }

  // =========================================================
  // GET EMPLOYEE NAME
  // =========================================================

  String _getEmployeeName(
    Map<String, dynamic> attendance,
  ) {
    final profile =
        attendance['profiles'];

    if (profile is Map) {
      final nama =
          profile['nama']?.toString();

      if (nama != null &&
          nama.trim().isNotEmpty) {
        return nama;
      }
    }

    return 'Pegawai';
  }

  // =========================================================
  // FORMAT ATTENDANCE DATE
  // =========================================================

  String _formatAttendanceDate(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    final raw =
        value.toString();

    try {
      final parts =
          raw.split('-');

      if (parts.length != 3) {
        return raw;
      }

      final year =
          int.parse(parts[0]);

      final month =
          int.parse(parts[1]);

      final day =
          int.parse(
        parts[2].substring(
          0,
          2,
        ),
      );

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

      if (month < 1 ||
          month > 12) {
        return raw;
      }

      return '$day '
          '${months[month - 1]} '
          '$year';
    } catch (_) {
      return raw;
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String _formatLocalTime(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    final raw =
        value.toString();

    if (raw.isEmpty) {
      return '-';
    }

    try {
      final parsed =
          DateTime.parse(
        raw,
      );

      final local =
          parsed.toLocal();

      final hour =
          local.hour
              .toString()
              .padLeft(
                2,
                '0',
              );

      final minute =
          local.minute
              .toString()
              .padLeft(
                2,
                '0',
              );

      return '$hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  // =========================================================
  // FORMAT WORK HOURS
  // =========================================================

  String _formatWorkHours(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    final number =
        double.tryParse(
      value.toString(),
    );

    if (number == null) {
      return '-';
    }

    final hours =
        number.floor();

    final minutes =
        ((number - hours) * 60)
            .round();

    if (hours == 0) {
      return '$minutes menit';
    }

    if (minutes == 0) {
      return '$hours jam';
    }

    return '$hours jam $minutes menit';
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
  // SUMMARY HEADER
  // =========================================================

  Widget _buildSummaryHeader(
    List<Map<String, dynamic>> data,
  ) {
    final manualCount =
        data.where(
      (item) =>
          item['is_manual'] == true,
    ).length;

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final isMobile =
            constraints.maxWidth < 620;

        final totalCard =
            _summaryCard(
          icon:
              Icons.fact_check_rounded,
          title:
              'Total Data',
          value:
              '${data.length}',
        );

        final manualCard =
            _summaryCard(
          icon:
              Icons.edit_calendar_rounded,
          title:
              'Presensi Manual',
          value:
              '$manualCount',
        );

        if (isMobile) {
          return Column(
            children: [
              totalCard,
              const SizedBox(
                height: 12,
              ),
              manualCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child:
                  totalCard,
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child:
                  manualCard,
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            colorScheme
                .primaryContainer
                .withValues(
                  alpha: 0.35,
                ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              colorScheme
                  .primary
                  .withValues(
                    alpha: 0.12,
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
                  colorScheme
                      .primary
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
                  colorScheme.primary,
            ),
          ),
          const SizedBox(
            width: 14,
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
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MANUAL ATTENDANCE BUTTON
  // =========================================================

  Widget _buildManualAttendanceButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed:
            _openManualAttendance,
        icon: const Icon(
          Icons.edit_calendar_rounded,
        ),
        label: const Text(
          'INPUT PRESENSI MANUAL',
        ),
      ),
    );
  }

  // =========================================================
  // ATTENDANCE CARD
  // =========================================================

  Widget _buildAttendanceCard(
    Map<String, dynamic> attendance,
  ) {
    final id =
        attendance['id']?.toString() ??
            '';

    final employeeName =
        _getEmployeeName(
      attendance,
    );

    final date =
        _formatAttendanceDate(
      attendance[
          'attendance_date'],
    );

    final checkIn =
        _formatLocalTime(
      attendance['check_in'],
    );

    final checkOut =
        _formatLocalTime(
      attendance['check_out'],
    );

    final totalHours =
        _formatWorkHours(
      attendance[
          'total_work_hours'],
    );

    final overtimeHours =
        _formatWorkHours(
      attendance[
          'overtime_hours'],
    );

    final isOvertime =
        attendance['is_overtime'] ==
            true;

    final isAutoCheckout =
        attendance[
                'is_auto_checkout'] ==
            true;

    final isManual =
        attendance['is_manual'] ==
            true;

    final manualReason =
        attendance[
                'manual_reason']
            ?.toString()
            .trim();

    final manualNote =
        attendance[
                'manual_note']
            ?.toString()
            .trim();

    final deleting =
        _deletingAttendanceId ==
            id;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      clipBehavior:
          Clip.antiAlias,
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
          children: [
            // =================================================
            // HEADER
            // =================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    employeeName.isEmpty
                        ? '?'
                        : employeeName[0]
                            .toUpperCase(),
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        employeeName,
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
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons
                                .calendar_today_rounded,
                            size: 15,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Flexible(
                            child: Text(
                              date,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip:
                      'Hapus Presensi',
                  onPressed:
                      deleting
                          ? null
                          : () {
                              _deleteAttendance(
                                attendance,
                              );
                            },
                  icon: deleting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.delete_outline_rounded,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .error,
                        ),
                ),
              ],
            ),

            // =================================================
            // STATUS BADGES
            // =================================================

            if (isManual ||
                isAutoCheckout ||
                isOvertime) ...[
              const SizedBox(
                height: 14,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isManual)
                    _statusBadge(
                      icon:
                          Icons
                              .edit_calendar_rounded,
                      text:
                          'PRESENSI MANUAL',
                      color:
                          Colors.orange,
                    ),

                  if (isAutoCheckout)
                    _statusBadge(
                      icon:
                          Icons
                              .schedule_send_rounded,
                      text:
                          'AUTO CHECKOUT',
                      color:
                          Colors.blueGrey,
                    ),

                  if (isOvertime)
                    _statusBadge(
                      icon:
                          Icons
                              .more_time_rounded,
                      text:
                          'LEMBUR',
                      color:
                          Colors.purple,
                    ),
                ],
              ),
            ],

            const SizedBox(
              height: 16,
            ),

            const Divider(
              height: 1,
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // TIME
            // =================================================

            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final mobile =
                    constraints
                            .maxWidth <
                        500;

                final checkInWidget =
                    _attendanceInfo(
                  icon:
                      Icons.login_rounded,
                  label:
                      'Jam Masuk',
                  value:
                      checkIn,
                );

                final checkOutWidget =
                    _attendanceInfo(
                  icon:
                      Icons.logout_rounded,
                  label:
                      'Jam Keluar',
                  value:
                      checkOut,
                );

                if (mobile) {
                  return Column(
                    children: [
                      checkInWidget,
                      const SizedBox(
                        height: 14,
                      ),
                      checkOutWidget,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child:
                          checkInWidget,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child:
                          checkOutWidget,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(
              height: 14,
            ),

            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final mobile =
                    constraints
                            .maxWidth <
                        500;

                final totalWidget =
                    _attendanceInfo(
                  icon:
                      Icons
                          .access_time_filled_rounded,
                  label:
                      'Total Kerja',
                  value:
                      totalHours,
                );

                final overtimeWidget =
                    _attendanceInfo(
                  icon:
                      Icons
                          .more_time_rounded,
                  label:
                      'Lembur',
                  value:
                      isOvertime
                          ? overtimeHours
                          : 'Tidak',
                );

                if (mobile) {
                  return Column(
                    children: [
                      totalWidget,
                      const SizedBox(
                        height: 14,
                      ),
                      overtimeWidget,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child:
                          totalWidget,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child:
                          overtimeWidget,
                    ),
                  ],
                );
              },
            ),

            // =================================================
            // MANUAL INFORMATION
            // =================================================

            if (isManual) ...[
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
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons
                              .admin_panel_settings_rounded,
                          color:
                              Colors.orange,
                          size: 21,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            'Dimasukkan oleh Admin',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (manualReason !=
                            null &&
                        manualReason
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Alasan: $manualReason',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],

                    if (manualNote !=
                            null &&
                        manualNote
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        'Catatan: $manualNote',
                      ),
                    ],

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Foto presensi tidak diwajibkan untuk input manual.',
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ATTENDANCE INFO
  // =========================================================

  Widget _attendanceInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color:
                Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(
                      alpha: 0.10,
                    ),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color:
                Theme.of(context)
                    .colorScheme
                    .primary,
          ),
        ),
        const SizedBox(
          width: 11,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                label,
                style:
                    Theme.of(context)
                        .textTheme
                        .bodySmall,
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                value,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _statusBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          100,
        ),
        border:
            Border.all(
          color:
              color.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            text,
            style:
                TextStyle(
              color: color,
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 55,
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .event_busy_rounded,
            size: 60,
            color:
                Theme.of(context)
                    .colorScheme
                    .outline,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            'Belum Ada Data Presensi',
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
            'Data presensi pegawai akan tampil di sini.',
            textAlign:
                TextAlign.center,
          ),
          const SizedBox(
            height: 20,
          ),
          FilledButton.icon(
            onPressed:
                _openManualAttendance,
            icon: const Icon(
              Icons.edit_calendar_rounded,
            ),
            label: const Text(
              'INPUT PRESENSI MANUAL',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState(
    Object error,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 45,
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 58,
            color:
                Theme.of(context)
                    .colorScheme
                    .error,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            'Gagal Memuat Presensi',
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
            height: 8,
          ),
          Text(
            error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
            textAlign:
                TextAlign.center,
          ),
          const SizedBox(
            height: 18,
          ),
          FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'COBA LAGI',
            ),
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
    final width =
        MediaQuery.sizeOf(
      context,
    ).width;

    final isMobile =
        width < 700;

    final bottomSafeArea =
        MediaQuery.viewPaddingOf(
      context,
    ).bottom;

    return Scaffold(
      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title: const Text(
          'Dashboard Admin',
        ),
        centerTitle: true,

        actions: [
          // =================================================
          // PRESENSI MANUAL
          // =================================================

          IconButton(
            tooltip:
                'Presensi Manual',
            onPressed:
                _openManualAttendance,
            icon: const Icon(
              Icons.edit_calendar_rounded,
            ),
          ),

          // =================================================
          // USER MANAGEMENT
          // =================================================

          IconButton(
            tooltip:
                'Kelola Pegawai',
            onPressed:
                _openUserManagement,
            icon: const Icon(
              Icons
                  .manage_accounts_rounded,
            ),
          ),

          // =================================================
          // RECAP
          // =================================================

          IconButton(
            tooltip:
                'Rekap Pegawai',
            onPressed:
                _openRecap,
            icon: const Icon(
              Icons
                  .assessment_rounded,
            ),
          ),

          // =================================================
          // REFRESH
          // =================================================

          IconButton(
            tooltip:
                'Refresh',
            onPressed:
                _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),

          // =================================================
          // LOGOUT
          // =================================================

          IconButton(
            tooltip:
                'Logout',
            onPressed:
                _logout,
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),

          const SizedBox(
            width: 5,
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        bottom: false,

        child: RefreshIndicator(
          onRefresh:
              _refreshAsync,

          child: FutureBuilder<
              List<
                  Map<
                      String,
                      dynamic>>>(
            future:
                _attendanceFuture,

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
                return ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  children: const [
                    SizedBox(
                      height: 250,
                    ),

                    Center(
                      child:
                          CircularProgressIndicator(),
                    ),

                    SizedBox(
                      height: 14,
                    ),

                    Center(
                      child: Text(
                        'Memuat data presensi...',
                      ),
                    ),
                  ],
                );
              }

              // =================================================
              // ERROR
              // =================================================

              if (snapshot.hasError) {
                return ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      EdgeInsets.fromLTRB(
                    isMobile
                        ? 16
                        : 24,
                    20,
                    isMobile
                        ? 16
                        : 24,
                    80 +
                        bottomSafeArea,
                  ),

                  children: [
                    const CurrentUserHeader(),

                    _buildErrorState(
                      snapshot.error!,
                    ),
                  ],
                );
              }

              final data =
                  snapshot.data ??
                      [];

              // =================================================
              // CONTENT
              // =================================================

              return ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(
                  parent:
                      BouncingScrollPhysics(),
                ),

                padding:
                    EdgeInsets.fromLTRB(
                  isMobile
                      ? 16
                      : 24,

                  20,

                  isMobile
                      ? 16
                      : 24,

                  100 +
                      bottomSafeArea,
                ),

                children: [
                  Center(
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth:
                            950,
                      ),

                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,

                        children: [
                          // =====================================
                          // ADMIN HEADER
                          // =====================================

                          const CurrentUserHeader(),

                          const SizedBox(
                            height: 24,
                          ),

                          // =====================================
                          // TITLE
                          // =====================================

                          Text(
                            'Manajemen Presensi',

                            style:
                                Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Pantau presensi pegawai dan tambahkan '
                            'presensi manual apabila pegawai lupa absen '
                            'atau mengalami kendala sistem.',

                            style:
                                Theme.of(context)
                                    .textTheme
                                    .bodyLarge,
                          ),

                          const SizedBox(
                            height: 22,
                          ),

                          // =====================================
                          // MANUAL BUTTON
                          // =====================================

                          _buildManualAttendanceButton(),

                          const SizedBox(
                            height: 22,
                          ),

                          // =====================================
                          // SUMMARY
                          // =====================================

                          _buildSummaryHeader(
                            data,
                          ),

                          const SizedBox(
                            height: 30,
                          ),

                          // =====================================
                          // LIST TITLE
                          // =====================================

                          Row(
                            children: [
                              Expanded(
                                child:
                                    Text(
                                  'Data Presensi Pegawai',

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
                              ),

                              Text(
                                '${data.length} data',

                                style:
                                    Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // =====================================
                          // LIST
                          // =====================================

                          if (data.isEmpty)
                            _buildEmptyState()
                          else
                            ...data.map(
                              (
                                attendance,
                              ) =>
                                  _buildAttendanceCard(
                                attendance,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}