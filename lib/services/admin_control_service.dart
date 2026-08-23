import 'package:supabase_flutter/supabase_flutter.dart';

class AdminControlService {
  final SupabaseClient supabase =
      Supabase.instance.client;

  // =========================================================
  // INVOKE ADMIN EDGE FUNCTION
  // =========================================================

  Future<Map<String, dynamic>> _invoke({
  required String action,
  Map<String, dynamic>? body,
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
      'admin-control',

      headers: {
        'Authorization':
            'Bearer ${session.accessToken}',
      },

      body: {
        'action': action,
        ...?body,
      },
    );

    final dynamic rawData =
        response.data;

    if (rawData is! Map) {
      throw Exception(
        'Response server tidak valid.',
      );
    }

    final data =
        Map<String, dynamic>.from(
      rawData,
    );

    if (data['ok'] != true) {
      throw Exception(
        data['message']
                ?.toString() ??
            'Operasi admin gagal.',
      );
    }

    return data;
  } on FunctionException catch (e) {
    throw Exception(
      e.details?.toString() ??
          e.reasonPhrase ??
          'Edge Function gagal dijalankan.',
    );
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception(
      e.toString(),
    );
  }
}

  // =========================================================
  // LIST EMPLOYEES
  // =========================================================

  Future<List<Map<String, dynamic>>>
      getEmployees() async {
    final data =
        await _invoke(
      action:
          'list_employees',
    );

    final employees =
        data['employees'];

    if (employees is! List) {
      return [];
    }

    return employees
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  // =========================================================
  // CREATE EMPLOYEE
  // =========================================================

  Future<void> createEmployee({
    required String nama,
    required String email,
    required String password,
  }) async {
    await _invoke(
      action:
          'create_employee',
      body: {
        'nama':
            nama.trim(),

        'email':
            email.trim(),

        'password':
            password,
      },
    );
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    await _invoke(
      action:
          'reset_password',
      body: {
        'user_id':
            userId,

        'new_password':
            newPassword,
      },
    );
  }

  // =========================================================
  // DELETE SINGLE ATTENDANCE
  // =========================================================

  Future<void> deleteAttendance({
    required String attendanceId,
  }) async {
    await _invoke(
      action:
          'delete_attendance',
      body: {
        'attendance_id':
            attendanceId,
      },
    );
  }

  // =========================================================
  // DELETE EMPLOYEE ACCOUNT
  // =========================================================

  Future<void> deleteEmployee({
    required String userId,
  }) async {
    await _invoke(
      action:
          'delete_employee',

      body: {
        'user_id':
            userId,
      },
    );
  }
}