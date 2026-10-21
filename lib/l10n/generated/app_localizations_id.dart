// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'StoreCheckerVal';

  @override
  String get navHome => 'BERANDA';

  @override
  String get navStore => 'TOKO';

  @override
  String get navTracker => 'TRACKER';

  @override
  String get navCollection => 'KOLEKSI';

  @override
  String get navProfile => 'PROFIL';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get languageSystem => 'Ikuti sistem';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get settingsLanguageSubtitle => 'Pilih bahasa aplikasi';

  @override
  String get settingsTitle => 'PROFIL & PENGATURAN';

  @override
  String get settingsSocialSubtitle => 'Teman & Radar Aktivitas Live';

  @override
  String get settingsSquadTitle => 'Radar Squad & Teman';

  @override
  String get settingsSquadSubtitle =>
      'Pantau match live, status & banner pemain';

  @override
  String get settingsPreferencesSubtitle => 'Notifikasi & Perilaku Aplikasi';

  @override
  String get settingsDailyAlertsTitle => 'Notifikasi Reset Store Harian';

  @override
  String get settingsDailyAlertsSubtitle =>
      'Dapatkan notifikasi saat store berganti';

  @override
  String get settingsNightMarketTitle => 'Notifikasi Night Market';

  @override
  String get settingsNightMarketSubtitle =>
      'Beri tahu saat skin wishlist muncul di Night Market';

  @override
  String get settingsAccessoryTitle => 'Notifikasi Rotasi Aksesori';

  @override
  String get settingsAccessorySubtitle =>
      'Notifikasi mingguan saat store Kingdom Credits berganti';

  @override
  String get settingsChatTitle => 'Notifikasi Pesan Chat';

  @override
  String get settingsChatSubtitle =>
      'Beri tahu saat pesan chat Riot baru masuk';

  @override
  String get settingsRulesTitle => 'Aturan Pemicu Store';

  @override
  String get settingsRulesSubtitle => 'Atur alert skin & harga tertentu';

  @override
  String get settingsDataSubtitle => 'Backup, Alert & Pin';

  @override
  String get settingsExportTitle => 'Ekspor Backup JSON';

  @override
  String get settingsExportSubtitle => 'Wishlist, alert, pin & preferensi';

  @override
  String get settingsImportTitle => 'Impor Backup JSON';

  @override
  String get settingsImportSubtitle =>
      'Pulihkan data dengan merge atau replace';

  @override
  String get settingsAccountSubtitle => 'Sesi & Kredensial';

  @override
  String get settingsSignOut => 'KELUAR';

  @override
  String get settingsSignOutSubtitle => 'Putuskan sesi Riot Games';

  @override
  String get settingsFooter => 'STORECHECKERVAL MOBILE';

  @override
  String get settingsVersion =>
      'Versi 1.0.0 • Dirancang untuk Kompetitor Valorant';

  @override
  String get settingsNotificationsEnabled =>
      'Notifikasi reset store diaktifkan!';

  @override
  String get settingsNotificationsDenied =>
      'Izin notifikasi ditolak di pengaturan OS.';

  @override
  String get settingsChooseLanguage => 'Pilih bahasa';

  @override
  String get settingsBackupSaved => 'Backup berhasil disimpan.';

  @override
  String settingsBackupFailed(String error) {
    return 'Gagal membuat backup: $error';
  }

  @override
  String get settingsBackupImportTitle => 'IMPOR BACKUP';

  @override
  String settingsBackupContent(int wishlist, int rules, int friends) {
    return 'Backup berisi $wishlist skin wishlist, $rules aturan alert, dan $friends teman favorit.';
  }

  @override
  String get settingsBackupModeHint =>
      'MERGE menambahkan data backup ke data saat ini. REPLACE menghapus wishlist, aturan alert, dan pin teman yang ada lalu menggantinya dengan isi backup.';

  @override
  String settingsBackupImported(
    String mode,
    int wishlist,
    int rules,
    int friends,
  ) {
    return 'Backup diimpor ($mode): $wishlist skin, $rules aturan, $friends teman favorit.';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Gagal mengimpor backup: $error';
  }

  @override
  String get settingsLogoutConfirm =>
      'Yakin ingin keluar dari Riot Games? Token sesi yang tersimpan akan dihapus.';

  @override
  String get cancel => 'BATAL';

  @override
  String get merge => 'MERGE';

  @override
  String get replace => 'REPLACE';

  @override
  String get share => 'BAGIKAN';

  @override
  String get preparing => 'MENYIAPKAN...';

  @override
  String get shareCard => 'KARTU BAGIKAN';

  @override
  String shareFailed(String error) {
    return 'Gagal membagikan kartu: $error';
  }

  @override
  String get careerLoadMore => 'MUAT MATCH LAINNYA';

  @override
  String get careerRatingTrend => 'TREN RATING';

  @override
  String get careerKdTrend => 'TREN K/D';

  @override
  String get refreshMatches => 'Muat Ulang Match';

  @override
  String get shareRankCard => 'Bagikan Kartu Rank';

  @override
  String get refreshCollection => 'Muat Ulang Koleksi';

  @override
  String get shareCollection => 'Bagikan Koleksi';

  @override
  String get shareMatch => 'Bagikan Match';

  @override
  String get wishlistAdd => 'TAMBAH KE WISHLIST';

  @override
  String get wishlistAdded => 'SUDAH DI WISHLIST';

  @override
  String get notificationWishlistTitleOne => 'Skin wishlist ada di store';

  @override
  String notificationWishlistTitleMany(int count) {
    return '$count skin wishlist ada di store';
  }

  @override
  String notificationWishlistBodyOne(String name) {
    return '$name ada di store hari ini.';
  }

  @override
  String notificationWishlistBodyMany(String names) {
    return '$names ada di store hari ini.';
  }

  @override
  String get notificationWishlistTicker => 'Skin wishlist';

  @override
  String get notificationWishlistSummary => 'Toko harian';

  @override
  String get notificationAlertTitleOne => '1 skin cocok dengan alert';

  @override
  String notificationAlertTitleMany(int count) {
    return '$count skin cocok dengan alert';
  }

  @override
  String get notificationAlertTicker => 'Alert skin';

  @override
  String get notificationAlertSummary => 'Aturan alert';

  @override
  String get notificationNightMarketTitleOne => 'Night Market sudah buka';

  @override
  String notificationNightMarketTitleMany(int count) {
    return '$count skin cocok di Night Market';
  }

  @override
  String get notificationNightMarketSummary => 'Night Market';

  @override
  String get notificationAccessoryTitle => 'Accessory store baru';

  @override
  String notificationAccessoryMore(int count) {
    return '+$count lainnya';
  }

  @override
  String get notificationAccessorySummary => 'Accessory store';

  @override
  String notificationChatTitle(String sender) {
    return 'Pesan baru dari $sender';
  }

  @override
  String get notificationChatSummary => 'Chat Riot';

  @override
  String get notificationTestTitle => 'Notifikasi aktif';

  @override
  String get notificationTestBody =>
      'Kamu akan dapat notifikasi saat skin wishlist muncul di store.';
}
