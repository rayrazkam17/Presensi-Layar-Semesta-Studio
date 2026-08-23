import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/logged_in_user.dart';

class AuthService {
  final SupabaseClient supabase =
      Supabase.instance.client;

  // =========================================================
  // CURRENT AUTH USER
  // =========================================================

  User? get currentAuthUser {
    return supabase.auth.currentUser;
  }

  // =========================================================
  // CURRENT SESSION
  // =========================================================

  Session? get currentSession {
    return supabase.auth.currentSession;
  }

  // =========================================================
  // IS LOGGED IN
  // =========================================================

  bool get isLoggedIn {
    return supabase.auth.currentSession != null;
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<LoggedInUser> login({
    required String email,
    required String password,
  }) async {
    try {
      // -----------------------------------------------------
      // LOGIN KE SUPABASE AUTH
      // -----------------------------------------------------

      final response =
          await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception(
          'Login berhasil tetapi data user tidak ditemukan.',
        );
      }

      // -----------------------------------------------------
      // AMBIL PROFILE BERDASARKAN AUTH USER ID
      // -----------------------------------------------------

      final profile = await supabase
          .from('profiles')
          .select(
            'id, nama, role',
          )
          .eq(
            'id',
            user.id,
          )
          .maybeSingle();

      if (profile == null) {
        // User Auth ada tetapi profiles belum ada.
        await supabase.auth.signOut();

        throw Exception(
          'Profile pengguna belum terdaftar.',
        );
      }

      final nama =
          profile['nama']?.toString().trim() ?? '';

      final role =
          profile['role']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (role.isEmpty) {
        await supabase.auth.signOut();

        throw Exception(
          'Role pengguna belum dikonfigurasi.',
        );
      }

      // -----------------------------------------------------
      // VALIDASI ROLE
      // -----------------------------------------------------

      if (role != 'admin' &&
          role != 'user') {
        await supabase.auth.signOut();

        throw Exception(
          'Role "$role" tidak dikenali.',
        );
      }

      // -----------------------------------------------------
      // CREATE USER MODEL
      // -----------------------------------------------------

      final loggedInUser =
          LoggedInUser(
        id: user.id,
        email: user.email ?? email.trim(),
        nama: nama.isEmpty
            ? 'Pengguna'
            : nama,
        role: role,
      );

      debugPrint(
        '=====================================',
      );

      debugPrint(
        'LOGIN BERHASIL',
      );

      debugPrint(
        'User ID : ${loggedInUser.id}',
      );

      debugPrint(
        'Email   : ${loggedInUser.email}',
      );

      debugPrint(
        'Nama    : ${loggedInUser.nama}',
      );

      debugPrint(
        'Role    : ${loggedInUser.role}',
      );

      debugPrint(
        '=====================================',
      );

      return loggedInUser;
    }

    // =======================================================
    // SUPABASE AUTH ERROR
    // =======================================================

    on AuthException catch (e) {
      throw Exception(
        _translateAuthError(e.message),
      );
    }

    // =======================================================
    // OTHER ERROR
    // =======================================================

    catch (e) {
      debugPrint(
        'Login error: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // GET CURRENT USER PROFILE
  //
  // Dipakai ketika browser direfresh tetapi session
  // Supabase masih aktif.
  // =========================================================

  Future<LoggedInUser?>
      getCurrentUserProfile() async {
    final user =
        supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select(
            'id, nama, role',
          )
          .eq(
            'id',
            user.id,
          )
          .maybeSingle();

      if (profile == null) {
        return null;
      }

      final role =
          profile['role']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      final nama =
          profile['nama']
                  ?.toString()
                  .trim() ??
              '';

      return LoggedInUser(
        id: user.id,
        email: user.email ?? '',
        nama: nama.isEmpty
            ? 'Pengguna'
            : nama,
        role: role,
      );
    } catch (e) {
      debugPrint(
        'Gagal mengambil profile user: $e',
      );

      return null;
    }
  }

  // =========================================================
  // GET USER ROLE
  //
  // Tetap disediakan supaya kode lama yang menggunakan
  // getUserRole() tidak rusak.
  // =========================================================

  Future<String?> getUserRole() async {
    final profile =
        await getCurrentUserProfile();

    return profile?.role;
  }

  // =========================================================
  // GET USER NAME
  // =========================================================

  Future<String?> getUserName() async {
    final profile =
        await getCurrentUserProfile();

    return profile?.nama;
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();

      debugPrint(
        'Logout berhasil.',
      );
    } catch (e) {
      debugPrint(
        'Logout error: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // AUTH ERROR TRANSLATOR
  // =========================================================

  String _translateAuthError(
    String message,
  ) {
    final lower =
        message.toLowerCase();

    if (lower.contains(
      'invalid login credentials',
    )) {
      return 'Email atau password salah.';
    }

    if (lower.contains(
      'email not confirmed',
    )) {
      return 'Email belum dikonfirmasi.';
    }

    if (lower.contains(
      'user not found',
    )) {
      return 'Pengguna tidak ditemukan.';
    }

    if (lower.contains(
      'too many requests',
    )) {
      return 'Terlalu banyak percobaan login. '
          'Silakan coba lagi nanti.';
    }

    return message;
  }
}