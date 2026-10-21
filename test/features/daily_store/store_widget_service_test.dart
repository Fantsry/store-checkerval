import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/daily_store/data/store_widget_service.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

void main() {
  test('buildPayload formats store rotation, items, and Night Market', () {
    final now = DateTime(2026, 10, 21, 22);
    final store = DailyStore(
      featuredOffers: const [
        SkinItem(uuid: '1', displayName: 'Prime Vandal', cost: 1775),
        SkinItem(uuid: '2', displayName: 'Oni Phantom', cost: 1775),
        SkinItem(uuid: '3', displayName: 'Reaver Operator', cost: 1775),
        SkinItem(uuid: '4', displayName: 'Sovereign Ghost', cost: 875),
      ],
      remainingDurationSeconds: 7 * 60 * 60,
      nightMarket: const NightMarket(
        offers: [
          NightMarketItem(
            skin: SkinItem(uuid: 'nm-1', displayName: 'Glitchpop Vandal'),
            originalCost: 2175,
            discountPercent: 44,
            discountedCost: 1218,
          ),
          NightMarketItem(
            skin: SkinItem(uuid: 'nm-2', displayName: 'Sentinels of Light'),
            originalCost: 2175,
            discountPercent: 31,
            discountedCost: 1500,
          ),
        ],
        remainingDurationSeconds: 86400,
      ),
      lastFetched: now,
    );

    final payload = StoreWidgetService.buildPayload(store, now: now);

    expect(payload['store_reset_label'], 'Reset 05:00');
    expect(payload['store_summary'], '4 skins • Reset 05:00');
    expect(payload['store_item_1'], 'Prime Vandal • 1.775 VP');
    expect(payload['store_item_4'], 'Sovereign Ghost • 875 VP');
    expect(
      payload['store_night_market'],
      'NIGHT MARKET: 2 deals • up to 44% off',
    );
    expect(payload['store_updated_label'], 'Update 22:00');
  });

  test('buildPayload hides empty Night Market and missing offers', () {
    final now = DateTime(2026, 10, 21, 9, 15);
    final store = DailyStore(
      featuredOffers: const [
        SkinItem(uuid: '1', displayName: 'Prime Vandal', cost: 0),
      ],
      remainingDurationSeconds: 0,
      lastFetched: now,
    );

    final payload = StoreWidgetService.buildPayload(store, now: now);

    expect(payload['store_item_1'], 'Prime Vandal • 0 VP');
    expect(payload['store_item_2'], '');
    expect(payload['store_night_market'], '');
  });
}
