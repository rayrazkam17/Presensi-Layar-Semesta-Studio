import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/attendance_service.dart';

class MyAttendancePage extends StatefulWidget {
  const MyAttendancePage({super.key});

  @override
  State<MyAttendancePage> createState() =>
      _MyAttendancePageState();
}

class _MyAttendancePageState extends State<MyAttendancePage> {
  final attendanceService = AttendanceService();

  Map<String, List<Map<String, dynamic>>> groupByMonth(
    List<Map<String, dynamic>> data,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in data) {
      final date = DateTime.parse(
        item['attendance_date'].toString(),
      );

      final key = DateFormat(
        'MMMM yyyy',
        'id_ID',
      ).format(date);

      grouped.putIfAbsent(
        key,
        () => [],
      );

      grouped[key]!.add(item);
    }

    return grouped;
  }

  double toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String formatWorkHours(dynamic value) {
    final hours = toDouble(value);
    final totalMinutes = (hours * 60).round();

    final jam = totalMinutes ~/ 60;
    final menit = totalMinutes % 60;

    if (jam == 0 && menit == 0) {
      return '-';
    }

    if (jam == 0) {
      return '$menit Menit';
    }

    if (menit == 0) {
      return '$jam Jam';
    }

    return '$jam Jam $menit Menit';
  }

  String formatTime(dynamic value) {
    if (value == null) return '-';

    try {
      return DateFormat(
        'HH:mm',
        'id_ID',
      ).format(
        DateTime.parse(
          value.toString(),
        ).toLocal(),
      );
    } catch (_) {
      return '-';
    }
  }

  Widget buildStatusText(
    Map<String, dynamic> item,
  ) {
    final hasCheckOut = item['check_out'] != null;

    if (!hasCheckOut) {
      return const Text(
        'Belum checkout',
        style: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final isAutoCheckout =
        item['is_auto_checkout'] == true;

    return Text(
      isAutoCheckout
          ? 'Auto Checkout'
          : 'Checkout manual',
      style: TextStyle(
        color: isAutoCheckout
            ? Colors.orange
            : Colors.green,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget buildMobileAttendanceCard(
    Map<String, dynamic> item,
  ) {
    final date = DateTime.parse(
      item['attendance_date'].toString(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat(
                'dd MMMM yyyy',
                'id_ID',
              ).format(date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const Divider(height: 24),

            Text(
              'Masuk   : ${formatTime(item['check_in'])}',
            ),

            Text(
              'Keluar  : ${formatTime(item['check_out'])}',
            ),

            Text(
              'Durasi  : ${formatWorkHours(item['total_work_hours'])}',
            ),

            Text(
              'Lembur  : ${item['is_overtime'] == true ? 'Ya' : 'Tidak'}',
            ),

            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 70,
                  child: Text('Status :'),
                ),
                Expanded(
                  child: buildStatusText(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDesktopAttendanceTable(
    List<Map<String, dynamic>> records,
    double availableWidth,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: availableWidth,
        ),
        child: Table(
          border: TableBorder.all(
            color: Colors.grey.shade300,
          ),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(3),
            4: FlexColumnWidth(2),
            5: FlexColumnWidth(4),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(
                color: Color(0xFFEFEFEF),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Tanggal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Masuk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Keluar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Durasi Kerja',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Lembur',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            ...records.map((item) {
              final date = DateTime.parse(
                item['attendance_date'].toString(),
              );

              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      DateFormat(
                        'dd MMM yyyy',
                        'id_ID',
                      ).format(date),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      formatTime(item['check_in']),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      formatTime(item['check_out']),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      formatWorkHours(
                        item['total_work_hours'],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      item['is_overtime'] == true
                          ? 'Ya'
                          : 'Tidak',
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: buildStatusText(item),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Presensi',
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: attendanceService.getMyAttendance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data presensi',
              ),
            );
          }

          final attendanceList = snapshot.data!;
          final grouped = groupByMonth(attendanceList);

          return ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: grouped.entries.map((entry) {
              final records = entry.value;

              final totalAttendance = records.length;

              final totalOvertimeDays = records.where(
                (item) => item['is_overtime'] == true,
              ).length;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Total Hadir : $totalAttendance Hari',
                      ),

                      Text(
                        'Total Lembur : $totalOvertimeDays Hari',
                      ),

                      const SizedBox(height: 20),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile =
                              constraints.maxWidth < 700;

                          if (isMobile) {
                            return Column(
                              children: records.map((item) {
                                return buildMobileAttendanceCard(
                                  item,
                                );
                              }).toList(),
                            );
                          }

                          return buildDesktopAttendanceTable(
                            records,
                            constraints.maxWidth,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}