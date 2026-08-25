import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/current_user_header.dart';

import 'attendance_page.dart';
import 'login_page.dart';
import 'my_attendance_page.dart';

class DashboardUserPage extends StatelessWidget {
  const DashboardUserPage({
    super.key,
  });

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.logout_rounded,
            size: 38,
          ),
          title: const Text(
            'Logout?',
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'BATAL',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'LOGOUT',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // MENU CARD
  // =========================================================

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,

      child: InkWell(
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,

            children: [
              // =================================================
              // ICON
              // =================================================

              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,

                  borderRadius:
                      BorderRadius.circular(
                    100,
                  ),
                ),

                child: Icon(
                  icon,
                  size: 29,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              // =================================================
              // TEXT
              // =================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      description,

                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,

                      // Jangan batasi maxLines.
                      // Supaya HP kecil bisa wrap.
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // =================================================
              // ARROW
              // =================================================

              const Icon(
                Icons.chevron_right_rounded,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final isSmallMobile =
        screenWidth < 430;

    final bottomSafeArea =
        MediaQuery.viewPaddingOf(context).bottom;

    // =========================================================
    // SAFARI / MOBILE BOTTOM SPACE
    //
    // Browser Safari mempunyai toolbar bawah yang dapat
    // menutupi isi Flutter Web.
    //
    // Kita beri ruang ekstra supaya card terakhir benar-benar
    // bisa discroll melewati toolbar browser.
    // =========================================================

    final bottomPadding =
        isSmallMobile
            ? 130.0 + bottomSafeArea
            : 60.0 + bottomSafeArea;

    return Scaffold(
      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title: const Text(
          'Dashboard User',
        ),

        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
            ),
            tooltip: 'Logout',
            onPressed: () {
              _logout(context);
            },
          ),

          const SizedBox(
            width: 6,
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        bottom: false,

        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return ListView(
              // =================================================
              // INI BAGIAN PENTING UNTUK HP KECIL
              // =================================================

              physics:
                  const AlwaysScrollableScrollPhysics(
                parent:
                    BouncingScrollPhysics(),
              ),

              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,

              padding: EdgeInsets.fromLTRB(
                isSmallMobile ? 16 : 24,
                18,
                isSmallMobile ? 16 : 24,
                bottomPadding,
              ),

              children: [
                // =================================================
                // CENTER CONTENT
                // =================================================

                Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 700,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,

                      children: [
                        // ===========================================
                        // USER HEADER
                        // ===========================================

                        const CurrentUserHeader(),

                        SizedBox(
                          height:
                              isSmallMobile
                                  ? 32
                                  : 38,
                        ),

                        // ===========================================
                        // MENU TITLE
                        // ===========================================

                        Text(
                          'Menu Presensi',

                          style:
                              Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Silakan pilih menu yang ingin digunakan.',

                          style:
                              Theme.of(context)
                                  .textTheme
                                  .bodyLarge,
                        ),

                        const SizedBox(
                          height: 26,
                        ),

                        // ===========================================
                        // ABSEN SEKARANG
                        // ===========================================

                        _buildMenuCard(
                          context: context,

                          icon:
                              Icons.camera_alt_rounded,

                          title:
                              'Absen Sekarang',

                          description:
                              'Ambil foto untuk melakukan '
                              'absen masuk atau keluar.',

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        const AttendancePage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // ===========================================
                        // RIWAYAT PRESENSI
                        // ===========================================

                        _buildMenuCard(
                          context: context,

                          icon:
                              Icons.history_rounded,

                          title:
                              'Riwayat Presensi',

                          description:
                              'Lihat riwayat kehadiran dan '
                              'jam kerja Anda.',

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        const MyAttendancePage(),
                              ),
                            );
                          },
                        ),

                        // ===========================================
                        // EXTRA BOTTOM SPACE
                        // ===========================================

                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 