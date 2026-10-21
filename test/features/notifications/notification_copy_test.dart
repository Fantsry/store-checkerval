import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_copy.dart';

void main() {
  group('resolveNotificationLocale', () {
    test('supports Indonesian and English and falls back to English', () {
      expect(resolveNotificationLocale('id'), const Locale('id'));
      expect(resolveNotificationLocale('en'), const Locale('en'));
      expect(resolveNotificationLocale('fr'), const Locale('en'));
      expect(resolveNotificationLocale('  ID  '), const Locale('id'));
    });
  });

  group('NotificationCopy', () {
    test('builds simple Indonesian wishlist and alert copy', () {
      final copy = NotificationCopy.forLanguage('id');

      expect(copy.wishlistTitle(1), 'Skin wishlist ada di store');
      expect(copy.wishlistTitle(3), '3 skin wishlist ada di store');
      expect(
        copy.wishlistBody(['Reaver Vandal']),
        'Reaver Vandal ada di store hari ini.',
      );
      expect(copy.alertTitle(2), '2 skin cocok dengan alert');
      expect(copy.nightMarketTitle(1), 'Night Market sudah buka');
      expect(copy.accessoryTitle, 'Accessory store baru');
      expect(copy.chatTitle('Boaster'), 'Pesan baru dari Boaster');
      expect(copy.testTitle, 'Notifikasi aktif');
    });

    test('builds simple English copy and no exclamation marks', () {
      final copy = NotificationCopy.forLanguage('en');

      expect(copy.wishlistTitle(1), 'Wishlist skin in store');
      expect(copy.wishlistTitle(3), '3 wishlist skins in store');
      expect(
        copy.wishlistBody(['Reaver Vandal']),
        'Reaver Vandal is in your store today.',
      );
      expect(copy.alertTitle(2), '2 skins match your alerts');
      expect(copy.nightMarketTitle(2), '2 matching skins in Night Market');
      expect(copy.accessoryTitle, 'New accessory store');
      expect(copy.chatTitle('Boaster'), 'New message from Boaster');
      expect(copy.testTitle, 'Notifications active');
      expect(copy.testBody, contains('wishlist skin'));
      expect(copy.testBody, isNot(contains('!')));
    });
  });
}
