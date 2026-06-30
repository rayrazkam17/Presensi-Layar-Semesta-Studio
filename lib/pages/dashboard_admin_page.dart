import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/attendance_service.dart';
import 'login_page.dart';
import 'admin_employee_recap_page.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() =>
      _DashboardAdminPageState();
}

class _DashboardAdminPageState
    extends State<DashboardAdminPage> {

  final attendanceService = AttendanceService();

  String formatLocalTime(dynamic value) {
    if (value == null) return '-';

    final dateTime = DateTime.parse(
      value.toString(),
    ).toLocal();

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String formatWorkHours(dynamic value) {
    final hours = ((value ?? 0) as num).toDouble();

    final totalMinutes = (hours * 60).round();

    final jam = totalMinutes ~/ 60;
    final menit = totalMinutes % 60;

    if (jam == 0) {
      return '$menit Menit';
    }

    if (menit == 0) {
      return '$jam Jam';
    }

    return '$jam Jam $menit Menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),

        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Rekap Pegawai',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminEmployeeRecapPage(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: attendanceService.getAllAttendance(),
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
                'Error:\n${snapshot.error}',
              ),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data presensi',
              ),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {

              final item = data[index];

              final profile =
                  item['profiles'] as Map<String, dynamic>?;

              final nama =
                  profile?['nama']?.toString() ?? 'Pegawai';

              final role =
                  profile?['role']?.toString() ?? '-'; 

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(

                  leading: CircleAvatar(
                    child: Text(
                      '${index + 1}',
                    ),
                  ),

                  title: Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role : $role'),

                      Text(
                        'Tanggal : ${item['attendance_date'] ?? '-'}',
                      ),

                      Text(
                        'Masuk : ${formatLocalTime(item['check_in'])}',
                      ),

                      Text(
                        'Keluar : ${formatLocalTime(item['check_out'])}',
                      ),

                      Text(
                        'Jam Kerja : ${formatWorkHours(item['total_work_hours'])}',
                      ),
                    ],
                  ),

                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}