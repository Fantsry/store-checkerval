import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'StoreCheckerVal'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get navHome;

  /// No description provided for @navStore.
  ///
  /// In en, this message translates to:
  /// **'STORE'**
  String get navStore;

  /// No description provided for @navTracker.
  ///
  /// In en, this message translates to:
  /// **'TRACKER'**
  String get navTracker;

  /// No description provided for @navCollection.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION'**
  String get navCollection;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get navProfile;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'PROFILE & SETTINGS'**
  String get settingsTitle;

  /// No description provided for @settingsSocialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friends & Live Activity Radar'**
  String get settingsSocialSubtitle;

  /// No description provided for @settingsSquadTitle.
  ///
  /// In en, this message translates to:
  /// **'Squad & Friends Radar'**
  String get settingsSquadTitle;

  /// No description provided for @settingsSquadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track live matches, presence & player banners'**
  String get settingsSquadSubtitle;

  /// No description provided for @settingsPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts & App Behavior'**
  String get settingsPreferencesSubtitle;

  /// No description provided for @settingsDailyAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Store Reset Alerts'**
  String get settingsDailyAlertsTitle;

  /// No description provided for @settingsDailyAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when store refreshes'**
  String get settingsDailyAlertsSubtitle;

  /// No description provided for @settingsNightMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Night Market Alerts'**
  String get settingsNightMarketTitle;

  /// No description provided for @settingsNightMarketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when a wishlist skin hits Night Market'**
  String get settingsNightMarketSubtitle;

  /// No description provided for @settingsAccessoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessory Rotation Alerts'**
  String get settingsAccessoryTitle;

  /// No description provided for @settingsAccessorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly alert when the Kingdom Credits store rotates'**
  String get settingsAccessorySubtitle;

  /// No description provided for @settingsChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Message Alerts'**
  String get settingsChatTitle;

  /// No description provided for @settingsChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when a new Riot chat message arrives'**
  String get settingsChatSubtitle;

  /// No description provided for @settingsRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Trigger Rules'**
  String get settingsRulesTitle;

  /// No description provided for @settingsRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure specific skin & price alerts'**
  String get settingsRulesSubtitle;

  /// No description provided for @settingsDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup, Alerts & Pins'**
  String get settingsDataSubtitle;

  /// No description provided for @settingsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Backup JSON'**
  String get settingsExportTitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wishlist, alerts, pins & preferences'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Backup JSON'**
  String get settingsImportTitle;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore data with merge or replace'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Session & Credentials'**
  String get settingsAccountSubtitle;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Riot Games session'**
  String get settingsSignOutSubtitle;

  /// No description provided for @settingsFooter.
  ///
  /// In en, this message translates to:
  /// **'STORECHECKERVAL MOBILE'**
  String get settingsFooter;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0 • Designed for Valorant Competitors'**
  String get settingsVersion;

  /// No description provided for @settingsNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled for store reset!'**
  String get settingsNotificationsEnabled;

  /// No description provided for @settingsNotificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permissions denied in OS settings.'**
  String get settingsNotificationsDenied;

  /// No description provided for @settingsChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get settingsChooseLanguage;

  /// No description provided for @settingsBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved successfully.'**
  String get settingsBackupSaved;

  /// No description provided for @settingsBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup: {error}'**
  String settingsBackupFailed(String error);

  /// No description provided for @settingsBackupImportTitle.
  ///
  /// In en, this message translates to:
  /// **'IMPORT BACKUP'**
  String get settingsBackupImportTitle;

  /// No description provided for @settingsBackupContent.
  ///
  /// In en, this message translates to:
  /// **'Backup contains {wishlist} wishlist skins, {rules} alert rules, and {friends} favorite friends.'**
  String settingsBackupContent(int wishlist, int rules, int friends);

  /// No description provided for @settingsBackupModeHint.
  ///
  /// In en, this message translates to:
  /// **'MERGE adds backup data to your current data. REPLACE deletes your current wishlist, alert rules, and pinned friends, then replaces them with the backup.'**
  String get settingsBackupModeHint;

  /// No description provided for @settingsBackupImported.
  ///
  /// In en, this message translates to:
  /// **'Backup imported ({mode}): {wishlist} skins, {rules} rules, {friends} favorite friends.'**
  String settingsBackupImported(
    String mode,
    int wishlist,
    int rules,
    int friends,
  );

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup: {error}'**
  String settingsImportFailed(String error);

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out from Riot Games? Your stored session tokens will be cleared.'**
  String get settingsLogoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'MERGE'**
  String get merge;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'REPLACE'**
  String get replace;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get share;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'PREPARING...'**
  String get preparing;

  /// No description provided for @shareCard.
  ///
  /// In en, this message translates to:
  /// **'SHARE CARD'**
  String get shareCard;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share card: {error}'**
  String shareFailed(String error);

  /// No description provided for @careerLoadMore.
  ///
  /// In en, this message translates to:
  /// **'LOAD MORE MATCHES'**
  String get careerLoadMore;

  /// No description provided for @careerRatingTrend.
  ///
  /// In en, this message translates to:
  /// **'RATING TREND'**
  String get careerRatingTrend;

  /// No description provided for @careerKdTrend.
  ///
  /// In en, this message translates to:
  /// **'K/D TREND'**
  String get careerKdTrend;

  /// No description provided for @refreshMatches.
  ///
  /// In en, this message translates to:
  /// **'Refresh Matches'**
  String get refreshMatches;

  /// No description provided for @shareRankCard.
  ///
  /// In en, this message translates to:
  /// **'Share Rank Card'**
  String get shareRankCard;

  /// No description provided for @refreshCollection.
  ///
  /// In en, this message translates to:
  /// **'Refresh Collection'**
  String get refreshCollection;

  /// No description provided for @shareCollection.
  ///
  /// In en, this message translates to:
  /// **'Share Collection'**
  String get shareCollection;

  /// No description provided for @shareMatch.
  ///
  /// In en, this message translates to:
  /// **'Share Match'**
  String get shareMatch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
