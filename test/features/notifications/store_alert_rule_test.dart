import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';

void main() {
  group('StoreAlertRule Entity', () {
    const kuronamiMelee = SkinItem(
      uuid: 'kuronami-knife-uuid',
      displayName: 'Kuronami no Yaiba',
      weaponName: 'Melee',
      tierName: 'Exclusive',
      cost: 5350,
    );

    const reaverKarambit = SkinItem(
      uuid: 'reaver-karambit-uuid',
      displayName: 'Reaver Karambit',
      weaponName: 'Karambit',
      tierName: 'Premium',
      cost: 4350,
    );

    const primeVandal = SkinItem(
      uuid: 'prime-vandal-uuid',
      displayName: 'Prime Vandal',
      weaponName: 'Vandal',
      tierName: 'Premium',
      cost: 1775,
    );

    const sensationVandal = SkinItem(
      uuid: 'sensation-vandal-uuid',
      displayName: 'Sensation Vandal',
      weaponName: 'Vandal',
      tierName: 'Deluxe',
      cost: 1275,
    );

    const sovereignGhost = SkinItem(
      uuid: 'sovereign-ghost-uuid',
      displayName: 'Sovereign Ghost',
      weaponName: 'Ghost',
      tierName: 'Premium',
      cost: 1775,
    );

    test('matches any Melee (knife, karambit, blade, yaiba)', () {
      const meleeRule = StoreAlertRule(
        id: '1',
        weapon: 'Melee',
        tiers: [],
        isEnabled: true,
      );

      expect(meleeRule.matches(kuronamiMelee), isTrue);
      expect(meleeRule.matches(reaverKarambit), isTrue);
      expect(meleeRule.matches(primeVandal), isFalse);
    });

    test('matches Vandal with Premium+ tier filter', () {
      const vandalPremiumRule = StoreAlertRule(
        id: '2',
        weapon: 'Vandal',
        tiers: ['Premium', 'Exclusive', 'Ultra'],
        isEnabled: true,
      );

      expect(vandalPremiumRule.matches(primeVandal), isTrue);
      // Sensation Vandal is Deluxe, should NOT match
      expect(vandalPremiumRule.matches(sensationVandal), isFalse);
      expect(vandalPremiumRule.matches(kuronamiMelee), isFalse);
    });

    test('matches Ghost with Deluxe/Premium tier filter', () {
      const ghostRule = StoreAlertRule(
        id: '3',
        weapon: 'Ghost',
        tiers: ['Deluxe', 'Premium'],
        isEnabled: true,
      );

      expect(ghostRule.matches(sovereignGhost), isTrue);
      expect(ghostRule.matches(primeVandal), isFalse);
    });

    test('matches Phantom with Premium+ tier filter', () {
      const reconPhantom = SkinItem(
        uuid: 'recon-phantom-uuid',
        displayName: 'Recon Phantom',
        weaponName: 'Phantom',
        tierName: 'Premium',
        cost: 1775,
      );

      const phantomPremiumRule = StoreAlertRule(
        id: 'phantom_1',
        weapon: 'Phantom',
        tiers: ['Premium', 'Exclusive', 'Ultra'],
        isEnabled: true,
      );

      expect(phantomPremiumRule.matches(reconPhantom), isTrue);
      expect(phantomPremiumRule.matches(primeVandal), isFalse);
    });

    test('disabled rule returns false', () {
      const disabledRule = StoreAlertRule(
        id: '4',
        weapon: 'Melee',
        tiers: [],
        isEnabled: false,
      );

      expect(disabledRule.matches(kuronamiMelee), isFalse);
    });

    test('toJson and fromJson preserves all fields', () {
      const rule = StoreAlertRule(
        id: 'test_id',
        weapon: 'Operator',
        tiers: ['Ultra', 'Exclusive'],
        isEnabled: true,
        customName: 'Sniper Alert',
      );

      final json = rule.toJson();
      final restored = StoreAlertRule.fromJson(json);

      expect(restored, equals(rule));
      expect(restored.displayName, equals('Sniper Alert'));
    });
  });
}
