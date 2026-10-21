// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'StoreCheckerVal';

  @override
  String get navHome => 'HOME';

  @override
  String get navStore => 'STORE';

  @override
  String get navTracker => 'TRACKER';

  @override
  String get navCollection => 'COLLECTION';

  @override
  String get navProfile => 'PROFILE';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get settingsTitle => 'PROFILE & SETTINGS';

  @override
  String get settingsSocialSubtitle => 'Friends & Live Activity Radar';

  @override
  String get settingsSquadTitle => 'Squad & Friends Radar';

  @override
  String get settingsSquadSubtitle =>
      'Track live matches, presence & player banners';

  @override
  String get settingsPreferencesSubtitle => 'Alerts & App Behavior';

  @override
  String get settingsDailyAlertsTitle => 'Daily Store Reset Alerts';

  @override
  String get settingsDailyAlertsSubtitle => 'Get notified when store refreshes';

  @override
  String get settingsNightMarketTitle => 'Night Market Alerts';

  @override
  String get settingsNightMarketSubtitle =>
      'Notify when a wishlist skin hits Night Market';

  @override
  String get settingsAccessoryTitle => 'Accessory Rotation Alerts';

  @override
  String get settingsAccessorySubtitle =>
      'Weekly alert when the Kingdom Credits store rotates';

  @override
  String get settingsChatTitle => 'Chat Message Alerts';

  @override
  String get settingsChatSubtitle =>
      'Notify when a new Riot chat message arrives';

  @override
  String get settingsRulesTitle => 'Store Trigger Rules';

  @override
  String get settingsRulesSubtitle => 'Configure specific skin & price alerts';

  @override
  String get settingsDataSubtitle => 'Backup, Alerts & Pins';

  @override
  String get settingsExportTitle => 'Export Backup JSON';

  @override
  String get settingsExportSubtitle => 'Wishlist, alerts, pins & preferences';

  @override
  String get settingsImportTitle => 'Import Backup JSON';

  @override
  String get settingsImportSubtitle => 'Restore data with merge or replace';

  @override
  String get settingsAccountSubtitle => 'Session & Credentials';

  @override
  String get settingsSignOut => 'SIGN OUT';

  @override
  String get settingsSignOutSubtitle => 'Disconnect Riot Games session';

  @override
  String get settingsFooter => 'STORECHECKERVAL MOBILE';

  @override
  String get settingsVersion =>
      'Version 1.0.0 • Designed for Valorant Competitors';

  @override
  String get settingsNotificationsEnabled =>
      'Notifications enabled for store reset!';

  @override
  String get settingsNotificationsDenied =>
      'Notification permissions denied in OS settings.';

  @override
  String get settingsChooseLanguage => 'Choose language';

  @override
  String get settingsBackupSaved => 'Backup saved successfully.';

  @override
  String settingsBackupFailed(String error) {
    return 'Failed to create backup: $error';
  }

  @override
  String get settingsBackupImportTitle => 'IMPORT BACKUP';

  @override
  String settingsBackupContent(int wishlist, int rules, int friends) {
    return 'Backup contains $wishlist wishlist skins, $rules alert rules, and $friends favorite friends.';
  }

  @override
  String get settingsBackupModeHint =>
      'MERGE adds backup data to your current data. REPLACE deletes your current wishlist, alert rules, and pinned friends, then replaces them with the backup.';

  @override
  String settingsBackupImported(
    String mode,
    int wishlist,
    int rules,
    int friends,
  ) {
    return 'Backup imported ($mode): $wishlist skins, $rules rules, $friends favorite friends.';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Failed to import backup: $error';
  }

  @override
  String get settingsLogoutConfirm =>
      'Are you sure you want to sign out from Riot Games? Your stored session tokens will be cleared.';

  @override
  String get cancel => 'CANCEL';

  @override
  String get merge => 'MERGE';

  @override
  String get replace => 'REPLACE';

  @override
  String get share => 'SHARE';

  @override
  String get preparing => 'PREPARING...';

  @override
  String get shareCard => 'SHARE CARD';

  @override
  String shareFailed(String error) {
    return 'Failed to share card: $error';
  }

  @override
  String get careerLoadMore => 'LOAD MORE MATCHES';

  @override
  String get careerRatingTrend => 'RATING TREND';

  @override
  String get careerKdTrend => 'K/D TREND';

  @override
  String get refreshMatches => 'Refresh Matches';

  @override
  String get shareRankCard => 'Share Rank Card';

  @override
  String get refreshCollection => 'Refresh Collection';

  @override
  String get shareCollection => 'Share Collection';

  @override
  String get shareMatch => 'Share Match';
}
