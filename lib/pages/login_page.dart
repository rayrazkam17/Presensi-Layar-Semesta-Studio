import 'package:flutter/material.dart';

import '../models/logged_in_user.dart';
import '../services/auth_service.dart';

import 'dashboard_admin_page.dart';
import 'dashboard_user_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {
  // =========================================================
  // FORM
  // =========================================================

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  // =========================================================
  // FOCUS
  // =========================================================

  final FocusNode _emailFocusNode =
      FocusNode();

  final FocusNode _passwordFocusNode =
      FocusNode();

  // =========================================================
  // SERVICE
  // =========================================================

  final AuthService _authService =
      AuthService();

  // =========================================================
  // STATE
  // =========================================================

  bool _loading = false;

  bool _obscurePassword = true;

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _login() async {
    if (_loading) {
      return;
    }

    FocusManager.instance.primaryFocus
        ?.unfocus();

    final valid =
        _formKey.currentState
                ?.validate() ??
            false;

    if (!valid) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // =====================================================
      // LOGIN + GET USER + GET ROLE
      // =====================================================

      final LoggedInUser user =
          await _authService.login(
        email:
            _emailController.text.trim(),

        password:
            _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      // =====================================================
      // ADMIN
      // =====================================================

      if (user.isAdmin) {
        Navigator.of(context)
            .pushAndRemoveUntil(
          MaterialPageRoute(
            builder:
                (_) =>
                    const DashboardAdminPage(),
          ),
          (route) => false,
        );

        return;
      }

      // =====================================================
      // NORMAL USER
      // =====================================================

      if (user.isUser) {
        Navigator.of(context)
            .pushAndRemoveUntil(
          MaterialPageRoute(
            builder:
                (_) =>
                    const DashboardUserPage(),
          ),
          (route) => false,
        );

        return;
      }

      // =====================================================
      // UNKNOWN ROLE
      // =====================================================

      throw Exception(
        'Role pengguna "${user.role}" '
        'tidak dikenali.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e
                  .toString()
                  .replaceFirst(
                    'Exception: ',
                    '',
                  ),
            ),
            backgroundColor:
                Theme.of(context)
                    .colorScheme
                    .error,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // VALIDATE EMAIL
  // =========================================================

  String? _validateEmail(
    String? value,
  ) {
    final email =
        value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email wajib diisi.';
    }

    final emailPattern =
        RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(
      email,
    )) {
      return 'Format email belum benar.';
    }

    return null;
  }

  // =========================================================
  // VALIDATE PASSWORD
  // =========================================================

  String? _validatePassword(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Password wajib diisi.';
    }

    return null;
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context)
            .width;

    final isMobile =
        screenWidth < 600;

    return Scaffold(
      resizeToAvoidBottomInset:
          true,

      body: SafeArea(
        child: GestureDetector(
          behavior:
              HitTestBehavior.translucent,

          onTap: () {
            FocusManager
                .instance
                .primaryFocus
                ?.unfocus();
          },

          child: LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              final verticalPadding =
                  isMobile
                      ? 20.0
                      : 32.0;

              final minimumHeight =
                  constraints.maxHeight -
                      (verticalPadding * 2);

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .onDrag,

                padding:
                    EdgeInsets.symmetric(
                  horizontal:
                      isMobile
                          ? 16
                          : 24,
                  vertical:
                      verticalPadding,
                ),

                child:
                    ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    minHeight:
                        minimumHeight >
                                0
                            ? minimumHeight
                            : 0,
                  ),

                  child: Center(
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth:
                            420,
                      ),

                      child: Card(
                        elevation: 3,

                        clipBehavior:
                            Clip.antiAlias,

                        child: Padding(
                          padding:
                              EdgeInsets.all(
                            isMobile
                                ? 22
                                : 32,
                          ),

                          child:
                              AutofillGroup(
                            child:
                                Form(
                              key:
                                  _formKey,

                              child:
                                  Column(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,

                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch,

                                children: [
                                  // =========================
                                  // ICON
                                  // =========================

                                  Icon(
                                    Icons
                                        .badge_outlined,
                                    size:
                                        56,
                                    color:
                                        Theme.of(
                                      context,
                                    )
                                            .colorScheme
                                            .primary,
                                  ),

                                  const SizedBox(
                                    height:
                                        14,
                                  ),

                                  // =========================
                                  // TITLE
                                  // =========================

                                  Text(
                                    'PRESENSI',
                                    textAlign:
                                        TextAlign
                                            .center,
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
                                        5,
                                  ),

                                  Text(
                                    'Layar Semesta Studio',
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style:
                                        Theme.of(
                                      context,
                                    )
                                            .textTheme
                                            .titleMedium,
                                  ),

                                  const SizedBox(
                                    height:
                                        10,
                                  ),

                                  Text(
                                    'Masuk menggunakan akun pegawai Anda.',
                                    textAlign:
                                        TextAlign
                                            .center,
                                  ),

                                  const SizedBox(
                                    height:
                                        28,
                                  ),

                                  // =========================
                                  // EMAIL
                                  // =========================

                                  TextFormField(
                                    controller:
                                        _emailController,

                                    focusNode:
                                        _emailFocusNode,

                                    enabled:
                                        !_loading,

                                    validator:
                                        _validateEmail,

                                    keyboardType:
                                        TextInputType
                                            .emailAddress,

                                    textInputAction:
                                        TextInputAction
                                            .next,

                                    autocorrect:
                                        false,

                                    enableSuggestions:
                                        false,

                                    autofillHints:
                                        const [
                                      AutofillHints
                                          .username,
                                      AutofillHints
                                          .email,
                                    ],

                                    scrollPadding:
                                        const EdgeInsets
                                            .only(
                                      bottom:
                                          140,
                                    ),

                                    decoration:
                                        const InputDecoration(
                                      labelText:
                                          'Email',

                                      hintText:
                                          'nama@perusahaan.com',

                                      prefixIcon:
                                          Icon(
                                        Icons
                                            .email_outlined,
                                      ),

                                      border:
                                          OutlineInputBorder(),
                                    ),

                                    onFieldSubmitted:
                                        (_) {
                                      _passwordFocusNode
                                          .requestFocus();
                                    },
                                  ),

                                  const SizedBox(
                                    height:
                                        16,
                                  ),

                                  // =========================
                                  // PASSWORD
                                  // =========================

                                  TextFormField(
                                    controller:
                                        _passwordController,

                                    focusNode:
                                        _passwordFocusNode,

                                    enabled:
                                        !_loading,

                                    validator:
                                        _validatePassword,

                                    obscureText:
                                        _obscurePassword,

                                    keyboardType:
                                        TextInputType
                                            .visiblePassword,

                                    textInputAction:
                                        TextInputAction
                                            .done,

                                    autocorrect:
                                        false,

                                    enableSuggestions:
                                        false,

                                    autofillHints:
                                        const [
                                      AutofillHints
                                          .password,
                                    ],

                                    scrollPadding:
                                        const EdgeInsets
                                            .only(
                                      bottom:
                                          140,
                                    ),

                                    decoration:
                                        InputDecoration(
                                      labelText:
                                          'Password',

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
                                            _loading
                                                ? null
                                                : () {
                                                    setState(
                                                      () {
                                                        _obscurePassword =
                                                            !_obscurePassword;
                                                      },
                                                    );
                                                  },

                                        icon:
                                            Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),

                                    onFieldSubmitted:
                                        (_) {
                                      _login();
                                    },
                                  ),

                                  const SizedBox(
                                    height:
                                        22,
                                  ),

                                  // =========================
                                  // LOGIN
                                  // =========================

                                  SizedBox(
                                    height:
                                        52,

                                    child:
                                        FilledButton.icon(
                                      onPressed:
                                          _loading
                                              ? null
                                              : _login,

                                      icon:
                                          _loading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.login_rounded,
                                                ),

                                      label:
                                          Text(
                                        _loading
                                            ? 'MEMERIKSA AKUN...'
                                            : 'LOGIN',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}