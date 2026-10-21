import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/daily_store/data/storefront_alert_parser.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

void main() {
  final skin = SkinItem(
    uuid: 'skin-1',
    displayName: 'Prime Vandal',
    weaponName: 'Vandal',
    cost: 1775,
    levels: const [
      SkinLevel(uuid: 'level-1', displayName: 'Prime Vandal'),
    ],
  );

  final skinMap = {'skin-1': skin};
  final levelMap = {'level-1': skin};

  test('parses Night Market and accessory sections', () {
    final sections = parseStorefrontAlertSections(
      storefront: {
        'BonusStore': {
          'BonusStoreRemainingDurationInSeconds': 90000,
          'BonusStoreOffers': [
            {
              'Offer': {
                'OfferID': 'level-1',
                'Cost': {
                  '85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741': 1775,
                },
              },
              'DiscountCosts': {
                '85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741': 1242,
              },
              'DiscountPercent': 30,
              'IsSeen': false,
            },
          ],
        },
        'AccessoryStore': {
          'AccessoryStoreRemainingDurationInSeconds': 500000,
          'AccessoryStoreOffers': [
            {
              'Offer': {
                'Rewards': [
                  {
                    'ItemID': 'buddy-1',
                    'ItemTypeID': 'dd3bf334-87f3-40bd-b043-682a57a8dc3a',
                  },
                ],
                'Cost': {
                  '85ca9543-7697-970b-7caa-e2a3d1a3d49e': 2000,
                },
              },
            },
          ],
        },
      },
      skinMap: skinMap,
      levelToSkinMap: levelMap,
    );

    expect(sections.hasNightMarketSection, isTrue);
    expect(sections.nightMarket, isNotNull);
    expect(sections.nightMarket!.offers.single.skin.displayName, 'Prime Vandal');
    expect(sections.nightMarket!.offers.single.discountedCost, 1242);
    expect(sections.nightMarket!.offers.single.discountPercent, 30);
    expect(sections.nightMarket!.offers.single.isSeen, isFalse);

    expect(sections.hasAccessorySection, isTrue);
    expect(sections.accessoryOffers.single.uuid, 'buddy-1');
    expect(sections.accessoryOffers.single.itemType, 'Gun Buddy');
    expect(sections.accessoryOffers.single.kcCost, 2000);
  });

  test('marks sections absent when Riot omits them', () {
    final sections = parseStorefrontAlertSections(
      storefront: const {},
      skinMap: skinMap,
      levelToSkinMap: levelMap,
    );

    expect(sections.hasNightMarketSection, isFalse);
    expect(sections.hasAccessorySection, isFalse);
    expect(sections.nightMarket, isNull);
    expect(sections.accessoryOffers, isEmpty);
  });
}
