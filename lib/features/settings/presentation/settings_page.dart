import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/l10n/l10n.dart';
import 'package:valorant_store_tracker/features/notifications/data/background_task_manager.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/widgets/store_alert_sheet.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/features/settings/data/backup_service.dart';
import 'package:valorant_store_tracker/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/vp_chip.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _nightMarketAlertsEnabled = true;
  bool _accessoryAlertsEnabled = true;
  bool _chatAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = getIt<SecureStorageService>();
    final localStore = getIt<LocalStoreService>();
    final notifications = await storage.areNotificationsEnabled();
    final nightMarket = await localStore.areNightMarketAlertsEnabled();
    final accessories = await localStore.areAccessoryAlertsEnabled();
    final chats = await localStore.areChatAlertsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = notifications;
        _nightMarketAlertsEnabled = nightMarket;
        _accessoryAlertsEnabled = accessories;
        _chatAlertsEnabled = chats;
      });
    }
  }

  Future<void> _setNightMarketAlerts(bool value) async {
    await getIt<LocalStoreService>().setNightMarketAlertsEnabled(value);
    if (mounted) setState(() => _nightMarketAlertsEnabled = value);
  }

  Future<void> _setAccessoryAlerts(bool value) async {
    await getIt<LocalStoreService>().setAccessoryAlertsEnabled(value);
    if (mounted) setState(() => _accessoryAlertsEnabled = value);
  }

  Future<void> _setChatAlerts(bool value) async {
    await getIt<LocalStoreService>().setChatAlertsEnabled(value);
    if (value) {
      final puuid = await getIt<SecureStorageService>().getPuuid();
      if (puuid != null && puuid.isNotEmpty) {
        await getIt<LocalStoreService>().setLastNotifiedChatAt(
          puuid,
          DateTime.now(),
        );
      }
      await BackgroundTaskManager.registerPeriodicChatCheck();
    } else {
      await BackgroundTaskManager.cancelChatCheck();
    }
    if (mounted) setState(() => _chatAlertsEnabled = value);
  }

  Future<void> _toggleNotifications(bool value) async {
    final l10n = context.l10n;
    if (value) {
      final granted = await getIt<NotificationService>().requestPermissions();
      if (granted) {
        await getIt<SecureStorageService>().setNotificationsEnabled(true);
        await BackgroundTaskManager.scheduleNextResetCheck();
        await BackgroundTaskManager.registerPeriodicStoreCheck();
        await BackgroundTaskManager.registerPeriodicChatCheck();
        setState(() => _notificationsEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settingsNotificationsEnabled)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settingsNotificationsDenied)),
          );
        }
      }
    } else {
      await getIt<SecureStorageService>().setNotificationsEnabled(false);
      await BackgroundTaskManager.cancelStoreCheck();
      await BackgroundTaskManager.cancelChatCheck();
      setState(() => _notificationsEnabled = false);
    }
  }

  Future<void> _exportBackup() async {
    final l10n = context.l10n;
    try {
      final backup = await getIt<BackupService>().exportBackup();
      final date = DateTime.now().toIso8601String().split('T').first;
      final path = await FilePicker.saveFile(
        dialogTitle: 'Simpan backup Store Checker Val',
        fileName: 'storecheckerval-backup-$date.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(backup),
      );
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsBackupSaved)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat backup: $error')));
    }
  }

  Future<void> _importBackup() async {
    final l10n = context.l10n;
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Pilih file backup Store Checker Val',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      final String raw;
      if (picked.bytes != null) {
        raw = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        raw = await File(picked.path!).readAsString();
      } else {
        throw const BackupFormatException('File backup tidak bisa dibaca.');
      }

      final backupService = getIt<BackupService>();
      final preview = backupService.previewBackup(raw);
      if (!mounted) return;

      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedLg,
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            l10n.settingsBackupImportTitle,
            style: AppTextStyles.h3(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsBackupContent(
                  preview.wishlistCount,
                  preview.alertRuleCount,
                  preview.favoriteFriendCount,
                ),
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.settingsBackupModeHint,
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.cancel,
                style: AppTextStyles.statLabel(color: AppColors.textMuted),
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.merge,
                style: AppTextStyles.statLabel(color: AppColors.cyan),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedMd,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'REPLACE',
                style: AppTextStyles.statValue(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
      if (replace == null || !mounted) return;

      final wishlistCubit = context.read<WishlistCubit>();
      final settingsCubit = context.read<AppSettingsCubit>();
      final imported = await backupService.importBackup(raw, replace: replace);
      await wishlistCubit.loadWishlist();
      await settingsCubit.load();
      await _loadSettings();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.settingsBackupImported(
              replace ? 'replace' : 'merge',
              imported.wishlistCount,
              imported.alertRuleCount,
              imported.favoriteFriendCount,
            ),
          ),
        ),
      );
    } on BackupFormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengimpor backup: $error')));
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = context.l10n;
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
            Text(
              'SIGN OUT',
              style: AppTextStyles.h3(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          l10n.settingsLogoutConfirm,
          style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'CANCEL',
              style: AppTextStyles.statLabel(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'SIGN OUT',
              style: AppTextStyles.statValue(color: Colors.white, fontSize: 13),
            ),
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
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
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
              SectionHeader(
                index: '01',
                title: l10n.settingsLanguage,
                subtitle: l10n.settingsLanguageSubtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingGroup([_buildLanguageTile()]),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                index: '02',
                title: 'SOCIAL & SQUAD',
                subtitle: l10n.settingsSocialSubtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingGroup([
                _buildSettingTile(
                  icon: Icons.people_alt_outlined,
                  title: l10n.settingsSquadTitle,
                  subtitle: l10n.settingsSquadSubtitle,
                  onTap: () => context.push('/social'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                index: '03',
                title: 'PREFERENCES',
                subtitle: l10n.settingsPreferencesSubtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingGroup([
                _buildSettingTile(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.settingsDailyAlertsTitle,
                  subtitle: l10n.settingsDailyAlertsSubtitle,
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: AppColors.accent,
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.local_fire_department_outlined,
                  title: l10n.settingsNightMarketTitle,
                  subtitle: l10n.settingsNightMarketSubtitle,
                  trailing: Switch(
                    value: _nightMarketAlertsEnabled,
                    onChanged: _setNightMarketAlerts,
                    activeColor: AppColors.accent,
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.storefront_outlined,
                  title: l10n.settingsAccessoryTitle,
                  subtitle: l10n.settingsAccessorySubtitle,
                  trailing: Switch(
                    value: _accessoryAlertsEnabled,
                    onChanged: _setAccessoryAlerts,
                    activeColor: AppColors.accent,
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: l10n.settingsChatTitle,
                  subtitle: l10n.settingsChatSubtitle,
                  trailing: Switch(
                    value: _chatAlertsEnabled,
                    onChanged: _setChatAlerts,
                    activeColor: AppColors.accent,
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.settingsRulesTitle,
                  subtitle: l10n.settingsRulesSubtitle,
                  onTap: () => StoreAlertSheet.show(context),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                index: '04',
                title: 'DATA MANAGEMENT',
                subtitle: l10n.settingsDataSubtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingGroup([
                _buildSettingTile(
                  icon: Icons.file_upload_outlined,
                  title: l10n.settingsExportTitle,
                  subtitle: l10n.settingsExportSubtitle,
                  onTap: _exportBackup,
                  trailing: const Icon(
                    Icons.save_alt_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.file_download_outlined,
                  title: l10n.settingsImportTitle,
                  subtitle: l10n.settingsImportSubtitle,
                  onTap: _importBackup,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                index: '05',
                title: 'ACCOUNT ACTIONS',
                subtitle: l10n.settingsAccountSubtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSignOutTile(context),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Text(
                    'STORE CHECKER VAL',
                    style: AppTextStyles.statLabel(color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    'v1.0.0',
                    style: AppTextStyles.statLabel(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Designed for Valorant competitors',
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (context, state) {
        final l10n = context.l10n;
        return _buildSettingTile(
          icon: Icons.translate_rounded,
          title: l10n.settingsLanguage,
          subtitle: _localeLabel(context, state.locale),
          onTap: _chooseLanguage,
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
        );
      },
    );
  }

  String _localeLabel(BuildContext context, Locale? locale) {
    if (locale == null) return context.l10n.languageSystem;
    if (locale.languageCode == 'id') return context.l10n.languageIndonesian;
    return context.l10n.languageEnglish;
  }

  Future<void> _chooseLanguage() async {
    final settingsCubit = context.read<AppSettingsCubit>();
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = ctx.l10n;
        final locale = settingsCubit.state.locale;
        return SimpleDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.roundedLg,
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            l10n.settingsChooseLanguage,
            style: AppTextStyles.h3(color: AppColors.textPrimary),
          ),
          children: [
            _languageOption(
              ctx,
              label: l10n.languageSystem,
              value: 'system',
              selected: locale == null,
            ),
            _languageOption(
              ctx,
              label: l10n.languageEnglish,
              value: 'en',
              selected: locale?.languageCode == 'en',
            ),
            _languageOption(
              ctx,
              label: l10n.languageIndonesian,
              value: 'id',
              selected: locale?.languageCode == 'id',
            ),
          ],
        );
      },
    );
    if (selected == null) return;
    await settingsCubit.setLocale(selected == 'system' ? null : selected);
  }

  Widget _languageOption(
    BuildContext context, {
    required String label,
    required String value,
    required bool selected,
  }) {
    return SimpleDialogOption(
      onPressed: () => Navigator.of(context).pop(value),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            size: 20,
            color: selected ? AppColors.accent : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodyMedium(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final UserProfile? profile = state is ProfileLoaded
            ? state.profile
            : null;

        return DataPanel(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppRadius.roundedSm,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.roundedSm,
                      child: profile?.cardSmallArt != null
                          ? CachedNetworkImage(
                              imageUrl: profile!.cardSmallArt!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.person_outline,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? 'Valorant Agent',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h3(color: AppColors.textPrimary),
                        ),
                        if (profile?.titleText != null)
                          Text(
                            profile!.titleText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(
                              color: AppColors.accentSoft,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${profile?.region.toUpperCase() ?? 'AP'} / '
                    'LVL ${profile?.accountLevel ?? 1}',
                    style: AppTextStyles.statLabel(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  VpChip(
                    amount: profile?.walletAvailable == true
                        ? profile!.valorantPoints
                        : null,
                    fontSize: 11,
                    compact: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  VpChip(
                    amount: profile?.walletAvailable == true
                        ? profile!.radianitePoints
                        : null,
                    isRadianite: true,
                    fontSize: 11,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignOutTile(BuildContext context) {
    return DataPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _confirmLogout(context),
        splashColor: AppColors.lossRed.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.lossRed,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIGN OUT',
                      style: AppTextStyles.statLabel(color: AppColors.lossRed),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Disconnect Riot Games session',
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.lossRed,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingGroup(List<Widget> tiles) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return DataPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            tiles[i],
          ],
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.accent.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(color: AppColors.textMuted),
                  ),
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
