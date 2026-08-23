import 'package:flutter/material.dart';

import '../models/logged_in_user.dart';
import '../services/auth_service.dart';

import 'dashboard_admin_page.dart';
import 'dashboard_user_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  State<AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState
    extends State<AuthGate> {
  final AuthService _authService =
      AuthService();

  late Future<LoggedInUser?>
      _profileFuture;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _profileFuture =
        _checkCurrentUser();
  }

  // =========================================================
  // CHECK USER
  // =========================================================

  Future<LoggedInUser?>
      _checkCurrentUser() async {
    if (!_authService.isLoggedIn) {
      return null;
    }

    return _authService
        .getCurrentUserProfile();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        LoggedInUser?>(
      future:
          _profileFuture,

      builder:
          (
        context,
        snapshot,
      ) {
        // ===================================================
        // LOADING
        // ===================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),

                  SizedBox(
                    height: 16,
                  ),

                  Text(
                    'Memeriksa akun...',
                  ),
                ],
              ),
            ),
          );
        }

        // ===================================================
        // ERROR
        // ===================================================

        if (snapshot.hasError) {
          return const LoginPage();
        }

        // ===================================================
        // NOT LOGGED IN
        // ===================================================

        final user =
            snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        // ===================================================
        // ADMIN
        // ===================================================

        if (user.isAdmin) {
          return const DashboardAdminPage();
        }

        // ===================================================
        // USER
        // ===================================================

        if (user.isUser) {
          return const DashboardUserPage();
        }

        // ===================================================
        // INVALID ROLE
        // ===================================================

        return InvalidRolePage(
          role:
              user.role,
        );
      },
    );
  }
}

// ===========================================================
// INVALID ROLE
// ===========================================================

class InvalidRolePage
    extends StatelessWidget {
  final String role;

  const InvalidRolePage({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final authService =
        AuthService();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 420,
            ),

            child: Padding(
              padding:
                  const EdgeInsets.all(
                24,
              ),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Icon(
                    Icons
                        .warning_amber_rounded,
                    size: 64,
                    color:
                        Theme.of(
                      context,
                    )
                            .colorScheme
                            .error,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Text(
                    'Role Tidak Valid',
                    style:
                        TextStyle(
                      fontSize:
                          22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    'Role akun saat ini: "$role".',
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  FilledButton.icon(
                    onPressed:
                        () async {
                      await authService
                          .logout();

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.of(
                        context,
                      ).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  const LoginPage(),
                        ),
                        (
                          route,
                        ) =>
                            false,
                      );
                    },

                    icon:
                        const Icon(
                      Icons.logout_rounded,
                    ),

                    label:
                        const Text(
                      'LOGOUT',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}