import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/core/utils/valorant_card_assets.dart';

void main() {
  const cardUuid = '8edf22c5-4489-ab41-769a-07adb4c454d6';

  group('ValorantCardAssets', () {
    test('builds deterministic media URLs from the in-game card UUID', () {
      expect(
        ValorantCardAssets.smallArt(cardUuid),
        'https://media.valorant-api.com/playercards/$cardUuid/smallart.png',
      );
      expect(
        ValorantCardAssets.wideArt(cardUuid),
        'https://media.valorant-api.com/playercards/$cardUuid/wideart.png',
      );
      expect(
        ValorantCardAssets.largeArt(cardUuid),
        'https://media.valorant-api.com/playercards/$cardUuid/largeart.png',
      );
    });

    test('does not fabricate art for missing or zero card UUIDs', () {
      expect(ValorantCardAssets.wideArt(null), isNull);
      expect(ValorantCardAssets.wideArt(''), isNull);
      expect(
        ValorantCardAssets.wideArt('00000000-0000-0000-0000-000000000000'),
        isNull,
      );
      expect(ValorantCardAssets.smallArt('  '), isNull);
    });

    test('finds card UUIDs in real Riot identity field variants', () {
      expect(
        ValorantCardAssets.cardIdFrom({
          'Identity': {'PlayerCardID': cardUuid},
        }),
        cardUuid,
      );
      expect(
        ValorantCardAssets.cardIdFrom({
          'PlayerIdentity': {'playerCardId': cardUuid},
        }),
        cardUuid,
      );
      expect(
        ValorantCardAssets.cardIdFrom({'player_card_id': cardUuid}),
        cardUuid,
      );
      expect(
        ValorantCardAssets.cardIdFrom({
          'Identity': {'PlayerCardId': cardUuid},
        }),
        cardUuid,
      );
      expect(ValorantCardAssets.cardIdFrom({'playerCard': cardUuid}), cardUuid);
    });

    test('identifies the VALORANT default card', () {
      expect(
        ValorantCardAssets.isDefaultCard(ValorantCardAssets.defaultCardUuid),
        isTrue,
      );
      expect(
        ValorantCardAssets.isDefaultCard(
          ValorantCardAssets.defaultCardUuid.toUpperCase(),
        ),
        isTrue,
      );
      expect(ValorantCardAssets.isDefaultCard(cardUuid), isFalse);
      expect(ValorantCardAssets.isDefaultCard(null), isFalse);
    });
  });
}
