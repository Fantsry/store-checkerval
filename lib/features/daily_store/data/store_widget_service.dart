import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';

class StoreWidgetService {
  static const String androidProviderName = 'StoreWidgetProvider';

  static Map<String, String> buildPayload(DailyStore store, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final elapsed = current.difference(store.lastFetched).inSeconds;
    final remaining = (store.remainingDurationSeconds - elapsed).clamp(
      0,
      store.remainingDurationSeconds,
    );
    final resetAt = current.add(Duration(seconds: remaining));
    final timeFormat = DateFormat('HH:mm');
    final resetLabel = 'Reset ${timeFormat.format(resetAt)}';

    final payload = <String, String>{
      'store_reset_label': resetLabel,
      'store_summary': store.featuredOffers.isEmpty
          ? 'Store unavailable'
          : '${store.featuredOffers.length} skins • $resetLabel',
      'store_updated_label': 'Update ${timeFormat.format(current)}',
    };

    for (var index = 0; index < 4; index++) {
      if (index >= store.featuredOffers.length) {
        payload['store_item_${index + 1}'] = '';
        continue;
      }
      final skin = store.featuredOffers[index];
      payload['store_item_${index + 1}'] =
          '${skin.displayName} • ${_formatVp(skin.cost)} VP';
    }

    final nightMarket = store.nightMarket;
    if (nightMarket != null && nightMarket.offers.isNotEmpty) {
      final maxDiscount = nightMarket.offers
          .map((offer) => offer.discountPercent)
          .reduce((a, b) => a > b ? a : b);
      payload['store_night_market'] =
          'NIGHT MARKET: ${nightMarket.offers.length} deals • up to $maxDiscount% off';
    } else {
      payload['store_night_market'] = '';
    }

    return payload;
  }

  static String _formatVp(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  Future<void> update(DailyStore store) async {
    if (!Platform.isAndroid) return;

    try {
      final payload = buildPayload(store);
      for (final entry in payload.entries) {
        await HomeWidget.saveWidgetData<String>(
          entry.key,
          entry.value.isEmpty ? null : entry.value,
        );
      }
      await HomeWidget.updateWidget(androidName: androidProviderName);
    } catch (_) {}
  }
}
