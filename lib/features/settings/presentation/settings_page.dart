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
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_state.dart';
import 'package:valorant_store_tracker/features/notifications/data/background_task_manager.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/cubit/store_alert_cubit.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/cubit/store_alert_state.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/widgets/store_alert_sheet.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/widgets/profile_card.dart';
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
        await BackgroundTaskManager.scheduleNextResetCheck();
        await BackgroundTaskManager.registerPeriodicStoreCheck();
        setState(() => _notificationsEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notifikasi aktif! Pengingat otomatis saat toko reset jam 07:00 WIB.'),
              backgroundColor: AppTheme.surfaceLight,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin notifikasi ditolak di pengaturan HP kamu.'),
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
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        title: const Text(
          'Import Wishlist JSON',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
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
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                hintText: '[{"uuid": "...", "displayName": "..."}]',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.accentMagenta),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMagenta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
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
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.battery_alert_rounded, color: AppTheme.accentMagenta),
            SizedBox(width: 8),
            Text(
              'Battery Optimization',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMagenta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: AppTheme.accentMagenta.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.accentMagenta),
            SizedBox(width: 8),
            Text(
              'Logout Akun',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin logout dari akun Riot ini? Sesi login dan token akan dibersihkan.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'BATAL',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMagenta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await context.read<AuthCubit>().logout();
      if (context.mounted) {
        context.read<ProfileCubit>().clearProfile();
        context.goNamed('login');
      }
    }
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
                  authState is AuthAuthenticated ? authState.session : null;              return RefreshIndicator(
                color: AppTheme.accentMagenta,
                backgroundColor: AppTheme.surfaceDark,
                onRefresh: () async {
                  await Future.wait([
                    context.read<ProfileCubit>().loadProfile(forceRefresh: true),
                    context.read<AuthCubit>().checkAuthStatus(),
                  ]);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ─── Header ─────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 38,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentMagenta,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SETTINGS',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        letterSpacing: 2.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'PROFILE & APP CONFIGURATION',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    letterSpacing: 0.8,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─── Player Profile Card ────────────────────
                    const SliverToBoxAdapter(
                      child: ProfileCard(),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 8),
                    ),

                    // ─── Companion Hub Section ───────────────────
                    SliverToBoxAdapter(
                      child: _SettingsSection(
                        title: 'COMPANION HUB',
                        children: [
                          _SettingsTile(
                            icon: Icons.inventory_2_rounded,
                            title: 'Inventory & Account Value',
                            subtitle: 'Kalkulator total VP & estimasi Rupiah akun',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onTap: () => context.pushNamed('inventory'),
                          ),
                          _SettingsTile(
                            icon: Icons.military_tech_rounded,
                            title: 'Battlepass & Missions Tracker',
                            subtitle: 'Progress Act tier & misi harian / mingguan',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onTap: () => context.pushNamed('battlepass'),
                          ),
                          _SettingsTile(
                            icon: Icons.radar_rounded,
                            title: 'Live Match Lobby Radar',
                            subtitle: 'Cek rank & peak rank teman / musuh realtime',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onTap: () => context.pushNamed('liveMatch'),
                          ),
                          _SettingsTile(
                            icon: Icons.favorite_rounded,
                            title: 'Wishlist & Skin Catalog',
                            subtitle: 'Kelola wishlist skin impian & katalog lengkap',
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onTap: () => context.pushNamed('wishlist'),
                          ),
                        ],
                      ),
                    ),

                    // ─── Account Section ────────────────────────
                    SliverToBoxAdapter(
                      child: _SettingsSection(
                        title: 'ACCOUNT DETAILS',
                      children: [
                        _SettingsTile(
                          icon: Icons.person_rounded,
                          title: 'Riot Account',
                          subtitle: session != null
                              ? session.displayName
                              : 'Not signed in',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentMagenta.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.accentMagenta.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              session != null ? 'CONNECTED' : 'SIGN IN',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppTheme.accentMagenta,
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
                        if (session != null)
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            title: 'Logout Akun Riot',
                            subtitle: 'Keluar dan bersihkan sesi login',
                            titleColor: AppTheme.accentMagenta,
                            onTap: () => _confirmLogout(context),
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
                          title: 'Store Wishlist Alerts',
                          subtitle: 'Notifikasi saat skin wishlist ada di store',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            activeThumbColor: AppTheme.accentMagenta,
                            activeTrackColor: AppTheme.accentMagenta.withValues(alpha: 0.3),
                            onChanged: _toggleNotifications,
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.tune_rounded,
                          title: 'Aturan Notifikasi Skin (Custom Alerts)',
                          subtitle: 'Notifikasi Melee, Vandal, Ghost, dll.',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onTap: () => StoreAlertSheet.show(context),
                        ),
                        BlocBuilder<StoreAlertCubit, StoreAlertState>(
                          builder: (context, state) {
                            if (state is StoreAlertLoaded) {
                              final activeRules =
                                  state.rules.where((r) => r.isEnabled).toList();
                              if (activeRules.isNotEmpty) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: activeRules.map((rule) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceDark,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: AppTheme.accentMagenta
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Text(
                                          rule.displayName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.schedule_rounded,
                          title:
                              'Reset Toko: ${TimezoneHelper.formatDuration(TimezoneHelper.timeUntilReset)} lagi',
                          subtitle:
                              'Pemeriksaan background dijadwalkan otomatis setiap reset (00:00 UTC / 07:00 WIB)',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Pengecekan toko berjalan otomatis di background setiap 00:00 UTC (07:00 WIB) & berkala setiap 1 jam.'),
                                backgroundColor: AppTheme.surfaceLight,
                              ),
                            );
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.sync_rounded,
                          title: 'Uji Background Worker Sekarang',
                          subtitle:
                              'Jalankan evaluasi store sekarang & kirim notifikasi jika cocok',
                          onTap: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Menjalankan background store check...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            try {
                              final success = await BackgroundTaskManager
                                  .triggerImmediateBackgroundCheck();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Pengecekan beres! Jika ada skin incaran, akan langsung diberitahukan.'
                                          : 'Pemeriksaan selesai, tapi pastikan kamu sudah login.',
                                    ),
                                    backgroundColor: success
                                        ? const Color(0xFF00C4A8)
                                        : AppTheme.surfaceLight,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Gagal cek toko background: $e'),
                                    backgroundColor: AppTheme.valorantRed,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.send_rounded,
                          title: 'Tes Kirim Notifikasi',
                          subtitle:
                              'Uji suara, banner, & getaran di HP kamu',
                          onTap: () async {
                            await getIt<NotificationService>()
                                .showTestNotification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Notifikasi tes meluncur! Silakan periksa bilah notifikasi HP kamu.'),
                                  backgroundColor: AppTheme.surfaceLight,
                                ),
                              );
                            }
                          },
                        ),
                        _SettingsTile(
                          icon: Icons.battery_saver_rounded,
                          title: 'Battery Optimization Guide',
                          subtitle:
                              'Panduan agar background check tidak dibunuh sistem',
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
                            activeThumbColor: AppTheme.accentMagenta,
                            activeTrackColor: AppTheme.accentMagenta.withValues(alpha: 0.3),
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
                            titleColor: AppTheme.accentMagenta,
                            onTap: () => _confirmLogout(context),
                          ),
                      ],
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
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
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (titleColor ?? AppTheme.accentMagenta).withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: titleColor ?? AppTheme.accentMagenta,
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
