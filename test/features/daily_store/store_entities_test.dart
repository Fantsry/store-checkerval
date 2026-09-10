import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

void main() {
  group('DailyStore and SkinItem Entities', () {
    const skin = SkinItem(
      uuid: 'skin-1',
      displayName: 'Prime Vandal',
      weaponName: 'Vandal',
      cost: 1775,
      tierName: 'Premium',
      tierColor: 'FFE5B4',
      chromas: [
        SkinChroma(
          uuid: 'c-1',
          displayName: 'Prime Vandal (Orange)',
        ),
      ],
      levels: [
        SkinLevel(
          uuid: 'l-1',
          displayName: 'Level 1',
        ),
      ],
    );

    test('SkinItem toJson and fromJson matches', () {
      final json = skin.toJson();
      final restored = SkinItem.fromJson(json);

      expect(restored.uuid, 'skin-1');
      expect(restored.displayName, 'Prime Vandal');
      expect(restored.weaponName, 'Vandal');
      expect(restored.cost, 1775);
      expect(restored.chromas.length, 1);
      expect(restored.levels.length, 1);
    });

    test('UserWallet toJson and fromJson matches including kingdomCredits', () {
      const wallet = UserWallet(
        valorantPoints: 2500,
        radianitePoints: 120,
        kingdomCredits: 8500,
      );
      final json = wallet.toJson();
      final restored = UserWallet.fromJson(json);

      expect(restored.valorantPoints, 2500);
      expect(restored.radianitePoints, 120);
      expect(restored.kingdomCredits, 8500);
    });

    test('DailyStore toJson and fromJson matches and deduplicates bundles', () {
      const bundle1 = FeaturedBundle(
        uuid: 'b-1',
        displayName: 'Prime Collection',
        price: 7100,
      );
      const duplicateBundle = FeaturedBundle(
        uuid: 'b-1',
        displayName: 'Prime Collection',
        price: 7100,
      );
      const bundle2 = FeaturedBundle(
        uuid: 'b-2',
        displayName: 'Glitchpop Collection',
        price: 8700,
      );

      final json = {
        'featuredOffers': [skin.toJson()],
        'remainingDurationSeconds': 43200,
        'bundles': [
          bundle1.toJson(),
          duplicateBundle.toJson(),
          bundle2.toJson(),
        ],
        'accessoryOffers': [
          {
            'uuid': 'acc-1',
            'displayName': 'Octobuddy',
            'displayIcon': 'https://example.com/icon.png',
            'itemType': 'Gun Buddy',
            'kcCost': 4000,
            'remainingDurationSeconds': 250000,
          }
        ],
        'lastFetched': DateTime(2026, 9, 5, 7, 0).toIso8601String(),
      };

      final restored = DailyStore.fromJson(json);

      expect(restored.featuredOffers.length, 1);
      expect(restored.featuredOffers.first.displayName, 'Prime Vandal');
      // Verify deduplication: 3 in json, but only 2 unique
      expect(restored.bundles.length, 2);
      expect(restored.bundles[0].uuid, 'b-1');
      expect(restored.bundles[1].uuid, 'b-2');
      expect(restored.bundle?.uuid, 'b-1');
      expect(restored.accessoryOffers.length, 1);
      expect(restored.accessoryOffers.first.kcCost, 4000);
    });
  });
}
