import 'package:flutter/material.dart';

import '../models/logged_in_user.dart';
import '../services/auth_service.dart';

class CurrentUserHeader extends StatefulWidget {
  const CurrentUserHeader({
    super.key,
  });

  @override
  State<CurrentUserHeader> createState() =>
      _CurrentUserHeaderState();
}

class _CurrentUserHeaderState
    extends State<CurrentUserHeader> {
  final AuthService _authService = AuthService();

  late Future<LoggedInUser?> _userFuture;

  @override
  void initState() {
    super.initState();

    _userFuture =
        _authService.getCurrentUserProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _userFuture =
          _authService.getCurrentUserProfile();
    });
  }

  String _getInitial(
    String name,
  ) {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return '?';
    }

    return cleanName
        .substring(0, 1)
        .toUpperCase();
  }

  String _roleLabel(
    String role,
  ) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';

      case 'user':
        return 'Pegawai';

      default:
        return role;
    }
  }

  IconData _roleIcon(
    String role,
  ) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;

      case 'user':
        return Icons.badge_rounded;

      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return FutureBuilder<LoggedInUser?>(
      future: _userFuture,
      builder: (
        context,
        snapshot,
      ) {
        // ===================================================
        // LOADING
        // ===================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(
                    alpha: 0.4,
                  ),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(
                  width: 14,
                ),
                Text(
                  'Memuat profil...',
                ),
              ],
            ),
          );
        }

        // ===================================================
        // ERROR
        // ===================================================

        if (snapshot.hasError) {
          return _buildErrorCard(
            context,
            message:
                'Gagal mengambil profil pengguna.',
          );
        }

        final user = snapshot.data;

        // ===================================================
        // USER NOT FOUND
        // ===================================================

        if (user == null) {
          return _buildErrorCard(
            context,
            message:
                'Data pengguna tidak ditemukan.',
          );
        }

        // ===================================================
        // USER FOUND
        // ===================================================

        return _buildUserCard(
          context,
          user,
        );
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    LoggedInUser user,
  ) {
    final theme =
        Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final isAdmin =
        user.isAdmin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer
            .withValues(
          alpha: 0.35,
        ),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.primary
              .withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final isMobile =
              constraints.maxWidth < 500;

          if (isMobile) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildIdentity(
                  context,
                  user,
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildRoleBadge(
                  context,
                  user,
                  isAdmin,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildIdentity(
                  context,
                  user,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              _buildRoleBadge(
                context,
                user,
                isAdmin,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdentity(
    BuildContext context,
    LoggedInUser user,
  ) {
    final theme =
        Theme.of(context);

    return Row(
      children: [
        // ===================================================
        // AVATAR
        // ===================================================

        CircleAvatar(
          radius: 28,
          backgroundColor:
              theme.colorScheme.primary,
          foregroundColor:
              theme.colorScheme.onPrimary,
          child: Text(
            _getInitial(
              user.nama,
            ),
            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        // ===================================================
        // USER INFORMATION
        // ===================================================

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang,',
                style:
                    theme.textTheme.bodySmall
                        ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                user.nama,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    theme.textTheme.titleLarge
                        ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 15,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Expanded(
                    child: Text(
                      user.email,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(
    BuildContext context,
    LoggedInUser user,
    bool isAdmin,
  ) {
    final theme =
        Theme.of(context);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isAdmin
            ? theme.colorScheme.primary
            : theme.colorScheme
                .secondaryContainer,
        borderRadius:
            BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            _roleIcon(
              user.role,
            ),
            size: 18,
            color: isAdmin
                ? theme
                    .colorScheme
                    .onPrimary
                : theme
                    .colorScheme
                    .onSecondaryContainer,
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            _roleLabel(
              user.role,
            ),
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
              color: isAdmin
                  ? theme
                      .colorScheme
                      .onPrimary
                  : theme
                      .colorScheme
                      .onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context, {
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              message,
            ),
          ),

          IconButton(
            tooltip:
                'Muat ulang profil',
            onPressed:
                _refreshProfile,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }
}