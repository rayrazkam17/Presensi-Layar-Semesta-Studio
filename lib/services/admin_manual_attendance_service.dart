import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceAlreadyExistsException
    implements Exception {
  final String message;

  const AttendanceAlreadyExistsException(
    this.message,
  );

  @override
  String toString() {
    return message;
  }
}

class AdminManualAttendanceService {
  final SupabaseClient supabase =
      Supabase.instance.client;

  Future<Map<String, dynamic>>
      saveManualAttendance({
    required String userId,
    required DateTime date,
    required TimeOfDayData checkIn,
    required TimeOfDayData checkOut,
    required String reason,
    String? note,
    bool replaceExisting = false,
  }) async {
    final session =
        supabase.auth.currentSession;

    if (session == null) {
      throw Exception(
        'Session login tidak ditemukan. '
        'Silakan login kembali.',
      );
    }

    try {
      final response =
          await supabase.functions.invoke(
        'admin-manual-attendance',

        headers: {
          'Authorization':
              'Bearer ${session.accessToken}',
        },

        body: {
          'user_id':
              userId,

          'attendance_date':
              _formatDate(date),

          'check_in':
              checkIn.formatted,

          'check_out':
              checkOut.formatted,

          'reason':
              reason,

          'note':
              note?.trim() ?? '',

          'replace_existing':
              replaceExisting,
        },
      );

      final raw =
          response.data;

      if (raw is! Map) {
        throw Exception(
          'Response server tidak valid.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        raw,
      );

      if (data['ok'] != true) {
        if (data['code'] ==
            'attendance_exists') {
          throw AttendanceAlreadyExistsException(
            data['message']?.toString() ??
                'Presensi pada tanggal tersebut sudah ada.',
          );
        }

        throw Exception(
          data['message']?.toString() ??
              'Gagal menyimpan presensi manual.',
        );
      }

      return data;
    } on AttendanceAlreadyExistsException {
      rethrow;
    } on FunctionException catch (e) {
      throw Exception(
        e.details?.toString() ??
            e.reasonPhrase ??
            'Edge Function gagal dijalankan.',
      );
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '${date.year}-$month-$day';
  }
}

class TimeOfDayData {
  final int hour;
  final int minute;

  const TimeOfDayData({
    required this.hour,
    required this.minute,
  });

  String get formatted {
    final h =
        hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final m =
        minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$h:$m';
  }
}