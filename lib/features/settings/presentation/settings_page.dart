import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_state.dart';
import 'package:valorant_store_tracker/features/notifications/data/background_task_manager.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = getIt<SecureStorageService>();
    final bio = await storage.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = bio;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      try {
        final canAuth = await _localAuth.canCheckBiometrics;
        if (!canAuth) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometrics not available on this device'),
              ),
            );
          }
          return;
        }

        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable Biometric Lock',
        );

        if (authenticated) {
          await getIt<SecureStorageService>().setBiometricEnabled(true);
          setState(() => _biometricEnabled = true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Biometric auth failed: $e')),
          );
        }
      }
    } else {
      await getIt<SecureStorageService>().setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await getIt<NotificationService>().requestPermissions();
      if (granted) {
        await BackgroundTaskManager.registerPeriodicStoreCheck();
        setState(() => _notificationsEnabled = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission was denied in system settings'),
            ),
          );
        }
      }
    } else {
      await BackgroundTaskManager.cancelStoreCheck();
      setState(() => _notificationsEnabled = false);
    }
  }

  void _exportWishlist(BuildContext context) async {
    final localStore = getIt<LocalStoreService>();
    final wishlist = await localStore.getWishlist();
    final jsonStr = jsonEncode(wishlist.map((w) => w.toJson()).toList());

    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wishlist JSON copied to clipboard!'),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );
    }
  }

  void _importWishlist(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Import Wishlist JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste your exported wishlist JSON string below:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '[{"uuid": "...", "displayName": "..."}]',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final list = jsonDecode(controller.text) as List<dynamic>;
                final localStore = getIt<LocalStoreService>();
                for (final item in list) {
                  final w = WishlistItem.fromJson(item as Map<String, dynamic>);
                  await localStore.addToWishlist(w);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  context.read<WishlistCubit>().loadWishlist();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Imported ${list.length} skins to wishlist!'),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Invalid JSON format: $e')),
                  );
                }
              }
            },
            child: const Text('IMPORT'),
          ),
        ],
      ),
    );
  }

  void _showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Row(
          children: [
            Icon(Icons.battery_alert_rounded, color: AppTheme.valorantRed),
            SizedBox(width: 8),
            Text('Battery Optimization'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Android OEM battery savers (Xiaomi MIUI, Samsung OneUI, Oppo ColorOS) can silently terminate background checks.',
              style: TextStyle(height: 1.4, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'To ensure alerts trigger right at store reset:\n1. Open Phone Settings → Apps → Valorant Store Tracker\n2. Set Battery Usage to "Unrestricted" / "No Restrictions"\n3. Enable "Autostart" if available on your device.',
              style: TextStyle(
                height: 1.4,
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final session =
                  authState is AuthAuthenticated ? authState.session : null;

              return CustomScrollView(
                slivers: [
                  // ─── Header ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Text(
                        'SETTINGS',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(letterSpacing: 2),
                      ),
                    ),
                  ),

                  // ─── Account Section ────────────────────────
                  SliverToBoxAdapter(
                    child: _SettingsSection(
                      title: 'ACCOUNT',
                      children: [
                        _SettingsTile(
                          icon: Icons.person_rounded,
                          title: 'Riot Account',
                          subtitle: session != null
                              ? session.displayName
                              : 'Not signed in',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.valorantRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              session != null ? 'CONNECTED' : 'SIGN IN',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.valorantRed,
                              ),
                            ),
                          ),
                          onTap: () {
                            if (session == null) {
                              context.pushNamed('login');
                            }
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.public_rounded,
                          title: 'Region / Shard',
                          subtitle: session != null
                              ? '${session.region.toUpperCase()} (${session.shard})'
                              : 'Auto-detect on login',
                        ),
                      ],
                    ),
                  ),

                  // ─── Notifications Section ──────────────────
                  SliverToBoxAdapter(
                    child: _SettingsSection(
                      title: 'NOTIFICATIONS',
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications_rounded,
                          title: 'Store Notifications',
                          subtitle: 'Alert when wishlist skins appear in store',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            activeThumbColor: AppTheme.valorantRed,
                            onChanged: _toggleNotifications,
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.battery_saver_rounded,
                          title: 'Battery Optimization Guide',
                          subtitle: 'Required for reliable background checks',
                          onTap: () => _showBatteryOptimizationDialog(context),
                        ),
                      ],
                    ),
                  ),

                  // ─── Security Section ───────────────────────
                  SliverToBoxAdapter(
                    child: _SettingsSection(
                      title: 'SECURITY',
                      children: [
                        _SettingsTile(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric Lock',
                          subtitle: 'Require fingerprint to unlock app',
                          trailing: Switch(
                            value: _biometricEnabled,
                            activeThumbColor: AppTheme.valorantRed,
                            onChanged: _toggleBiometric,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Data Section ───────────────────────────
                  SliverToBoxAdapter(
                    child: _SettingsSection(
                      title: 'DATA BACKUP',
                      children: [
                        _SettingsTile(
                          icon: Icons.file_upload_rounded,
                          title: 'Export Wishlist',
                          subtitle: 'Copy wishlist JSON to clipboard',
                          onTap: () => _exportWishlist(context),
                        ),
                        _SettingsTile(
                          icon: Icons.file_download_rounded,
                          title: 'Import Wishlist',
                          subtitle: 'Restore wishlist from JSON',
                          onTap: () => _importWishlist(context),
                        ),
                      ],
                    ),
                  ),

                  // ─── About Section ──────────────────────────
                  SliverToBoxAdapter(
                    child: _SettingsSection(
                      title: 'ABOUT & SESSION',
                      children: [
                        const _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Version',
                          subtitle: '1.0.0 (Build 1) — Personal Edition',
                        ),
                        if (session != null)
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            title: 'Sign Out',
                            subtitle: 'Clear all tokens and local session',
                            titleColor: AppTheme.valorantRed,
                            onTap: () async {
                              await context.read<AuthCubit>().logout();
                              if (context.mounted) {
                                context.goNamed('login');
                              }
                            },
                          ),
                      ],
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: titleColor ?? AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
