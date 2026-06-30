import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'attendance_page.dart';
import 'my_attendance_page.dart';

class DashboardUserPage extends StatelessWidget {
  const DashboardUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard User'),
        actions: [
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Dashboard User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // Tombol Absen
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('ABSEN SEKARANG'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendancePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // Tombol Riwayat Presensi
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text(
                'RIWAYAT PRESENSI',
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyAttendancePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}