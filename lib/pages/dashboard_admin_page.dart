import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/admin_control_service.dart';
import '../services/attendance_service.dart';
import '../widgets/current_user_header.dart';

import 'admin_employee_recap_page.dart';
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

  final AttendanceService attendanceService =
      AttendanceService();

  final AdminControlService adminControlService =
      AdminControlService();

  // =========================================================
  // FUTURE DATA
  // =========================================================

  late Future<List<Map<String, dynamic>>>
      _attendanceFuture;

  // ID data yang sedang dihapus.
  String? _deletingAttendanceId;

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
    _attendanceFuture =
        attendanceService.getAllAttendance();
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> _refreshAttendance() async {
    setState(() {
      _loadAttendance();
    });

    try {
      await _attendanceFuture;
    } catch (_) {
      // Error sudah ditampilkan oleh FutureBuilder.
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String formatLocalTime(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(
        value.toString(),
      ).toLocal();

      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  // =========================================================
  // FORMAT WORK HOURS
  // =========================================================

  String formatWorkHours(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    double hours;

    try {
      if (value is num) {
        hours = value.toDouble();
      } else {
        hours = double.tryParse(
              value.toString(),
            ) ??
            0;
      }
    } catch (_) {
      hours = 0;
    }

    final totalMinutes =
        (hours * 60).round();

    final jam =
        totalMinutes ~/ 60;

    final menit =
        totalMinutes % 60;

    if (jam == 0) {
      return '$menit Menit';
    }

    if (menit == 0) {
      return '$jam Jam';
    }

    return '$jam Jam $menit Menit';
  }

  // =========================================================
  // SHOW MESSAGE
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
          backgroundColor: error
              ? Theme.of(context)
                  .colorScheme
                  .error
              : Colors.green.shade700,
        ),
      );
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
            size: 38,
          ),
          title: const Text(
            'Logout?',
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar '
            'dari akun administrator?',
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

    await Supabase.instance.client.auth
        .signOut();

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

    // Kalau admin kembali dari halaman pegawai,
    // refresh dashboard.
    _refreshAttendance();
  }

  // =========================================================
  // OPEN RECAP
  // =========================================================

  void _openEmployeeRecap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminEmployeeRecapPage(),
      ),
    );
  }

  // =========================================================
  // CONFIRM DELETE ATTENDANCE
  // =========================================================

  Future<void> _confirmDeleteAttendance({
    required Map<String, dynamic> item,
    required String nama,
  }) async {
    final attendanceId =
        item['id']?.toString();

    if (attendanceId == null ||
        attendanceId.isEmpty) {
      _showMessage(
        'ID data presensi tidak ditemukan.',
        error: true,
      );

      return;
    }

    if (_deletingAttendanceId != null) {
      return;
    }

    final tanggal =
        item['attendance_date']
                ?.toString() ??
            '-';

    // =======================================================
    // FIRST CONFIRMATION
    // =======================================================

    final confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        final colorScheme =
            Theme.of(dialogContext)
                .colorScheme;

        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            size: 52,
            color:
                colorScheme.error,
          ),

          title: const Text(
            'Hapus Data Presensi?',
            textAlign: TextAlign.center,
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Anda akan menghapus data presensi:',
              ),

              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color: colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize:
                            16,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Tanggal: $tanggal',
                    ),

                    Text(
                      'Masuk: '
                      '${formatLocalTime(
                        item['check_in'],
                      )}',
                    ),

                    Text(
                      'Keluar: '
                      '${formatLocalTime(
                        item['check_out'],
                      )}',
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color: colorScheme.error
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: colorScheme.error
                        .withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons
                          .report_gmailerrorred_rounded,
                      color:
                          colorScheme.error,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    const Expanded(
                      child: Text(
                        'PERINGATAN: Data yang sudah '
                        'dihapus tidak dapat dipulihkan kembali.',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    colorScheme.error,
                foregroundColor:
                    colorScheme.onError,
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
                'YA, HAPUS',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // =======================================================
    // DELETE
    // =======================================================

    setState(() {
      _deletingAttendanceId =
          attendanceId;
    });

    try {
      await adminControlService
          .deleteAttendance(
        attendanceId:
            attendanceId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Data presensi $nama berhasil dihapus.',
      );

      // Reload list setelah delete.
      await _refreshAttendance();
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
          _deletingAttendanceId =
              null;
        });
      }
    }
  }

  // =========================================================
  // BUILD ATTENDANCE CARD
  // =========================================================

  Widget _buildAttendanceCard({
    required Map<String, dynamic> item,
    required int index,
  }) {
    final profileRaw =
        item['profiles'];

    final profile =
        profileRaw is Map
            ? Map<String, dynamic>.from(
                profileRaw,
              )
            : <String, dynamic>{};

    final nama =
        profile['nama']?.toString() ??
            'Pegawai';

    final role =
        profile['role']?.toString() ??
            '-';

    final attendanceId =
        item['id']?.toString();

    final deleting =
        attendanceId != null &&
            _deletingAttendanceId ==
                attendanceId;

    return Card(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),

      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 4,
        ),

        child: ListTile(
          // =================================================
          // NUMBER
          // =================================================

          leading: CircleAvatar(
            child: Text(
              '${index + 1}',
            ),
          ),

          // =================================================
          // NAME
          // =================================================

          title: Row(
            children: [
              Expanded(
                child: Text(
                  nama,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              if (item['is_auto_checkout'] ==
                  true)
                const Tooltip(
                  message:
                      'Auto Checkout',
                  child: Icon(
                    Icons
                        .schedule_send_rounded,
                    size: 19,
                  ),
                ),
            ],
          ),

          // =================================================
          // DETAILS
          // =================================================

          subtitle: Padding(
            padding:
                const EdgeInsets.only(
              top: 6,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Role : $role',
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Tanggal : '
                  '${item['attendance_date'] ?? '-'}',
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Masuk : '
                  '${formatLocalTime(
                    item['check_in'],
                  )}',
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Keluar : '
                  '${formatLocalTime(
                    item['check_out'],
                  )}',
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Jam Kerja : '
                  '${formatWorkHours(
                    item['total_work_hours'],
                  )}',
                ),

                if (item['is_overtime'] ==
                    true) ...[
                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    'Lembur : '
                    '${formatWorkHours(
                      item['overtime_hours'],
                    )}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // =================================================
          // DELETE BUTTON
          // =================================================

          trailing: deleting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : IconButton(
                  tooltip:
                      'Hapus Presensi',
                  onPressed:
                      _deletingAttendanceId !=
                              null
                          ? null
                          : () =>
                              _confirmDeleteAttendance(
                                item: item,
                                nama: nama,
                              ),
                  icon: Icon(
                    Icons
                        .delete_outline_rounded,
                    color:
                        Theme.of(context)
                            .colorScheme
                            .error,
                  ),
                ),

          isThreeLine: true,
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
    return Scaffold(
      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title: const Text(
          'Dashboard Admin',
        ),

        actions: [
          // =================================================
          // MANAGE EMPLOYEES
          // =================================================

          IconButton(
            icon: const Icon(
              Icons.manage_accounts_rounded,
            ),
            tooltip:
                'Kelola Pegawai',
            onPressed:
                _openUserManagement,
          ),

          // =================================================
          // EMPLOYEE RECAP
          // =================================================

          IconButton(
            icon: const Icon(
              Icons.analytics_outlined,
            ),
            tooltip:
                'Rekap Pegawai',
            onPressed:
                _openEmployeeRecap,
          ),

          // =================================================
          // REFRESH
          // =================================================

          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            tooltip:
                'Refresh',
            onPressed: () {
              _refreshAttendance();
            },
          ),

          // =================================================
          // LOGOUT
          // =================================================

          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
            ),
            tooltip:
                'Logout',
            onPressed:
                _logout,
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // CURRENT ADMIN PROFILE
            // =================================================

            const Padding(
              padding:
                  EdgeInsets.fromLTRB(
                16,
                16,
                16,
                8,
              ),
              child:
                  CurrentUserHeader(),
            ),

            // =================================================
            // HEADER
            // =================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .fact_check_outlined,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      'Data Presensi Pegawai',
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                    ),
                  ),

                  FilledButton.icon(
                    onPressed:
                        _openUserManagement,
                    icon: const Icon(
                      Icons
                          .person_add_alt_1_rounded,
                    ),
                    label: const Text(
                      'Kelola Pegawai',
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // ATTENDANCE DATA
            // =================================================

            Expanded(
              child: RefreshIndicator(
                onRefresh:
                    _refreshAttendance,

                child: FutureBuilder<
                    List<
                        Map<String,
                            dynamic>>>(
                  future:
                      _attendanceFuture,

                  builder: (
                    context,
                    snapshot,
                  ) {
                    // =========================================
                    // LOADING
                    // =========================================

                    if (snapshot.connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    // =========================================
                    // ERROR
                    // =========================================

                    if (snapshot.hasError) {
                      return ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.sizeOf(
                                      context,
                                    ).height *
                                    0.45,
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(
                                  24,
                                ),
                                child: Column(
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,
                                  children: [
                                    Icon(
                                      Icons
                                          .error_outline_rounded,
                                      size: 48,
                                      color:
                                          Theme.of(
                                        context,
                                      )
                                              .colorScheme
                                              .error,
                                    ),

                                    const SizedBox(
                                      height:
                                          12,
                                    ),

                                    Text(
                                      'Gagal memuat data presensi.\n\n'
                                      '${snapshot.error}',
                                      textAlign:
                                          TextAlign.center,
                                    ),

                                    const SizedBox(
                                      height:
                                          16,
                                    ),

                                    FilledButton.icon(
                                      onPressed:
                                          () {
                                        _refreshAttendance();
                                      },
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
                          ),
                        ],
                      );
                    }

                    // =========================================
                    // DATA
                    // =========================================

                    final data =
                        snapshot.data ??
                            [];

                    if (data.isEmpty) {
                      return ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  Icon(
                                    Icons
                                        .inbox_outlined,
                                    size: 48,
                                  ),

                                  SizedBox(
                                    height:
                                        12,
                                  ),

                                  Text(
                                    'Belum ada data presensi',
                                  ),

                                  SizedBox(
                                    height:
                                        5,
                                  ),

                                  Text(
                                    'Tarik ke bawah untuk memperbarui.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // =========================================
                    // LIST
                    // =========================================

                    return ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),

                      padding:
                          const EdgeInsets.only(
                        bottom: 24,
                      ),

                      itemCount:
                          data.length,

                      itemBuilder: (
                        context,
                        index,
                      ) {
                        return _buildAttendanceCard(
                          item:
                              data[index],
                          index:
                              index,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}