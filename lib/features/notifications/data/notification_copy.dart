import 'dart:ui';

import 'package:valorant_store_tracker/l10n/l10n.dart';

Locale resolveNotificationLocale(String? languageCode) {
  final normalized = languageCode?.trim().toLowerCase();
  final code = normalized == null || normalized.isEmpty
      ? PlatformDispatcher.instance.locale.languageCode.toLowerCase()
      : normalized;
  return Locale(code == 'id' ? 'id' : 'en');
}

class NotificationCopy {
  final AppLocalizations l10n;

  const NotificationCopy(this.l10n);

  factory NotificationCopy.forLanguage(String? languageCode) {
    return NotificationCopy(
      lookupAppLocalizations(resolveNotificationLocale(languageCode)),
    );
  }

  String wishlistTitle(int count) => count == 1
      ? l10n.notificationWishlistTitleOne
      : l10n.notificationWishlistTitleMany(count);

  String wishlistBody(List<String> names) => names.length == 1
      ? l10n.notificationWishlistBodyOne(names.first)
      : l10n.notificationWishlistBodyMany(names.join(', '));

  String get wishlistTicker => l10n.notificationWishlistTicker;

  String get wishlistSummary => l10n.notificationWishlistSummary;

  String alertTitle(int count) => count == 1
      ? l10n.notificationAlertTitleOne
      : l10n.notificationAlertTitleMany(count);

  String get alertTicker => l10n.notificationAlertTicker;

  String get alertSummary => l10n.notificationAlertSummary;

  String nightMarketTitle(int count) => count == 1
      ? l10n.notificationNightMarketTitleOne
      : l10n.notificationNightMarketTitleMany(count);

  String get nightMarketSummary => l10n.notificationNightMarketSummary;

  String get accessoryTitle => l10n.notificationAccessoryTitle;

  String accessoryMore(int count) => l10n.notificationAccessoryMore(count);

  String get accessorySummary => l10n.notificationAccessorySummary;

  String chatTitle(String sender) => l10n.notificationChatTitle(sender);

  String get chatSummary => l10n.notificationChatSummary;

  String get testTitle => l10n.notificationTestTitle;

  String get testBody => l10n.notificationTestBody;
}
