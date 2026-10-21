import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/settings/data/backup_service.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

class MockLocalStoreService extends Mock implements LocalStoreService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockLocalStoreService localStore;
  late MockSecureStorageService secureStorage;
  late BackupService service;

  final wishlistItem = WishlistItem(
    uuid: 'skin-1',
    displayName: 'Prime Vandal',
    weaponName: 'Vandal',
    cost: 1775,
    tierName: 'Premium',
    addedAt: DateTime(2026, 10, 1),
  );

  const alertRule = StoreAlertRule(
    id: 'rule-1',
    weapon: 'Vandal',
    tiers: ['Premium'],
    customName: 'Prime only',
  );

  final friendJson = jsonEncode({
    'puuid': 'friend-1',
    'gameName': 'Buddy',
    'tagLine': '123',
    'isFavorite': true,
  });

  setUpAll(() {
    registerFallbackValue(wishlistItem);
    registerFallbackValue(alertRule);
  });

  setUp(() {
    localStore = MockLocalStoreService();
    secureStorage = MockSecureStorageService();
    service = BackupService(
      localStore: localStore,
      secureStorage: secureStorage,
    );

    when(() => localStore.getWishlist()).thenAnswer((_) async => [wishlistItem]);
    when(() => localStore.getAlertRules()).thenAnswer((_) async => [alertRule]);
    when(() => localStore.getSavedFriendsJson())
        .thenAnswer((_) async => [friendJson]);
    when(() => localStore.getLocale()).thenAnswer((_) async => 'id');
    when(() => localStore.areNightMarketAlertsEnabled())
        .thenAnswer((_) async => true);
    when(() => localStore.areAccessoryAlertsEnabled())
        .thenAnswer((_) async => false);
    when(() => localStore.areChatAlertsEnabled()).thenAnswer((_) async => true);
    when(() => secureStorage.areNotificationsEnabled())
        .thenAnswer((_) async => true);
  });

  group('BackupService export', () {
    test('exports settings, wishlist, alert rules, and favorite friends',
        () async {
      final raw = await service.exportBackup();
      final payload = jsonDecode(raw) as Map<String, dynamic>;

      expect(payload['schemaVersion'], BackupService.schemaVersion);
      expect(payload['app'], 'StoreCheckerVal');
      expect(payload['settings']['locale'], 'id');
      expect(payload['settings']['accessoryAlertsEnabled'], false);
      expect((payload['wishlist'] as List).length, 1);
      expect((payload['alertRules'] as List).length, 1);
      expect((payload['favoriteFriends'] as List).length, 1);
      expect(
        (payload['favoriteFriends'] as List).first['puuid'],
        'friend-1',
      );
      expect(raw.contains('accessToken'), false);
    });
  });

  group('BackupService import', () {
    test('preview reports counts without writing data', () {
      final raw = jsonEncode({
        'schemaVersion': 1,
        'wishlist': [wishlistItem.toJson()],
        'alertRules': [alertRule.toJson()],
        'favoriteFriends': [
          {'puuid': 'friend-1', 'isFavorite': true},
        ],
      });

      final preview = service.previewBackup(raw);

      expect(preview.wishlistCount, 1);
      expect(preview.alertRuleCount, 1);
      expect(preview.favoriteFriendCount, 1);
      verifyNever(() => localStore.addToWishlist(any()));
    });

    test('merge imports data and settings without clearing existing data',
        () async {
      when(() => localStore.addToWishlist(any())).thenAnswer((_) async {});
      when(() => localStore.saveAlertRule(any())).thenAnswer((_) async {});
      when(() => localStore.saveFriendJson(any(), any()))
          .thenAnswer((_) async {});
      when(() => localStore.setLocale(any())).thenAnswer((_) async {});
      when(() => secureStorage.setNotificationsEnabled(any()))
          .thenAnswer((_) async {});
      when(() => localStore.setNightMarketAlertsEnabled(any()))
          .thenAnswer((_) async {});
      when(() => localStore.setAccessoryAlertsEnabled(any()))
          .thenAnswer((_) async {});
      when(() => localStore.setChatAlertsEnabled(any()))
          .thenAnswer((_) async {});

      final raw = jsonEncode({
        'schemaVersion': 1,
        'settings': {
          'locale': 'en',
          'notificationsEnabled': false,
          'nightMarketAlertsEnabled': false,
          'accessoryAlertsEnabled': true,
          'chatAlertsEnabled': false,
        },
        'wishlist': [wishlistItem.toJson()],
        'alertRules': [alertRule.toJson()],
        'favoriteFriends': [
          {'puuid': 'friend-1', 'isFavorite': true},
        ],
      });

      final result = await service.importBackup(raw);

      expect(result.wishlistCount, 1);
      expect(result.alertRuleCount, 1);
      expect(result.favoriteFriendCount, 1);
      verify(() => localStore.addToWishlist(any())).called(1);
      verify(() => localStore.saveAlertRule(any())).called(1);
      verify(() => localStore.saveFriendJson('friend-1', any())).called(1);
      verify(() => localStore.setLocale('en')).called(1);
      verify(() => secureStorage.setNotificationsEnabled(false)).called(1);
      verifyNever(() => localStore.clearWishlist());
      verifyNever(() => localStore.clearAlertRules());
      verifyNever(() => localStore.clearFavoriteFriendFlags());
    });

    test('replace clears current data before importing', () async {
      when(() => localStore.clearWishlist()).thenAnswer((_) async {});
      when(() => localStore.clearAlertRules()).thenAnswer((_) async {});
      when(() => localStore.clearFavoriteFriendFlags()).thenAnswer((_) async {});
      when(() => localStore.addToWishlist(any())).thenAnswer((_) async {});
      when(() => localStore.saveAlertRule(any())).thenAnswer((_) async {});
      when(() => localStore.saveFriendJson(any(), any()))
          .thenAnswer((_) async {});

      final raw = jsonEncode({
        'schemaVersion': 1,
        'wishlist': [wishlistItem.toJson()],
      });

      await service.importBackup(raw, replace: true);

      verifyInOrder([
        () => localStore.clearWishlist(),
        () => localStore.clearAlertRules(),
        () => localStore.clearFavoriteFriendFlags(),
        () => localStore.addToWishlist(any()),
      ]);
    });

    test('rejects invalid JSON without touching storage', () async {
      expect(
        () => service.previewBackup('not-json'),
        throwsA(isA<BackupFormatException>()),
      );
      verifyNever(() => localStore.addToWishlist(any()));
    });

    test('rejects unsupported schema versions', () {
      expect(
        () => service.previewBackup(jsonEncode({'schemaVersion': 99})),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects incomplete wishlist entries', () {
      expect(
        () => service.previewBackup(
          jsonEncode({
            'schemaVersion': 1,
            'wishlist': [
              {'uuid': '', 'displayName': ''},
            ],
          }),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
