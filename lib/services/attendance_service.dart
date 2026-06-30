import 'package:supabase_flutter/supabase_flutter.dart';
import 'whatsapp_service.dart';
import 'storage_service.dart';

final whatsappService = WhatsAppService();
final storageService = StorageService();

class AttendanceService {
  final supabase = Supabase.instance.client;

  /// Menghasilkan tanggal hari ini berdasarkan WIB.
  ///
  /// Database tetap menyimpan waktu UTC, tetapi attendance_date
  /// harus mengikuti kalender kerja Indonesia WIB.
  String getTodayWibDate() {
    final nowWib = DateTime.now().toUtc().add(
          const Duration(hours: 7),
        );

    return DateTime(
      nowWib.year,
      nowWib.month,
      nowWib.day,
    ).toIso8601String().split('T')[0];
  }

  Future<bool> hasCheckedInToday() async {
    final user = supabase.auth.currentUser!;

    final today = getTodayWibDate();

    final result = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id)
        .eq('attendance_date', today);

    return result.isNotEmpty;
  }

  Future<void> checkIn({
  required String photoPath,
}) async {
  final user = supabase.auth.currentUser!;

  // Ambil profil user yang sedang login
  final profile = await supabase
      .from('profiles')
      .select('nama, role')
      .eq('id', user.id)
      .single();

  final nama = profile['nama']?.toString() ?? 'Pegawai';
  final role = profile['role']?.toString() ?? '-';

  // Waktu presensi disimpan sebagai UTC
  final nowUtc = DateTime.now().toUtc();

  // Tanggal presensi mengikuti WIB
  final todayWib = getTodayWibDate();

  await supabase.from('attendance').insert({
    'user_id': user.id,
    'attendance_date': todayWib,
    'check_in': nowUtc.toIso8601String(),
    'check_in_photo': photoPath,
    'is_auto_checkout': false,
  });

  final photoUrl = storageService.getPhotoUrl(photoPath);

  try {
    await whatsappService.send({
      "type": "checkin",
      "nama": nama,
      "checkIn": nowUtc.toIso8601String(),
      "photoUrl": photoUrl,
    });

    print("WhatsApp check-in berhasil dikirim");
  } catch (e) {
    print("Gagal mengirim WhatsApp check-in: $e");
  }
}

  Future<bool> hasCheckedOutToday() async {
    final user = supabase.auth.currentUser!;

    final today = getTodayWibDate();

    final result = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id)
        .eq('attendance_date', today)
        .not('check_out', 'is', null);

    return result.isNotEmpty;
  }

  Future<void> checkOut({
    required String photoPath,
  }) async {
    final user = supabase.auth.currentUser!;

    final today = getTodayWibDate();

    final attendance = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id)
        .eq('attendance_date', today)
        .single();

    final checkInUtc = DateTime.parse(
      attendance['check_in'].toString(),
    ).toUtc();

    final nowUtc = DateTime.now().toUtc();

    final duration = nowUtc.difference(checkInUtc);

    final totalWorkHours = double.parse(
      (duration.inMinutes / 60).toStringAsFixed(2),
    );

    final overtimeHours = totalWorkHours > 12
        ? double.parse(
            (totalWorkHours - 12).toStringAsFixed(2),
          )
        : 0.0;

    final isOvertime = totalWorkHours > 12;

    print('CHECK IN : $checkInUtc UTC');
    print('CHECK OUT: $nowUtc UTC');
    print('DURATION : ${duration.inMinutes} Minutes');
    print('TOTAL    : $totalWorkHours Hours');

    await supabase
        .from('attendance')
        .update({
          'check_out': nowUtc.toIso8601String(),
          'check_out_photo': photoPath,
          'total_work_hours': totalWorkHours,
          'overtime_hours': overtimeHours,
          'is_overtime': isOvertime,
          'is_auto_checkout': false,
        })
        .eq('id', attendance['id']);
  
  final photoUrl = storageService.getPhotoUrl(photoPath);

  try {
    final profile = await supabase
        .from('profiles')
        .select('nama')
        .eq('id', user.id)
        .single();

    await whatsappService.send({
      "type": "checkout",
      "nama": profile['nama'],
      "checkIn": attendance['check_in'],
      "checkOut": nowUtc.toIso8601String(),
      "totalWorkHours": totalWorkHours,
      "overtimeHours": overtimeHours,
      "photoUrl": photoUrl,
    });

    print("WhatsApp checkout berhasil dikirim");
  } catch (e) {
    print("Gagal mengirim WhatsApp checkout: $e");
  }
}

  /// Menutup presensi kemarin yang belum checkout.
  ///
  /// Mekanisme:
  /// - Mencari attendance_date kemarin berdasarkan WIB.
  /// - Jika check_out masih null, sistem mengisi checkout 23:59:59 WIB.
  /// - Waktu checkout dikonversi ke UTC sebelum disimpan ke Supabase.
  /// - Auto checkout tidak dianggap lembur.
  Future<void> autoCheckOutYesterdayAttendance() async {
    final nowWib = DateTime.now().toUtc().add(
          const Duration(hours: 7),
        );

    final yesterdayWib = DateTime(
      nowWib.year,
      nowWib.month,
      nowWib.day,
    ).subtract(
      const Duration(days: 1),
    );

    final yesterdayDate = yesterdayWib
        .toIso8601String()
        .split('T')[0];

    final unfinishedAttendance = await supabase
        .from('attendance')
        .select()
        .eq('attendance_date', yesterdayDate)
        .isFilter('check_out', null);

    for (final row in unfinishedAttendance) {
      final item = Map<String, dynamic>.from(row);

      // 23:59:59 WIB pada tanggal presensi kemarin.
      final autoCheckoutWib = DateTime(
        yesterdayWib.year,
        yesterdayWib.month,
        yesterdayWib.day,
        23,
        59,
        59,
      );

      // WIB UTC+7, sehingga dikurangi 7 jam sebelum disimpan.
      final autoCheckoutUtc = autoCheckoutWib.subtract(
        const Duration(hours: 7),
      );

      final checkInUtc = DateTime.parse(
        item['check_in'].toString(),
      ).toUtc();

      final duration = autoCheckoutUtc.difference(checkInUtc);

      // Pengaman apabila ada data check-in yang tidak valid.
      final safeDurationMinutes =
          duration.isNegative ? 0 : duration.inMinutes;

      final totalWorkHours = double.parse(
        (safeDurationMinutes / 60).toStringAsFixed(2),
      );

      await supabase
          .from('attendance')
          .update({
            'check_out': autoCheckoutUtc.toIso8601String(),
            'check_out_photo': null,
            'total_work_hours': totalWorkHours,
            'overtime_hours': 0.0,
            'is_overtime': false,
            'is_auto_checkout': true,
          })
          .eq('id', item['id']);

      try {
  final profile = await supabase
      .from('profiles')
      .select('nama')
      .eq('id', item['user_id'])
      .single();

  await whatsappService.send({
      "type": "auto_checkout",
      "nama": profile['nama'],
      "tanggal": yesterdayDate,
    });

    print(
      "WhatsApp auto checkout berhasil dikirim",
    );
  } catch (e) {
    print(
      "Gagal mengirim WhatsApp auto checkout: $e",
    );
  }

      print(
        'AUTO CHECKOUT 23:59 WIB: ${item['user_id']}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMyAttendance() async {
    final user = supabase.auth.currentUser!;

    final result = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id)
        .order(
          'attendance_date',
          ascending: false,
        );

    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final result = await supabase
        .from('attendance')
        .select('''
          id,
          user_id,
          attendance_date,
          check_in,
          check_out,
          check_in_photo,
          check_out_photo,
          total_work_hours,
          overtime_hours,
          is_overtime,
          is_auto_checkout,
          profiles (
            nama,
            role
          )
        ''')
        .order(
          'attendance_date',
          ascending: false,
        );

    return List<Map<String, dynamic>>.from(result);
  }

  /// Mengambil rekap semua pegawai berdasarkan bulan dan tahun pilihan admin.
  Future<List<Map<String, dynamic>>> getMonthlyEmployeeRecap({
    required int month,
    required int year,
  }) async {
    final startDate = DateTime.utc(year, month, 1);
    final endDate = DateTime.utc(year, month + 1, 1);

    final result = await supabase
        .from('attendance')
        .select('''
          user_id,
          attendance_date,
          is_overtime,
          is_auto_checkout,
          profiles (
            nama,
            role
          )
        ''')
        .gte(
          'attendance_date',
          startDate.toIso8601String().split('T')[0],
        )
        .lt(
          'attendance_date',
          endDate.toIso8601String().split('T')[0],
        );

    final Map<String, Map<String, dynamic>> recap = {};

    for (final row in result) {
      final item = Map<String, dynamic>.from(row);

      final userId = item['user_id'].toString();

      final profileRaw = item['profiles'];

      final profile = profileRaw is Map
          ? Map<String, dynamic>.from(profileRaw)
          : <String, dynamic>{};

      final nama = profile['nama']?.toString() ?? 'Pegawai';
      final role = profile['role']?.toString() ?? '-';

      if (!recap.containsKey(userId)) {
        recap[userId] = {
          'user_id': userId,
          'nama': nama,
          'role': role,
          'hadir': 0,
          'lembur': 0,
        };
      }

      recap[userId]!['hadir'] =
          (recap[userId]!['hadir'] as int) + 1;

      if (item['is_overtime'] == true) {
        recap[userId]!['lembur'] =
            (recap[userId]!['lembur'] as int) + 1;
      }
    }

    final recapList = recap.values.toList();

    recapList.sort((a, b) {
      return a['nama']
          .toString()
          .compareTo(b['nama'].toString());
    });

    return recapList;
  }

  /// Mengambil detail presensi satu pegawai berdasarkan bulan dan tahun.
  Future<List<Map<String, dynamic>>> getEmployeeAttendance({
    required String userId,
    required int month,
    required int year,
  }) async {
    final startDate = DateTime.utc(year, month, 1);
    final endDate = DateTime.utc(year, month + 1, 1);

    final result = await supabase
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .gte(
          'attendance_date',
          startDate.toIso8601String().split('T')[0],
        )
        .lt(
          'attendance_date',
          endDate.toIso8601String().split('T')[0],
        )
        .order(
          'attendance_date',
          ascending: false,
        );

    return List<Map<String, dynamic>>.from(result);
  }

  /// Mengambil seluruh attendance pada bulan/tahun tertentu.
  Future<List<Map<String, dynamic>>> getAttendanceByMonth({
    required int month,
    required int year,
  }) async {
    final startDate = DateTime.utc(year, month, 1);
    final endDate = DateTime.utc(year, month + 1, 1);

    final result = await supabase
        .from('attendance')
        .select('''
          user_id,
          attendance_date,
          total_work_hours,
          overtime_hours,
          is_overtime,
          is_auto_checkout,
          profiles (
            nama,
            role
          )
        ''')
        .gte(
          'attendance_date',
          startDate.toIso8601String().split('T')[0],
        )
        .lt(
          'attendance_date',
          endDate.toIso8601String().split('T')[0],
        )
        .order(
          'attendance_date',
          ascending: false,
        );

    return List<Map<String, dynamic>>.from(result);
  }
}