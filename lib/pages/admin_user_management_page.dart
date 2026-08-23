import 'package:flutter/material.dart';

import '../services/admin_control_service.dart';

class AdminUserManagementPage
    extends StatefulWidget {
  const AdminUserManagementPage({
    super.key,
  });

  @override
  State<AdminUserManagementPage>
      createState() =>
          _AdminUserManagementPageState();
}

class _AdminUserManagementPageState
    extends State<
        AdminUserManagementPage> {
  // =========================================================
  // SERVICE
  // =========================================================

  final AdminControlService
      _adminService =
      AdminControlService();

  // =========================================================
  // DATA
  // =========================================================

  late Future<
          List<Map<String, dynamic>>>
      _employeesFuture;

  String? _deletingUserId;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadEmployees();
  }

  // =========================================================
  // LOAD
  // =========================================================

  void _loadEmployees() {
    _employeesFuture =
        _adminService
            .getEmployees();
  }

  // =========================================================
  // REFRESH
  // =========================================================

  void _refresh() {
    setState(() {
      _loadEmployees();
    });
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(
            message,
          ),

          backgroundColor:
              error
                  ? Theme.of(context)
                      .colorScheme
                      .error
                  : Colors
                      .green
                      .shade700,
        ),
      );
  }

  // =========================================================
  // CREATE EMPLOYEE
  // =========================================================

  Future<void>
      _showCreateEmployeeDialog() async {
    final namaController =
        TextEditingController();

    final emailController =
        TextEditingController();

    final passwordController =
        TextEditingController();

    bool obscurePassword =
        true;

    bool loading =
        false;

    await showDialog<void>(
      context:
          context,

      barrierDismissible:
          false,

      builder:
          (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder:
              (
            context,
            setDialogState,
          ) {
            Future<void> submit()
                async {
              final nama =
                  namaController
                      .text
                      .trim();

              final email =
                  emailController
                      .text
                      .trim();

              final password =
                  passwordController
                      .text;

              if (nama.isEmpty) {
                _showMessage(
                  'Nama wajib diisi.',
                  error:
                      true,
                );

                return;
              }

              if (!email
                  .contains(
                    '@',
                  )) {
                _showMessage(
                  'Email belum valid.',
                  error:
                      true,
                );

                return;
              }

              if (password.length <
                  8) {
                _showMessage(
                  'Password minimal 8 karakter.',
                  error:
                      true,
                );

                return;
              }

              setDialogState(
                () {
                  loading =
                      true;
                },
              );

              try {
                await _adminService
                    .createEmployee(
                  nama:
                      nama,

                  email:
                      email,

                  password:
                      password,
                );

                if (!mounted) {
                  return;
                }

                if (dialogContext
                    .mounted) {
                  Navigator.pop(
                    dialogContext,
                  );
                }

                _showMessage(
                  'Akun $nama berhasil dibuat.',
                );

                _refresh();
              } catch (e) {
                _showMessage(
                  e
                      .toString()
                      .replaceFirst(
                        'Exception: ',
                        '',
                      ),

                  error:
                      true,
                );
              }
            }

            return AlertDialog(
              title:
                  const Row(
                children: [
                  Icon(
                    Icons
                        .person_add_alt_1_rounded,
                  ),

                  SizedBox(
                    width:
                        10,
                  ),

                  Text(
                    'Tambah Pegawai',
                  ),
                ],
              ),

              content:
                  SizedBox(
                width:
                    420,

                child:
                    SingleChildScrollView(
                  child:
                      Column(
                    mainAxisSize:
                        MainAxisSize
                            .min,

                    children: [
                      TextField(
                        controller:
                            namaController,

                        textInputAction:
                            TextInputAction
                                .next,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Nama Pegawai',

                          prefixIcon:
                              Icon(
                            Icons
                                .person_outline_rounded,
                          ),

                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height:
                            14,
                      ),

                      TextField(
                        controller:
                            emailController,

                        keyboardType:
                            TextInputType
                                .emailAddress,

                        textInputAction:
                            TextInputAction
                                .next,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Email / Username',

                          prefixIcon:
                              Icon(
                            Icons
                                .email_outlined,
                          ),

                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height:
                            14,
                      ),

                      TextField(
                        controller:
                            passwordController,

                        obscureText:
                            obscurePassword,

                        textInputAction:
                            TextInputAction
                                .done,

                        decoration:
                            InputDecoration(
                          labelText:
                              'Password Awal',

                          helperText:
                              'Minimal 8 karakter',

                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline_rounded,
                          ),

                          border:
                              const OutlineInputBorder(),

                          suffixIcon:
                              IconButton(
                            onPressed:
                                () {
                              setDialogState(
                                () {
                                  obscurePassword =
                                      !obscurePassword;
                                },
                              );
                            },

                            icon:
                                Icon(
                              obscurePassword
                                  ? Icons
                                      .visibility_outlined
                                  : Icons
                                      .visibility_off_outlined,
                            ),
                          ),
                        ),

                        onSubmitted:
                            (_) {
                          if (!loading) {
                            submit();
                          }
                        },
                      ),

                      const SizedBox(
                        height:
                            12,
                      ),

                      Container(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors
                                  .amber
                                  .withValues(
                            alpha:
                                0.10,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),

                        child:
                            const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Icon(
                              Icons
                                  .info_outline_rounded,
                              size:
                                  20,
                            ),

                            SizedBox(
                              width:
                                  8,
                            ),

                            Expanded(
                              child:
                                  Text(
                                'Catat atau berikan password awal '
                                'kepada pegawai. Password lama tidak '
                                'dapat dilihat kembali setelah akun dibuat.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed:
                      loading
                          ? null
                          : () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },

                  child:
                      const Text(
                    'Batal',
                  ),
                ),

                FilledButton.icon(
                  onPressed:
                      loading
                          ? null
                          : submit,

                  icon:
                      loading
                          ? const SizedBox(
                              width:
                                  18,
                              height:
                                  18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .person_add_rounded,
                            ),

                  label:
                      Text(
                    loading
                        ? 'Membuat...'
                        : 'Buat Akun',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    namaController
        .dispose();

    emailController
        .dispose();

    passwordController
        .dispose();
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  Future<void>
      _showResetPasswordDialog(
    Map<String, dynamic> employee,
  ) async {
    final passwordController =
        TextEditingController();

    bool obscure =
        true;

    bool loading =
        false;

    await showDialog<void>(
      context:
          context,

      barrierDismissible:
          false,

      builder:
          (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder:
              (
            context,
            setDialogState,
          ) {
            Future<void> submit()
                async {
              final password =
                  passwordController
                      .text;

              if (password.length <
                  8) {
                _showMessage(
                  'Password baru minimal 8 karakter.',
                  error:
                      true,
                );

                return;
              }

              setDialogState(
                () {
                  loading =
                      true;
                },
              );

              try {
                await _adminService
                    .resetPassword(
                  userId:
                      employee['id']
                          .toString(),

                  newPassword:
                      password,
                );

                if (!mounted) {
                  return;
                }

                if (dialogContext
                    .mounted) {
                  Navigator.pop(
                    dialogContext,
                  );
                }

                _showMessage(
                  'Password ${employee['nama']} berhasil diubah.',
                );
              } catch (e) {
                _showMessage(
                  e
                      .toString()
                      .replaceFirst(
                        'Exception: ',
                        '',
                      ),

                  error:
                      true,
                );
              }
            }

            return AlertDialog(
              title:
                  const Text(
                'Ubah Password Pegawai',
              ),

              content:
                  SizedBox(
                width:
                    400,

                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize
                          .min,

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,

                  children: [
                    Text(
                      employee['nama']
                              ?.toString() ??
                          'Pegawai',

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,

                        fontSize:
                            17,
                      ),
                    ),

                    const SizedBox(
                      height:
                          4,
                    ),

                    Text(
                      employee['email']
                              ?.toString() ??
                          '-',
                    ),

                    const SizedBox(
                      height:
                          20,
                    ),

                    TextField(
                      controller:
                          passwordController,

                      obscureText:
                          obscure,

                      autofocus:
                          true,

                      decoration:
                          InputDecoration(
                        labelText:
                            'Password Baru',

                        helperText:
                            'Minimal 8 karakter',

                        prefixIcon:
                            const Icon(
                          Icons
                              .password_rounded,
                        ),

                        border:
                            const OutlineInputBorder(),

                        suffixIcon:
                            IconButton(
                          onPressed:
                              () {
                            setDialogState(
                              () {
                                obscure =
                                    !obscure;
                              },
                            );
                          },

                          icon:
                              Icon(
                            obscure
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          12,
                    ),

                    const Text(
                      'Password lama tidak dapat dilihat. '
                      'Password baru akan menggantikan '
                      'password sebelumnya.',
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed:
                      loading
                          ? null
                          : () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },

                  child:
                      const Text(
                    'Batal',
                  ),
                ),

                FilledButton(
                  onPressed:
                      loading
                          ? null
                          : submit,

                  child:
                      Text(
                    loading
                        ? 'Mengubah...'
                        : 'Ubah Password',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController
        .dispose();
  }

  // =========================================================
  // DELETE EMPLOYEE
  // =========================================================

  Future<void>
      _showDeleteEmployeeDialog(
    Map<String, dynamic> employee,
  ) async {
    final userId =
        employee['id']
            ?.toString();

    final nama =
        employee['nama']
                ?.toString() ??
            'Pegawai';

    final email =
        employee['email']
                ?.toString() ??
            '-';

    if (userId == null ||
        userId.isEmpty) {
      _showMessage(
        'User ID pegawai tidak ditemukan.',
        error:
            true,
      );

      return;
    }

    // =======================================================
    // INPUT KONFIRMASI
    // =======================================================

    final confirmationController =
        TextEditingController();

    bool canDelete =
        false;

    final confirmed =
        await showDialog<bool>(
      context:
          context,

      barrierDismissible:
          false,

      builder:
          (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder:
              (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              icon:
                  Icon(
                Icons
                    .warning_amber_rounded,

                size:
                    52,

                color:
                    Theme.of(
                  dialogContext,
                )
                        .colorScheme
                        .error,
              ),

              title:
                  const Text(
                'Hapus Akun Pegawai?',
                textAlign:
                    TextAlign.center,
              ),

              content:
                  SizedBox(
                width:
                    440,

                child:
                    SingleChildScrollView(
                  child:
                      Column(
                    mainAxisSize:
                        MainAxisSize
                            .min,

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [
                      // =====================================
                      // EMPLOYEE
                      // =====================================

                      Container(
                        padding:
                            const EdgeInsets.all(
                          14,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Theme.of(
                            context,
                          )
                                  .colorScheme
                                  .surfaceContainerHighest,

                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),

                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              nama,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,

                                fontSize:
                                    17,
                              ),
                            ),

                            const SizedBox(
                              height:
                                  4,
                            ),

                            Text(
                              email,
                            ),

                            const SizedBox(
                              height:
                                  4,
                            ),

                            const Text(
                              'Role: Pegawai',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height:
                            18,
                      ),

                      // =====================================
                      // WARNING
                      // =====================================

                      Container(
                        padding:
                            const EdgeInsets.all(
                          14,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Theme.of(
                            context,
                          )
                                  .colorScheme
                                  .error
                                  .withValues(
                                alpha:
                                    0.08,
                              ),

                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),

                          border:
                              Border.all(
                            color:
                                Theme.of(
                              context,
                            )
                                    .colorScheme
                                    .error
                                    .withValues(
                                  alpha:
                                      0.25,
                                ),
                          ),
                        ),

                        child:
                            Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Icon(
                              Icons
                                  .delete_forever_rounded,

                              color:
                                  Theme.of(
                                context,
                              )
                                      .colorScheme
                                      .error,
                            ),

                            const SizedBox(
                              width:
                                  10,
                            ),

                            const Expanded(
                              child:
                                  Text(
                                'PERINGATAN\n\n'
                                'Akun login, profile, dan riwayat '
                                'presensi pegawai ini akan dihapus.\n\n'
                                'Data yang sudah dihapus tidak dapat '
                                'dipulihkan kembali.',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height:
                            20,
                      ),

                      const Text(
                        'Untuk melanjutkan, ketik:',
                      ),

                      const SizedBox(
                        height:
                            5,
                      ),

                      Text(
                        'HAPUS',

                        style:
                            TextStyle(
                          fontSize:
                              18,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              Theme.of(
                            context,
                          )
                                  .colorScheme
                                  .error,
                        ),
                      ),

                      const SizedBox(
                        height:
                            10,
                      ),

                      // =====================================
                      // CONFIRM INPUT
                      // =====================================

                      TextField(
                        controller:
                            confirmationController,

                        autofocus:
                            true,

                        autocorrect:
                            false,

                        enableSuggestions:
                            false,

                        textCapitalization:
                            TextCapitalization
                                .characters,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Ketik HAPUS',

                          prefixIcon:
                              Icon(
                            Icons
                                .keyboard_rounded,
                          ),

                          border:
                              OutlineInputBorder(),
                        ),

                        onChanged:
                            (
                          value,
                        ) {
                          setDialogState(
                            () {
                              canDelete =
                                  value
                                          .trim()
                                          .toUpperCase() ==
                                      'HAPUS';
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed:
                      () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },

                  child:
                      const Text(
                    'BATAL',
                  ),
                ),

                FilledButton.icon(
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(
                      dialogContext,
                    )
                            .colorScheme
                            .error,

                    foregroundColor:
                        Theme.of(
                      dialogContext,
                    )
                            .colorScheme
                            .onError,
                  ),

                  onPressed:
                      canDelete
                          ? () {
                              Navigator.pop(
                                dialogContext,
                                true,
                              );
                            }
                          : null,

                  icon:
                      const Icon(
                    Icons
                        .delete_forever_rounded,
                  ),

                  label:
                      const Text(
                    'HAPUS PERMANEN',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    confirmationController
        .dispose();

    if (confirmed !=
        true) {
      return;
    }

    // =======================================================
    // DELETE
    // =======================================================

    setState(() {
      _deletingUserId =
          userId;
    });

    try {
      await _adminService
          .deleteEmployee(
        userId:
            userId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Akun $nama berhasil dihapus permanen.',
      );

      _refresh();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),

        error:
            true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingUserId =
              null;
        });
      }
    }
  }

  // =========================================================
  // BUILD EMPLOYEE
  // =========================================================

  Widget _buildEmployeeCard(
    Map<String, dynamic> employee,
  ) {
    final id =
        employee['id']
                ?.toString() ??
            '';

    final nama =
        employee['nama']
                ?.toString() ??
            'Pegawai';

    final email =
        employee['email']
                ?.toString() ??
            '-';

    final deleting =
        _deletingUserId ==
            id;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom:
            10,
      ),

      child:
          Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical:
              4,
        ),

        child:
            ListTile(
          leading:
              CircleAvatar(
            child:
                Text(
              nama.isNotEmpty
                  ? nama[0]
                      .toUpperCase()
                  : '?',
            ),
          ),

          title:
              Text(
            nama,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          subtitle:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              const SizedBox(
                height:
                    4,
              ),

              Row(
                children: [
                  const Icon(
                    Icons
                        .email_outlined,
                    size:
                        15,
                  ),

                  const SizedBox(
                    width:
                        5,
                  ),

                  Expanded(
                    child:
                        Text(
                      email,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                    3,
              ),

              const Row(
                children: [
                  Icon(
                    Icons
                        .badge_outlined,
                    size:
                        15,
                  ),

                  SizedBox(
                    width:
                        5,
                  ),

                  Text(
                    'Pegawai',
                  ),
                ],
              ),
            ],
          ),

          // =================================================
          // ACTIONS
          // =================================================

          trailing:
              deleting
                  ? const SizedBox(
                      width:
                          28,
                      height:
                          28,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          MainAxisSize
                              .min,

                      children: [
                        // ===================================
                        // RESET PASSWORD
                        // ===================================

                        IconButton(
                          tooltip:
                              'Ubah Password',

                          onPressed:
                              () {
                            _showResetPasswordDialog(
                              employee,
                            );
                          },

                          icon:
                              const Icon(
                            Icons
                                .key_rounded,
                          ),
                        ),

                        // ===================================
                        // DELETE ACCOUNT
                        // ===================================

                        IconButton(
                          tooltip:
                              'Hapus Akun',

                          onPressed:
                              _deletingUserId !=
                                      null
                                  ? null
                                  : () {
                                      _showDeleteEmployeeDialog(
                                        employee,
                                      );
                                    },

                          icon:
                              Icon(
                            Icons
                                .delete_outline_rounded,

                            color:
                                Theme.of(
                              context,
                            )
                                    .colorScheme
                                    .error,
                          ),
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
    return Scaffold(
      appBar:
          AppBar(
        title:
            const Text(
          'Manajemen Pegawai',
        ),

        actions: [
          IconButton(
            tooltip:
                'Refresh',

            onPressed:
                _refresh,

            icon:
                const Icon(
              Icons
                  .refresh_rounded,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _showCreateEmployeeDialog,

        icon:
            const Icon(
          Icons
              .person_add_rounded,
        ),

        label:
            const Text(
          'Tambah Pegawai',
        ),
      ),

      body:
          SafeArea(
        child:
            FutureBuilder<
                List<
                    Map<
                        String,
                        dynamic>>>(
          future:
              _employeesFuture,

          builder:
              (
            context,
            snapshot,
          ) {
            // =================================================
            // LOADING
            // =================================================

            if (snapshot
                    .connectionState ==
                ConnectionState
                    .waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            // =================================================
            // ERROR
            // =================================================

            if (snapshot.hasError) {
              return Center(
                child:
                    Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),

                  child:
                      Column(
                    mainAxisSize:
                        MainAxisSize
                            .min,

                    children: [
                      Icon(
                        Icons
                            .error_outline_rounded,

                        size:
                            48,

                        color:
                            Theme.of(
                          context,
                        )
                                .colorScheme
                                .error,
                      ),

                      const SizedBox(
                        height:
                            12,
                      ),

                      Text(
                        snapshot.error
                            .toString(),

                        textAlign:
                            TextAlign.center,
                      ),

                      const SizedBox(
                        height:
                            16,
                      ),

                      FilledButton.icon(
                        onPressed:
                            _refresh,

                        icon:
                            const Icon(
                          Icons
                              .refresh_rounded,
                        ),

                        label:
                            const Text(
                          'Coba Lagi',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // =================================================
            // EMPLOYEES
            // =================================================

            final employees =
                snapshot.data ??
                    [];

            if (employees.isEmpty) {
              return Center(
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize
                          .min,

                  children: [
                    const Icon(
                      Icons
                          .group_off_outlined,

                      size:
                          55,
                    ),

                    const SizedBox(
                      height:
                          14,
                    ),

                    const Text(
                      'Belum ada akun pegawai.',
                    ),

                    const SizedBox(
                      height:
                          16,
                    ),

                    FilledButton.icon(
                      onPressed:
                          _showCreateEmployeeDialog,

                      icon:
                          const Icon(
                        Icons
                            .person_add_rounded,
                      ),

                      label:
                          const Text(
                        'Tambah Pegawai',
                      ),
                    ),
                  ],
                ),
              );
            }

            // =================================================
            // LIST
            // =================================================

            return RefreshIndicator(
              onRefresh:
                  () async {
                _refresh();

                try {
                  await _employeesFuture;
                } catch (_) {}
              },

              child:
                  ListView.builder(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  100,
                ),

                itemCount:
                    employees.length,

                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  return _buildEmployeeCard(
                    employees[
                        index],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}