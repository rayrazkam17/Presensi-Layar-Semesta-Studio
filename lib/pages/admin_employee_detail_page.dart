import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/attendance_service.dart';

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
  final AttendanceService attendanceService = AttendanceService();

  late Future<List<Map<String, dynamic>>> attendanceFuture;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() {
    attendanceFuture = attendanceService.getEmployeeAttendance(
      userId: widget.userId,
      month: widget.month,
      year: widget.year,
    );
  }

  void refreshData() {
    setState(() {
      _loadAttendance();
    });
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString());

      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return '-';
    }
  }

  String formatTime(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      return DateFormat('HH:mm', 'id_ID').format(date);
    } catch (_) {
      return '-';
    }
  }

  double toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  String formatWorkDuration(dynamic value) {
    final totalHours = toDouble(value);
    final totalMinutes = (totalHours * 60).round();

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0 && minutes == 0) {
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

  Future<String?> getPhotoSignedUrl(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) {
      return null;
    }

    try {
      return await Supabase.instance.client.storage
          .from('attendance-photos')
          .createSignedUrl(
            photoPath,
            60 * 10,
          );
    } catch (e) {
      debugPrint('Gagal membuat signed URL: $e');
      return null;
    }
  }

  void showAttendancePhotoDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final checkInPhoto = item['check_in_photo']?.toString();
    final checkOutPhoto = item['check_out_photo']?.toString();

    final isAutoCheckout =
        item['is_auto_checkout'] == true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bukti Foto Presensi'),
          content: SizedBox(
            width: 420,
            child: FutureBuilder<List<String?>>(
              future: Future.wait([
                getPhotoSignedUrl(checkInPhoto),
                getPhotoSignedUrl(checkOutPhoto),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Gagal memuat bukti foto:\n${snapshot.error}',
                  );
                }

                final urls = snapshot.data ?? [null, null];

                final checkInUrl = urls[0];
                final checkOutUrl = urls[1];

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Foto Check-in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (checkInUrl != null)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: Image.network(
                            checkInUrl,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              _,
                              error,
                              stackTrace,
                            ) {
                              debugPrint(
                                'Gagal load foto check-in: $error',
                              );

                              return const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Foto check-in tidak dapat dimuat',
                                ),
                              );
                            },
                          ),
                        )
                      else
                        const Text(
                          'Foto check-in belum tersedia',
                        ),

                      const SizedBox(height: 20),

                      const Text(
                        'Foto Check-out',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (checkOutUrl != null)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: Image.network(
                            checkOutUrl,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              _,
                              error,
                              stackTrace,
                            ) {
                              debugPrint(
                                'Gagal load foto check-out: $error',
                              );

                              return const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Foto check-out tidak dapat dimuat',
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Text(
                          isAutoCheckout
                              ? 'Tidak ada foto keluar karena '
                                  'sistem melakukan auto checkout.'
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAttendanceCard(
    Map<String, dynamic> item,
  ) {
    final isOvertime = item['is_overtime'] == true;

    final isAutoCheckout =
        item['is_auto_checkout'] == true;

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
        hasCheckInPhoto || hasCheckOutPhoto;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              formatDate(item['attendance_date']),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const Divider(height: 24),

            _buildInfoRow(
              'Masuk',
              formatTime(item['check_in']),
            ),

            _buildInfoRow(
              'Keluar',
              formatTime(item['check_out']),
            ),

            _buildInfoRow(
              'Durasi',
              formatWorkDuration(
                item['total_work_hours'],
              ),
            ),

            _buildInfoRow(
              'Lembur',
              isOvertime ? 'Ya' : 'Tidak',
            ),

            _buildInfoRow(
              'Status',
              isAutoCheckout
                  ? 'Auto Checkout'
                  : 'Checkout Manual',
              valueColor: isAutoCheckout
                  ? Colors.orange
                  : Colors.green,
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: hasAnyPhoto
                  ? TextButton.icon(
                      icon: const Icon(
                        Icons.photo_outlined,
                      ),
                      label: const Text('Lihat Bukti'),
                      onPressed: () {
                        showAttendancePhotoDialog(
                          context,
                          item,
                        );
                      },
                    )
                  : Text(
                      isAutoCheckout
                          ? 'Tidak ada foto keluar'
                          : '-',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTable(
    List<Map<String, dynamic>> records,
  ) {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Tanggal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Masuk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Keluar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Durasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Lembur',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Bukti',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          ...records.map((item) {
            final isOvertime =
                item['is_overtime'] == true;

            final isAutoCheckout =
                item['is_auto_checkout'] == true;

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
                hasCheckInPhoto || hasCheckOutPhoto;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      formatDate(item['attendance_date']),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      formatTime(item['check_in']),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      formatTime(item['check_out']),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: Text(
                      formatWorkDuration(
                        item['total_work_hours'],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      isOvertime ? 'Ya' : 'Tidak',
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      isAutoCheckout ? 'Auto' : 'Manual',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isAutoCheckout
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: hasAnyPhoto
                        ? TextButton(
                            onPressed: () {
                              showAttendancePhotoDialog(
                                context,
                                item,
                              );
                            },
                            child: const Text('Lihat'),
                          )
                        : Text(
                            isAutoCheckout
                                ? 'Tidak ada foto keluar'
                                : '-',
                            textAlign: TextAlign.center,
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periode = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(
      DateTime(widget.year, widget.month),
    ).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Presensi Pegawai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat detail:\n${snapshot.error}',
                ),
              ),
            );
          }

          final records = snapshot.data ?? [];

          final totalHadir = records.length;

          final totalLembur = records.where(
            (item) => item['is_overtime'] == true,
          ).length;

          final totalJamKerja = records.fold<double>(
            0,
            (sum, item) =>
                sum + toDouble(item['total_work_hours']),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile =
                  constraints.maxWidth < 700;

              final padding = isMobile ? 12.0 : 16.0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nama,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Role: ${widget.role}'),
                            Text('Periode: $periode'),
                            const SizedBox(height: 16),
                            Text(
                              'Total Hadir: $totalHadir Hari',
                            ),
                            Text(
                              'Total Lembur: $totalLembur Hari',
                            ),
                            Text(
                              'Total Jam Kerja: '
                              '${formatWorkDuration(totalJamKerja)}',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'RIWAYAT PRESENSI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (records.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'Belum ada riwayat presensi '
                            'pada periode ini',
                          ),
                        ),
                      )
                    else if (isMobile)
                      Column(
                        children: records
                            .map(
                              (item) =>
                                  _buildMobileAttendanceCard(
                                item,
                              ),
                            )
                            .toList(),
                      )
                    else
                      _buildAttendanceTable(records),
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