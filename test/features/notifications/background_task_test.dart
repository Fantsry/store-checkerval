import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

class MockLocalStoreService extends Mock implements LocalStoreService {}

class FakeNotificationService extends NotificationService {
  final List<List<String>> wishlistMatchesNotified = [];
  final List<Map<String, List<String>>> customAlertsNotified = [];

  @override
  Future<void> showWishlistMatchNotification({
    required List<String> matchedSkinNames,
    String? skinUuid,
  }) async {
    wishlistMatchesNotified.add(matchedSkinNames);
  }

  @override
  Future<void> showCustomAlertNotification({
    required Map<String, List<String>> ruleMatches,
  }) async {
    customAlertsNotified.add(ruleMatches);
  }
}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('TimezoneHelper Tests', () {
    test('formatDuration formats hours, minutes, seconds with zero padding', () {
      const duration = Duration(hours: 5, minutes: 7, seconds: 9);
      expect(TimezoneHelper.formatDuration(duration), '05:07:09');

      const durationZero = Duration.zero;
      expect(TimezoneHelper.formatDuration(durationZero), '00:00:00');
    });

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

    test('formatWeeklyDuration formats days, hours, minutes, seconds properly', () {
      const durationMultiDay = Duration(days: 3, hours: 14, minutes: 25, seconds: 8);
      expect(TimezoneHelper.formatWeeklyDuration(durationMultiDay), '3d 14:25:08');

      const durationSingleDay = Duration(hours: 18, minutes: 5, seconds: 2);
      expect(TimezoneHelper.formatWeeklyDuration(durationSingleDay), '18:05:02');

      expect(TimezoneHelper.formatWeeklyDuration(Duration.zero), '00:00:00');
    });

    test('nextAccessoryStoreReset calculates Wednesday 00:00 UTC correctly in the future', () {
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
    });

    test('skips notification when already notified today with deduplicate = true', () async {
      final todayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      when(() => mockLocalStore.getLastNotifiedStoreDate())
          .thenAnswer((_) async => todayKey);

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
      );

      verifyNever(() => mockLocalStore.setLastNotifiedStoreDate(any()));
    });

    test('evaluates wishlist and alerts, and updates notified date when matches found', () async {
      when(() => mockLocalStore.getLastNotifiedStoreDate())
          .thenAnswer((_) async => null);
      when(() => mockLocalStore.setLastNotifiedStoreDate(any()))
          .thenAnswer((_) async => {});

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
      );

      final todayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      verify(() => mockLocalStore.setLastNotifiedStoreDate(todayKey)).called(1);
      expect(notificationService.wishlistMatchesNotified.length, 1);
      expect(notificationService.wishlistMatchesNotified.first, ['Prime Vandal']);
      expect(notificationService.customAlertsNotified.length, 1);
    });
  });
}
