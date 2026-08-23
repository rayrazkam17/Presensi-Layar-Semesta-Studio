import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/current_user_header.dart';

import 'login_page.dart';
import 'attendance_page.dart';
import 'my_attendance_page.dart';

class DashboardUserPage
    extends StatelessWidget {
  const DashboardUserPage({
    super.key,
  });

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
    await Supabase.instance.client.auth
        .signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                const LoginPage(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title:
            const Text(
          'Dashboard User',
        ),

        actions: [
          IconButton(
            icon:
                const Icon(
              Icons.logout_rounded,
            ),

            tooltip:
                'Logout',

            onPressed:
                () =>
                    _logout(
              context,
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            16,
          ),

          child: Center(
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth:
                    700,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,

                children: [
                  // ===========================================
                  // CURRENT USER
                  // ===========================================

                  const CurrentUserHeader(),

                  const SizedBox(
                    height:
                        32,
                  ),

                  // ===========================================
                  // TITLE
                  // ===========================================

                  Text(
                    'Menu Presensi',

                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                  ),

                  const SizedBox(
                    height:
                        8,
                  ),

                  Text(
                    'Silakan pilih menu yang ingin digunakan.',

                    style:
                        Theme.of(
                      context,
                    )
                            .textTheme
                            .bodyMedium,
                  ),

                  const SizedBox(
                    height:
                        24,
                  ),

                  // ===========================================
                  // ATTENDANCE CARD
                  // ===========================================

                  Card(
                    clipBehavior:
                        Clip.antiAlias,

                    child:
                        InkWell(
                      onTap:
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const AttendancePage(),
                          ),
                        );
                      },

                      child:
                          const Padding(
                        padding:
                            EdgeInsets.all(
                          20,
                        ),

                        child:
                            Row(
                          children: [
                            CircleAvatar(
                              radius:
                                  27,

                              child:
                                  Icon(
                                Icons
                                    .camera_alt_rounded,
                              ),
                            ),

                            SizedBox(
                              width:
                                  16,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Text(
                                    'Absen Sekarang',

                                    style:
                                        TextStyle(
                                      fontSize:
                                          17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        4,
                                  ),

                                  Text(
                                    'Ambil foto untuk melakukan '
                                    'absen masuk atau keluar.',
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              Icons
                                  .chevron_right_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height:
                        12,
                  ),

                  // ===========================================
                  // HISTORY CARD
                  // ===========================================

                  Card(
                    clipBehavior:
                        Clip.antiAlias,

                    child:
                        InkWell(
                      onTap:
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const MyAttendancePage(),
                          ),
                        );
                      },

                      child:
                          const Padding(
                        padding:
                            EdgeInsets.all(
                          20,
                        ),

                        child:
                            Row(
                          children: [
                            CircleAvatar(
                              radius:
                                  27,

                              child:
                                  Icon(
                                Icons
                                    .history_rounded,
                              ),
                            ),

                            SizedBox(
                              width:
                                  16,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Text(
                                    'Riwayat Presensi',

                                    style:
                                        TextStyle(
                                      fontSize:
                                          17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        4,
                                  ),

                                  Text(
                                    'Lihat riwayat kehadiran '
                                    'dan jam kerja Anda.',
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              Icons
                                  .chevron_right_rounded,
                            ),
                          ],
                        ),
                      ),
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