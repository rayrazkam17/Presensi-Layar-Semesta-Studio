import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_service.dart';
import 'whatsapp_service.dart';

class AttendanceService {
  final SupabaseClient supabase = Supabase.instance.client;

  final WhatsAppService whatsappService = WhatsAppService();
  final StorageService storageService = StorageService();

  // =========================================================
  // USER
  // =========================================================

  User _requireUser() {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    return user;
  }

  // =========================================================
  // WIB DATE
  // =========================================================

  /// Menghasilkan tanggal hari ini berdasarkan WIB.
  ///
  /// Contoh:
  /// 2026-08-23
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

  // =========================================================
  // CHECK STATUS
  // =========================================================

  Future<bool> hasCheckedInToday() async {
    final user = _requireUser();

    final today = getTodayWibDate();

    final result = await supabase
        .from('attendance')
        .select('id')
        .eq('user_id', user.id)
        .eq('attendance_date', today);

    return result.isNotEmpty;
  }

  Future<bool> hasCheckedOutToday() async {
    final user = _requireUser();

    final today = getTodayWibDate();

    final result = await supabase
        .from('attendance')
        .select('id')
        .eq('user_id', user.id)
        .eq('attendance_date', today)
        .not(
          'check_out',
          'is',
          null,
        );

    return result.isNotEmpty;
  }

  // =========================================================
  // CHECK IN
  // =========================================================

  Future<void> checkIn({
    required String photoPath,
  }) async {
    final user = _requireUser();

    final profile = await supabase
        .from('profiles')
        .select('nama')
        .eq('id', user.id)
        .single();

    final nama =
        profile['nama']?.toString() ?? 'Pegawai';

    final nowUtc = DateTime.now().toUtc();

    final todayWib = getTodayWibDate();

    await supabase.from('attendance').insert({
      'user_id': user.id,
      'attendance_date': todayWib,
      'check_in': nowUtc.toIso8601String(),
      'check_in_photo': photoPath,
      'is_auto_checkout': false,
    });

    // Untuk sementara tetap menggunakan URL yang sudah
    // digunakan project lama.
    // Private signed URL akan kita benahi di Tahap 2.
    final photoUrl =
        storageService.getPhotoUrl(photoPath);

    try {
      await whatsappService.send({
        'type': 'checkin',
        'nama': nama,
        'checkIn': nowUtc.toIso8601String(),
        'photoUrl': photoUrl,
      });

      debugPrint(
        'WhatsApp check-in berhasil dikirim',
      );
    } catch (e) {
      // Absensi tetap dianggap berhasil walaupun
      // notifikasi WhatsApp gagal.
      debugPrint(
        'Gagal mengirim WhatsApp check-in: $e',
      );
    }
  }

  // =========================================================
  // CHECK OUT
  // =========================================================

  Future<void> checkOut({
    required String photoPath,
  }) async {
    final user = _requireUser();

    final today = getTodayWibDate();

    final attendance = await supabase
        .from('attendance')
        .select()
        .eq('user_id', user.id)
        .eq('attendance_date', today)
        .single();

    final checkInRaw =
        attendance['check_in'];

    if (checkInRaw == null) {
      throw Exception(
        'Data check-in tidak ditemukan.',
      );
    }

    final checkInUtc = DateTime.parse(
      checkInRaw.toString(),
    ).toUtc();

    final nowUtc = DateTime.now().toUtc();

    final duration =
        nowUtc.difference(checkInUtc);

    final safeMinutes =
        duration.isNegative
            ? 0
            : duration.inMinutes;

    final totalWorkHours =
        double.parse(
      (safeMinutes / 60)
          .toStringAsFixed(2),
    );

    // Untuk sementara mengikuti logika project lama:
    // lembur jika total kerja > 12 jam.
    //
    // Pada tahap fitur shift nanti akan kita buat
    // berdasarkan jadwal kerja.
    final overtimeHours =
        totalWorkHours > 12
            ? double.parse(
                (totalWorkHours - 12)
                    .toStringAsFixed(2),
              )
            : 0.0;

    final isOvertime =
        totalWorkHours > 12;

    await supabase
        .from('attendance')
        .update({
          'check_out':
              nowUtc.toIso8601String(),
          'check_out_photo':
              photoPath,
          'total_work_hours':
              totalWorkHours,
          'overtime_hours':
              overtimeHours,
          'is_overtime':
              isOvertime,
          'is_auto_checkout':
              false,
        })
        .eq(
          'id',
          attendance['id'],
        );

    final photoUrl =
        storageService.getPhotoUrl(photoPath);

    try {
      final profile = await supabase
          .from('profiles')
          .select('nama')
          .eq('id', user.id)
          .single();

      final nama =
          profile['nama']?.toString() ??
              'Pegawai';

      await whatsappService.send({
        'type': 'checkout',
        'nama': nama,
        'checkIn': attendance['check_in'],
        'checkOut':
            nowUtc.toIso8601String(),
        'totalWorkHours':
            totalWorkHours,
        'overtimeHours':
            overtimeHours,
        'photoUrl': photoUrl,
      });

      debugPrint(
        'WhatsApp checkout berhasil dikirim',
      );
    } catch (e) {
      debugPrint(
        'Gagal mengirim WhatsApp checkout: $e',
      );
    }
  }

  // =========================================================
  // AUTO CHECKOUT
  // =========================================================

  /// Menutup presensi kemarin yang belum checkout.
  ///
  /// CATATAN:
  /// Fungsi ini masih mengikuti mekanisme project lama.
  /// Pada Tahap 3 nanti dipindahkan ke Supabase Cron supaya
  /// tidak bergantung pada aplikasi yang sedang dibuka.
  Future<void>
      autoCheckOutYesterdayAttendance() async {
    final nowWib =
        DateTime.now().toUtc().add(
              const Duration(hours: 7),
            );

    final yesterdayWib = DateTime(
      nowWib.year,
      nowWib.month,
      nowWib.day,
    ).subtract(
      const Duration(days: 1),
    );

    final yesterdayDate =
        yesterdayWib
            .toIso8601String()
            .split('T')[0];

    final unfinishedAttendance =
        await supabase
            .from('attendance')
            .select()
            .eq(
              'attendance_date',
              yesterdayDate,
            )
            .isFilter(
              'check_out',
              null,
            );

    for (final row
        in unfinishedAttendance) {
      final item =
          Map<String, dynamic>.from(row);

      // 23:59:59 WIB.
      final autoCheckoutWib =
          DateTime(
        yesterdayWib.year,
        yesterdayWib.month,
        yesterdayWib.day,
        23,
        59,
        59,
      );

      // Konversi WIB ke UTC.
      final autoCheckoutUtc =
          autoCheckoutWib.subtract(
        const Duration(hours: 7),
      );

      final checkInRaw =
          item['check_in'];

      if (checkInRaw == null) {
        continue;
      }

      final checkInUtc =
          DateTime.parse(
        checkInRaw.toString(),
      ).toUtc();

      final duration =
          autoCheckoutUtc.difference(
        checkInUtc,
      );

      final safeDurationMinutes =
          duration.isNegative
              ? 0
              : duration.inMinutes;

      final totalWorkHours =
          double.parse(
        (safeDurationMinutes / 60)
            .toStringAsFixed(2),
      );

      await supabase
          .from('attendance')
          .update({
            'check_out':
                autoCheckoutUtc
                    .toIso8601String(),
            'check_out_photo':
                null,
            'total_work_hours':
                totalWorkHours,
            'overtime_hours':
                0.0,
            'is_overtime':
                false,
            'is_auto_checkout':
                true,
          })
          .eq(
            'id',
            item['id'],
          );

      // ===============================================
      // WHATSAPP
      // ===============================================

      try {
        final profile =
            await supabase
                .from('profiles')
                .select('nama')
                .eq(
                  'id',
                  item['user_id'],
                )
                .single();

        final nama =
            profile['nama']
                    ?.toString() ??
                'Pegawai';

        await whatsappService.send({
          'type':
              'auto_checkout',
          'nama':
              nama,
          'tanggal':
              yesterdayDate,
        });

        debugPrint(
          'WhatsApp auto checkout '
          'berhasil dikirim',
        );
      } catch (e) {
        debugPrint(
          'Gagal mengirim WhatsApp '
          'auto checkout: $e',
        );
      }
    }
  }

  // =========================================================
  // MY ATTENDANCE
  // =========================================================

  Future<List<Map<String, dynamic>>>
      getMyAttendance() async {
    final user = _requireUser();

    final result = await supabase
        .from('attendance')
        .select()
        .eq(
          'user_id',
          user.id,
        )
        .order(
          'attendance_date',
          ascending: false,
        );

    return List<Map<String, dynamic>>.from(
      result,
    );
  }

  // =========================================================
  // ALL ATTENDANCE
  // =========================================================

  Future<List<Map<String, dynamic>>>
      getAllAttendance() async {
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

    return List<Map<String, dynamic>>.from(
      result,
    );
  }

  // =========================================================
  // MONTHLY EMPLOYEE RECAP
  // =========================================================

  Future<List<Map<String, dynamic>>>
      getMonthlyEmployeeRecap({
    required int month,
    required int year,
  }) async {
    final startDate =
        DateTime.utc(
      year,
      month,
      1,
    );

    final endDate =
        month == 12
            ? DateTime.utc(
                year + 1,
                1,
                1,
              )
            : DateTime.utc(
                year,
                month + 1,
                1,
              );

    final result =
        await supabase
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
              startDate
                  .toIso8601String()
                  .split('T')[0],
            )
            .lt(
              'attendance_date',
              endDate
                  .toIso8601String()
                  .split('T')[0],
            );

    final Map<
        String,
        Map<String, dynamic>>
        recap = {};

    for (final row in result) {
      final item =
          Map<String, dynamic>.from(
        row,
      );

      final userId =
          item['user_id'].toString();

      final profileRaw =
          item['profiles'];

      final profile =
          profileRaw is Map
              ? Map<String, dynamic>.from(
                  profileRaw,
                )
              : <String, dynamic>{};

      final nama =
          profile['nama']
                  ?.toString() ??
              'Pegawai';

      final role =
          profile['role']
                  ?.toString() ??
              '-';

      if (!recap.containsKey(userId)) {
        recap[userId] = {
          'user_id':
              userId,
          'nama':
              nama,
          'role':
              role,
          'hadir':
              0,
          'lembur':
              0,
        };
      }

      recap[userId]!['hadir'] =
          (recap[userId]!['hadir']
                  as int) +
              1;

      if (item['is_overtime'] ==
          true) {
        recap[userId]!['lembur'] =
            (recap[userId]!['lembur']
                    as int) +
                1;
      }
    }

    final recapList =
        recap.values.toList();

    recapList.sort(
      (a, b) {
        return a['nama']
            .toString()
            .compareTo(
              b['nama'].toString(),
            );
      },
    );

    return recapList;
  }

  // =========================================================
  // EMPLOYEE ATTENDANCE
  // =========================================================

  Future<List<Map<String, dynamic>>>
      getEmployeeAttendance({
    required String userId,
    required int month,
    required int year,
  }) async {
    final startDate =
        DateTime.utc(
      year,
      month,
      1,
    );

    final endDate =
        month == 12
            ? DateTime.utc(
                year + 1,
                1,
                1,
              )
            : DateTime.utc(
                year,
                month + 1,
                1,
              );

    final result =
        await supabase
            .from('attendance')
            .select()
            .eq(
              'user_id',
              userId,
            )
            .gte(
              'attendance_date',
              startDate
                  .toIso8601String()
                  .split('T')[0],
            )
            .lt(
              'attendance_date',
              endDate
                  .toIso8601String()
                  .split('T')[0],
            )
            .order(
              'attendance_date',
              ascending: false,
            );

    return List<Map<String, dynamic>>.from(
      result,
    );
  }

  // =========================================================
  // ATTENDANCE BY MONTH
  // =========================================================

  Future<List<Map<String, dynamic>>>
      getAttendanceByMonth({
    required int month,
    required int year,
  }) async {
    final startDate =
        DateTime.utc(
      year,
      month,
      1,
    );

    final endDate =
        month == 12
            ? DateTime.utc(
                year + 1,
                1,
                1,
              )
            : DateTime.utc(
                year,
                month + 1,
                1,
              );

    final result =
        await supabase
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
              startDate
                  .toIso8601String()
                  .split('T')[0],
            )
            .lt(
              'attendance_date',
              endDate
                  .toIso8601String()
                  .split('T')[0],
            )
            .order(
              'attendance_date',
              ascending: false,
            );

    return List<Map<String, dynamic>>.from(
      result,
    );
  }
    Future<List<Map<String, dynamic>>>
      getEmployeeAttendanceByRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    String formatDate(DateTime date) {
      final month =
          date.month.toString().padLeft(2, '0');

      final day =
          date.day.toString().padLeft(2, '0');

      return '${date.year}-$month-$day';
    }

    final start = formatDate(startDate);
    final end = formatDate(endDate);

    final response = await supabase
        .from('attendance')
        .select('''
          id,
          user_id,
          attendance_date,
          check_in,
          check_out,
          total_work_hours,
          is_overtime,
          is_manual,
          manual_reason
        ''')
        .eq(
          'user_id',
          userId,
        )
        .gte(
          'attendance_date',
          start,
        )
        .lte(
          'attendance_date',
          end,
        )
        .order(
          'attendance_date',
          ascending: true,
        );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }
}