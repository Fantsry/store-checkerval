import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/notifications/data/background_task_manager.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

class MockLocalStoreService extends Mock implements LocalStoreService {}

class FakeNotificationService extends NotificationService {
  final List<List<String>> wishlistMatchesNotified = [];
  final List<Map<String, List<String>>> customAlertsNotified = [];
  final List<List<NightMarketItem>> nightMarketNotified = [];
  final List<List<AccessoryStoreItem>> accessoryNotified = [];
  String? lastWishlistLanguageCode;

  @override
  Future<void> showWishlistMatchNotification({
    required List<String> matchedSkinNames,
    String? skinUuid,
    String? languageCode,
  }) async {
    wishlistMatchesNotified.add(matchedSkinNames);
    lastWishlistLanguageCode = languageCode;
  }

  @override
  Future<void> showCustomAlertNotification({
    required Map<String, List<String>> ruleMatches,
    String? languageCode,
  }) async {
    customAlertsNotified.add(ruleMatches);
  }

  @override
  Future<void> showNightMarketNotification({
    required List<NightMarketItem> matches,
    String? languageCode,
  }) async {
    nightMarketNotified.add(matches);
  }

  @override
  Future<void> showAccessoryNotification({
    required List<AccessoryStoreItem> items,
    String? languageCode,
  }) async {
    accessoryNotified.add(items);
  }
}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('TimezoneHelper Tests', () {
    test(
      'formatDuration formats hours, minutes, seconds with zero padding',
      () {
        const duration = Duration(hours: 5, minutes: 7, seconds: 9);
        expect(TimezoneHelper.formatDuration(duration), '05:07:09');

        const durationZero = Duration.zero;
        expect(TimezoneHelper.formatDuration(durationZero), '00:00:00');
      },
    );

    test('nextStoreReset calculates 00:00 UTC correctly in the future', () {
      final reset = TimezoneHelper.nextStoreReset;
      final now = DateTime.now().toUtc();
      final resetUtc = reset.toUtc();

      expect(resetUtc.hour, 0);
      expect(resetUtc.minute, 0);
      expect(resetUtc.second, 0);
      expect(resetUtc.isAfter(now), true);

      final diff = TimezoneHelper.timeUntilReset;
      expect(diff.isNegative, false);
      expect(diff.inHours, lessThanOrEqualTo(24));
    });

    test(
      'formatWeeklyDuration formats days, hours, minutes, seconds properly',
      () {
        const durationMultiDay = Duration(
          days: 3,
          hours: 14,
          minutes: 25,
          seconds: 8,
        );
        expect(
          TimezoneHelper.formatWeeklyDuration(durationMultiDay),
          '3d 14:25:08',
        );

        const durationSingleDay = Duration(hours: 18, minutes: 5, seconds: 2);
        expect(
          TimezoneHelper.formatWeeklyDuration(durationSingleDay),
          '18:05:02',
        );

        expect(TimezoneHelper.formatWeeklyDuration(Duration.zero), '00:00:00');
      },
    );

    test(
      'nextAccessoryStoreReset calculates Wednesday 00:00 UTC correctly in the future',
      () {
        final reset = TimezoneHelper.nextAccessoryStoreReset;
        final now = DateTime.now().toUtc();
        final resetUtc = reset.toUtc();

        expect(resetUtc.weekday, DateTime.wednesday);
        expect(resetUtc.hour, 0);
        expect(resetUtc.minute, 0);
        expect(resetUtc.second, 0);
        expect(resetUtc.isAfter(now), true);

        final diff = TimezoneHelper.timeUntilAccessoryReset;
        expect(diff.isNegative, false);
        expect(diff.inDays, lessThanOrEqualTo(7));
      },
    );
  });

  group('BackgroundTaskManager JWT Expiry Tests', () {
    String jwtWithExp(DateTime expiry) {
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({'exp': expiry.millisecondsSinceEpoch ~/ 1000}),
            ),
          )
          .replaceAll('=', '');
      return 'header.$payload.signature';
    }

    test('detects expired and soon-to-expire access tokens', () {
      final now = DateTime.utc(2026, 10, 23, 12);

      expect(
        BackgroundTaskManager.isJwtExpiringSoon(
          jwtWithExp(now.subtract(const Duration(minutes: 1))),
          now: now,
        ),
        isTrue,
      );
      expect(
        BackgroundTaskManager.isJwtExpiringSoon(
          jwtWithExp(now.add(const Duration(minutes: 2))),
          now: now,
        ),
        isTrue,
      );
      expect(
        BackgroundTaskManager.isJwtExpiringSoon(
          jwtWithExp(now.add(const Duration(hours: 1))),
          now: now,
        ),
        isFalse,
      );
    });

    test('treats malformed tokens as usable so callers can try them', () {
      expect(BackgroundTaskManager.isJwtExpiringSoon('not-a-jwt'), isFalse);
    });
  });

  group('BackgroundTaskManager Expedited Scheduling Tests', () {
    test('enables expedited reset work only on Android 12+', () {
      expect(
        BackgroundTaskManager.supportsExpeditedWorkFromVersion(
          'Android 11 (API 30)',
        ),
        isFalse,
      );
      expect(
        BackgroundTaskManager.supportsExpeditedWorkFromVersion(
          'Android 12 (API 31)',
        ),
        isTrue,
      );
      expect(
        BackgroundTaskManager.supportsExpeditedWorkFromVersion(
          'Android 14 (API 34)',
        ),
        isTrue,
      );
      expect(
        BackgroundTaskManager.supportsExpeditedWorkFromVersion('16.5.0'),
        isFalse,
      );
    });
  });

  group('NotificationService Store Evaluation & Deduplication Tests', () {
    late MockLocalStoreService mockLocalStore;
    late FakeNotificationService notificationService;

    final tVandalSkin = SkinItem(
      uuid: 'vandal-prime-uuid',
      displayName: 'Prime Vandal',
      weaponName: 'Vandal',
      tierName: 'Premium',
    );

    final tMeleeSkin = SkinItem(
      uuid: 'melee-blade-uuid',
      displayName: 'Kuroonami No Yaiba',
      weaponName: 'Melee',
      tierName: 'Exclusive',
    );

    final tStore = DailyStore(
      featuredOffers: [tVandalSkin, tMeleeSkin],
      remainingDurationSeconds: 43200,
      lastFetched: DateTime.now(),
    );

    setUp(() {
      mockLocalStore = MockLocalStoreService();
      notificationService = FakeNotificationService();
      when(
        () => mockLocalStore.getLastNotifiedNightMarketRotation(),
      ).thenAnswer((_) async => null);
      when(
        () => mockLocalStore.getLastNotifiedAccessoryRotation(),
      ).thenAnswer((_) async => null);
    });

    test(
      'skips notification when already notified today with deduplicate = true',
      () async {
        final todayKey = DateTime.now().toUtc().toIso8601String().substring(
          0,
          10,
        );
        when(
          () => mockLocalStore.getLastNotifiedStoreDate(),
        ).thenAnswer((_) async => todayKey);

        final wishlist = [
          WishlistItem(
            uuid: 'vandal-prime-uuid',
            displayName: 'Prime Vandal',
            cost: 1775,
            addedAt: DateTime.now(),
          ),
        ];

        // Should return early without setting new notified date
        await notificationService.evaluateStoreOffers(
          store: tStore,
          wishlist: wishlist,
          alertRules: const [],
          localStore: mockLocalStore,
          deduplicate: true,
          notificationsEnabled: true,
        );

        verifyNever(() => mockLocalStore.setLastNotifiedStoreDate(any()));
      },
    );

    test(
      'evaluates wishlist and alerts, and updates notified date when matches found',
      () async {
        when(
          () => mockLocalStore.getLastNotifiedStoreDate(),
        ).thenAnswer((_) async => null);
        when(
          () => mockLocalStore.setLastNotifiedStoreDate(any()),
        ).thenAnswer((_) async => {});

        final wishlist = [
          WishlistItem(
            uuid: 'vandal-prime-uuid',
            displayName: 'Prime Vandal',
            cost: 1775,
            addedAt: DateTime.now(),
          ),
        ];

        final alertRules = [
          const StoreAlertRule(
            id: 'melee_alert',
            weapon: 'Melee',
            tiers: [],
            isEnabled: true,
            customName: 'Melee Alert',
          ),
        ];

        await notificationService.evaluateStoreOffers(
          store: tStore,
          wishlist: wishlist,
          alertRules: alertRules,
          localStore: mockLocalStore,
          deduplicate: true,
          notificationsEnabled: true,
        );

        final todayKey = DateTime.now().toUtc().toIso8601String().substring(
          0,
          10,
        );
        verify(
          () => mockLocalStore.setLastNotifiedStoreDate(todayKey),
        ).called(1);
        expect(notificationService.wishlistMatchesNotified.length, 1);
        expect(notificationService.wishlistMatchesNotified.first, [
          'Prime Vandal',
        ]);
        expect(notificationService.customAlertsNotified.length, 1);
      },
    );

    test(
      'notifies Night Market wishlist match even when daily store was notified',
      () async {
        final todayKey = DateTime.now().toUtc().toIso8601String().substring(
          0,
          10,
        );
        when(
          () => mockLocalStore.getLastNotifiedStoreDate(),
        ).thenAnswer((_) async => todayKey);
        when(
          () => mockLocalStore.setLastNotifiedNightMarketRotation(any()),
        ).thenAnswer((_) async => {});

        final nightMarket = NightMarket(
          offers: [
            NightMarketItem(
              skin: tVandalSkin,
              originalCost: 1775,
              discountPercent: 30,
              discountedCost: 1242,
            ),
          ],
          remainingDurationSeconds: 1000,
        );
        final store = DailyStore(
          featuredOffers: const [],
          remainingDurationSeconds: 43200,
          nightMarket: nightMarket,
          lastFetched: DateTime.now(),
        );

        await notificationService.evaluateStoreOffers(
          store: store,
          wishlist: [
            WishlistItem(
              uuid: 'vandal-prime-uuid',
              displayName: 'Prime Vandal',
              cost: 1775,
              addedAt: DateTime.now(),
            ),
          ],
          alertRules: const [],
          localStore: mockLocalStore,
          deduplicate: true,
          notificationsEnabled: true,
        );

        expect(notificationService.nightMarketNotified.length, 1);
        expect(
          notificationService
              .nightMarketNotified
              .single
              .single
              .skin
              .displayName,
          'Prime Vandal',
        );
        verify(
          () => mockLocalStore.setLastNotifiedNightMarketRotation(any()),
        ).called(1);
      },
    );

    test('does not repeat Night Market alert for the same rotation', () async {
      when(
        () => mockLocalStore.getLastNotifiedStoreDate(),
      ).thenAnswer((_) async => null);
      when(
        () => mockLocalStore.getLastNotifiedNightMarketRotation(),
      ).thenAnswer((_) async => 'vandal-prime-uuid');

      final store = DailyStore(
        featuredOffers: const [],
        remainingDurationSeconds: 43200,
        nightMarket: NightMarket(
          offers: [
            NightMarketItem(
              skin: tVandalSkin,
              originalCost: 1775,
              discountPercent: 30,
              discountedCost: 1242,
            ),
          ],
          remainingDurationSeconds: 1000,
        ),
        lastFetched: DateTime.now(),
      );

      await notificationService.evaluateStoreOffers(
        store: store,
        wishlist: [
          WishlistItem(
            uuid: 'vandal-prime-uuid',
            displayName: 'Prime Vandal',
            cost: 1775,
            addedAt: DateTime.now(),
          ),
        ],
        alertRules: const [],
        localStore: mockLocalStore,
        deduplicate: true,
        notificationsEnabled: true,
      );

      expect(notificationService.nightMarketNotified, isEmpty);
      verifyNever(
        () => mockLocalStore.setLastNotifiedNightMarketRotation(any()),
      );
    });

    test('notifies accessory rotation once and respects its toggle', () async {
      when(
        () => mockLocalStore.getLastNotifiedStoreDate(),
      ).thenAnswer((_) async => null);
      when(
        () => mockLocalStore.setLastNotifiedAccessoryRotation(any()),
      ).thenAnswer((_) async => {});

      final store = DailyStore(
        featuredOffers: const [],
        remainingDurationSeconds: 43200,
        accessoryOffers: const [
          AccessoryStoreItem(uuid: 'buddy-1', displayName: 'Nice Buddy'),
        ],
        lastFetched: DateTime.now(),
      );

      await notificationService.evaluateStoreOffers(
        store: store,
        wishlist: const [],
        alertRules: const [],
        localStore: mockLocalStore,
        deduplicate: true,
        notificationsEnabled: true,
      );

      expect(notificationService.accessoryNotified.length, 1);
      verify(
        () => mockLocalStore.setLastNotifiedAccessoryRotation('buddy-1'),
      ).called(1);

      await notificationService.evaluateStoreOffers(
        store: store,
        wishlist: const [],
        alertRules: const [],
        localStore: mockLocalStore,
        deduplicate: true,
        notificationsEnabled: true,
        accessoryAlertsEnabled: false,
      );
      expect(notificationService.accessoryNotified.length, 1);
    });

    test('skips all notifications when notifications are disabled', () async {
      when(
        () => mockLocalStore.getLastNotifiedStoreDate(),
      ).thenAnswer((_) async => null);

      final wishlist = [
        WishlistItem(
          uuid: 'vandal-prime-uuid',
          displayName: 'Prime Vandal',
          cost: 1775,
          addedAt: DateTime.now(),
        ),
      ];

      final alertRules = [
        const StoreAlertRule(
          id: 'melee_alert',
          weapon: 'Melee',
          tiers: [],
          isEnabled: true,
          customName: 'Melee Alert',
        ),
      ];

      await notificationService.evaluateStoreOffers(
        store: tStore,
        wishlist: wishlist,
        alertRules: alertRules,
        localStore: mockLocalStore,
        deduplicate: true,
        notificationsEnabled: false,
      );

      expect(notificationService.wishlistMatchesNotified, isEmpty);
      expect(notificationService.customAlertsNotified, isEmpty);
      verifyNever(() => mockLocalStore.setLastNotifiedStoreDate(any()));
    });

    test('forwards the app language to notification copy', () async {
      when(
        () => mockLocalStore.getLastNotifiedStoreDate(),
      ).thenAnswer((_) async => null);
      when(
        () => mockLocalStore.setLastNotifiedStoreDate(any()),
      ).thenAnswer((_) async => {});

      final wishlist = [
        WishlistItem(
          uuid: 'vandal-prime-uuid',
          displayName: 'Prime Vandal',
          cost: 1775,
          addedAt: DateTime.now(),
        ),
      ];

      await notificationService.evaluateStoreOffers(
        store: tStore,
        wishlist: wishlist,
        alertRules: const [],
        localStore: mockLocalStore,
        deduplicate: true,
        notificationsEnabled: true,
        languageCode: 'id',
      );

      expect(notificationService.lastWishlistLanguageCode, 'id');
    });
  });
}
