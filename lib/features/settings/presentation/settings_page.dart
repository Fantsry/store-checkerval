import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/notifications/data/background_task_manager.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/widgets/store_alert_sheet.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_badge.dart';
import 'package:valorant_store_tracker/ui/widgets/vp_chip.dart';

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
    final notifications = await storage.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = bio;
        _notificationsEnabled = notifications;
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
              const SnackBar(content: Text('Biometrics not available on this device')),
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
            SnackBar(content: Text('Biometric authentication failed: $e')),
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
        await getIt<SecureStorageService>().setNotificationsEnabled(true);
        await BackgroundTaskManager.scheduleNextResetCheck();
        await BackgroundTaskManager.registerPeriodicStoreCheck();
        setState(() => _notificationsEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications enabled for store reset!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permissions denied in OS settings.')),
          );
        }
      }
    } else {
      await getIt<SecureStorageService>().setNotificationsEnabled(false);
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
        const SnackBar(content: Text('Wishlist JSON copied to clipboard!')),
      );
    }
  }

  void _importWishlist(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedLg,
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('IMPORT WISHLIST', style: AppTextStyles.h3(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your exported wishlist JSON below:',
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLines: 4,
              style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '[{"uuid": "...", "displayName": "..."}]',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: AppTextStyles.statLabel(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
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
                    SnackBar(content: Text('Imported ${list.length} skins to wishlist!')),
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
            child: Text('IMPORT', style: AppTextStyles.statValue(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedLg,
          side: const BorderSide(color: AppColors.red, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.red),
            const SizedBox(width: AppSpacing.sm),
            Text('SIGN OUT', style: AppTextStyles.h3(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out from Riot Games? Your stored session tokens will be cleared.',
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('CANCEL', style: AppTextStyles.statLabel(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('SIGN OUT', style: AppTextStyles.statValue(color: Colors.white, fontSize: 13)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('PROFILE & SETTINGS', style: AppTextStyles.h2(color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlayerCard(),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'SOCIAL & SQUAD', subtitle: 'Friends & Live Activity Radar'),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(
                icon: Icons.people_alt_outlined,
                title: 'Squad & Friends Radar',
                subtitle: 'Track live matches, presence & player banners',
                onTap: () => context.push('/social'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.cyan),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'PREFERENCES', subtitle: 'Alerts & App Behavior'),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Daily Store Reset Alerts',
                subtitle: 'Get notified when store refreshes',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: AppColors.red,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildSettingTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric App Lock',
                subtitle: 'Require Face ID / Fingerprint on launch',
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                  activeColor: AppColors.cyan,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildSettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'Store Trigger Rules',
                subtitle: 'Configure specific skin & price alerts',
                onTap: () => StoreAlertSheet.show(context),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'DATA MANAGEMENT', subtitle: 'Wishlist & Backup'),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(
                icon: Icons.file_upload_outlined,
                title: 'Export Wishlist JSON',
                subtitle: 'Copy wishlist skins to clipboard',
                onTap: () => _exportWishlist(context),
                trailing: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildSettingTile(
                icon: Icons.file_download_outlined,
                title: 'Import Wishlist JSON',
                subtitle: 'Restore wishlist from JSON payload',
                onTap: () => _importWishlist(context),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'ACCOUNT ACTIONS', subtitle: 'Session & Credentials'),
              const SizedBox(height: AppSpacing.sm),
              AscendCard(
                onTap: () => _confirmLogout(context),
                borderColor: AppColors.red.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SIGN OUT', style: AppTextStyles.h4(color: AppColors.red)),
                          const SizedBox(height: 2),
                          Text(
                            'Disconnect Riot Games session',
                            style: AppTextStyles.caption(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.red),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Column(
                  children: [
                    Text(
                      'STORECHECKERVAL MOBILE',
                      style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0 • Designed for Valorant Competitors',
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final UserProfile? profile = state is ProfileLoaded ? state.profile : null;

        return AscendCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppRadius.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (profile?.cardSmallArt != null)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.roundedMd,
                        child: CachedNetworkImage(
                          imageUrl: profile!.cardSmallArt!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName.toUpperCase() ?? 'VALORANT AGENT',
                          style: AppTextStyles.h3(color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (profile?.titleText != null)
                          Text(
                            profile!.titleText!.toUpperCase(),
                            style: AppTextStyles.caption(color: AppColors.cyan),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatBadge(
                        text: profile?.region.toUpperCase() ?? 'AP',
                        color: AppColors.cyan,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LVL ${profile?.accountLevel ?? 1}',
                        style: AppTextStyles.statLabel(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  VpChip(amount: profile?.walletAvailable == true ? profile!.valorantPoints : null, fontSize: 13),
                  VpChip(amount: profile?.walletAvailable == true ? profile!.radianitePoints : null, isRadianite: true, fontSize: 13),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AscendCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.roundedSm,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium(color: AppColors.textPrimary)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: AppTextStyles.caption(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
