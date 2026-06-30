import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/camera_capture_widget.dart';
import '../services/storage_service.dart';
import '../services/attendance_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {

  Uint8List? approvedImage;

  final storageService = StorageService();
  final attendanceService = AttendanceService();

  Future<void> checkIn() async {

    if (approvedImage == null) return;

    try {

      final alreadyCheckIn =
          await attendanceService.hasCheckedInToday();

      if (alreadyCheckIn) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Anda sudah absen masuk hari ini',
            ),
          ),
        );

        return;
      }

      final user =
          Supabase.instance.client.auth.currentUser!;

      final now = DateTime.now();

      final filePath =
          '${now.year}/${now.month.toString().padLeft(2,'0')}/${user.id}/checkin_${now.millisecondsSinceEpoch}.jpg';

      final uploadedPath =
          await storageService.uploadAttendancePhoto(
        bytes: approvedImage!,
        fileName: filePath,
      );

      await attendanceService.checkIn(
        photoPath: uploadedPath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Absen masuk berhasil',
          ),
        ),
      );

    } catch (e) {

      print(e);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal: $e',
          ),
        ),
      );
    }
  }

  Future<void> checkOut() async {

    if (approvedImage == null) return;

    try {

      final alreadyCheckOut =
          await attendanceService
              .hasCheckedOutToday();

      if (alreadyCheckOut) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Anda sudah absen keluar hari ini',
            ),
          ),
        );

        return;
      }

      final user =
          Supabase.instance.client.auth.currentUser!;

      final now = DateTime.now();

      final filePath =
          '${now.year}/${now.month.toString().padLeft(2,'0')}/${user.id}/checkout_${now.millisecondsSinceEpoch}.jpg';

      final uploadedPath =
          await storageService.uploadAttendancePhoto(
        bytes: approvedImage!,
        fileName: filePath,
      );

      await attendanceService.checkOut(
        photoPath: uploadedPath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Absen keluar berhasil',
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Absensi"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            CameraCaptureWidget(
              onImageCaptured: (imageBytes) {

                setState(() {
                  approvedImage = imageBytes;
                });

                print(
                  'Foto diterima: ${imageBytes.length} bytes',
                );
              },

              onImageReset: () {

                setState(() {
                  approvedImage = null;
                });

              },
            ),

            if (approvedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Foto siap diproses (${approvedImage!.length} bytes)',
                ),
              ),

            if (approvedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('ABSEN MASUK'),
                  onPressed: checkIn,
                ),
              ),

            if (approvedImage != null)
              const SizedBox(height: 10),

            if (approvedImage != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('ABSEN KELUAR'),
                onPressed: checkOut,
              ),
          ],
        ),
      ),
    );
  }
}