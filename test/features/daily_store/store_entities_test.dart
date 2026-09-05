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

    test('UserWallet toJson and fromJson matches', () {
      const wallet = UserWallet(valorantPoints: 2500, radianitePoints: 120);
      final json = wallet.toJson();
      final restored = UserWallet.fromJson(json);

      expect(restored.valorantPoints, 2500);
      expect(restored.radianitePoints, 120);
    });

    test('DailyStore toJson and fromJson matches', () {
      final store = DailyStore(
        featuredOffers: const [skin],
        remainingDurationSeconds: 43200,
        bundle: const FeaturedBundle(
          uuid: 'b-1',
          displayName: 'Prime Collection',
          price: 7100,
        ),
        lastFetched: DateTime(2026, 9, 5, 7, 0),
      );

      final json = store.toJson();
      final restored = DailyStore.fromJson(json);

      expect(restored.featuredOffers.length, 1);
      expect(restored.featuredOffers.first.displayName, 'Prime Vandal');
      expect(restored.remainingDurationSeconds, 43200);
      expect(restored.bundle?.displayName, 'Prime Collection');
    });
  });
}
