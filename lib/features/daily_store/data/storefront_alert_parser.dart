import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/riot_store_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

class StorefrontAlertSections {
  const StorefrontAlertSections({
    required this.hasNightMarketSection,
    required this.hasAccessorySection,
    this.nightMarket,
    this.accessoryOffers = const [],
  });

  final bool hasNightMarketSection;
  final bool hasAccessorySection;
  final NightMarket? nightMarket;
  final List<AccessoryStoreItem> accessoryOffers;
}

StorefrontAlertSections parseStorefrontAlertSections({
  required Map<String, dynamic> storefront,
  required Map<String, SkinItem> skinMap,
  required Map<String, SkinItem> levelToSkinMap,
  Map<String, Map<String, dynamic>> accessoryMetadata = const {},
}) {
  final bonusStore = storefront['BonusStore'] as Map<String, dynamic>?;
  NightMarket? nightMarket;

  if (bonusStore != null) {
    final remaining =
        (bonusStore['BonusStoreRemainingDurationInSeconds'] as num?)
                ?.toInt() ??
            0;
    final items = <NightMarketItem>[];

    for (final rawOffer
        in bonusStore['BonusStoreOffers'] as List<dynamic>? ?? const []) {
      if (rawOffer is! Map) continue;
      final offer = rawOffer['Offer'] as Map?;
      final offerId = offer?['OfferID']?.toString().toLowerCase() ?? '';
      final rewards = offer?['Rewards'] as List?;
      String? rewardId;
      if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
        rewardId = rewards.first['ItemID']?.toString().toLowerCase();
      }

      final skin = skinMap[offerId] ??
          levelToSkinMap[offerId] ??
          (rewardId == null
              ? null
              : (skinMap[rewardId] ?? levelToSkinMap[rewardId]));
      if (skin == null) continue;

      final costMap = offer?['Cost'] as Map?;
      final originalPrice = (costMap?[
                  RiotStoreRemoteDataSourceImpl.vpCurrencyUuid] as num?)
              ?.toInt() ??
          skin.cost;
      final discountCosts = rawOffer['DiscountCosts'] as Map?;
      final discountedPrice = (discountCosts?[
                  RiotStoreRemoteDataSourceImpl.vpCurrencyUuid] as num?)
              ?.toInt() ??
          originalPrice;
      final discountPercent = (rawOffer['DiscountPercent'] as num?)?.toInt() ??
          (originalPrice > 0
              ? (((originalPrice - discountedPrice) / originalPrice) * 100)
                  .round()
              : 0);

      items.add(
        NightMarketItem(
          skin: skin.copyWith(cost: discountedPrice),
          originalCost: originalPrice,
          discountPercent: discountPercent,
          discountedCost: discountedPrice,
          isSeen: rawOffer['IsSeen'] as bool? ?? true,
        ),
      );
    }

    if (items.isNotEmpty) {
      nightMarket = NightMarket(
        offers: items,
        remainingDurationSeconds: remaining,
      );
    }
  }

  final accessoryStore = storefront['AccessoryStore'] as Map<String, dynamic>?;
  final accessories = <AccessoryStoreItem>[];

  if (accessoryStore != null) {
    var remaining = (accessoryStore[
                'AccessoryStoreRemainingDurationInSeconds'] as num?)
            ?.toInt() ??
        (accessoryStore['remainingDurationInSeconds'] as num?)?.toInt() ??
        (accessoryStore['RemainingDurationInSeconds'] as num?)?.toInt() ??
        (accessoryStore['AccessoryStoreRemainingDuration'] as num?)?.toInt() ??
        0;
    if (remaining <= 0) {
      remaining = TimezoneHelper.timeUntilAccessoryReset.inSeconds;
    }

    for (final raw
        in accessoryStore['AccessoryStoreOffers'] as List<dynamic>? ??
            const []) {
      if (raw is! Map) continue;
      final offer = raw['Offer'] is Map ? raw['Offer'] as Map : raw;
      final rewards = offer['Rewards'] as List?;
      String? itemId;
      String? itemTypeId;
      if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
        itemId = rewards.first['ItemID']?.toString().toLowerCase();
        itemTypeId =
            rewards.first['ItemTypeID']?.toString().toLowerCase();
      }
      itemId ??= offer['OfferID']?.toString().toLowerCase();
      if (itemId == null || itemId.isEmpty) continue;

      final meta = accessoryMetadata[itemId];
      var itemType = meta?['itemType']?.toString();
      if (itemType == null || itemType == 'Accessory') {
        if (itemTypeId == 'dd3bf334-87f3-40bd-b043-682a57a8dc3a') {
          itemType = 'Gun Buddy';
        } else if (itemTypeId == '3f296c07-64c3-494c-923b-fe692a4fa1bd') {
          itemType = 'Player Card';
        } else if (itemTypeId == 'de729d44-44ac-4276-3b01-77a1e7f60434') {
          itemType = 'Player Title';
        } else if (itemTypeId == 'dbe38bf7-b6e8-4591-a142-87289beec76e') {
          itemType = 'Spray';
        } else {
          itemType = 'Accessory';
        }
      }

      final costMap = offer['Cost'] as Map?;
      int cost = 0;
      if (costMap != null && costMap.isNotEmpty) {
        int? found;
        for (final entry in costMap.entries) {
          if (entry.key.toString().toLowerCase() ==
              RiotStoreRemoteDataSourceImpl.kcCurrencyUuid) {
            found = (entry.value as num?)?.toInt();
            break;
          }
        }
        found ??= (costMap.values.firstOrNull as num?)?.toInt();
        cost = found ?? 0;
      }

      accessories.add(
        AccessoryStoreItem(
          uuid: itemId,
          displayName: meta?['displayName']?.toString() ?? itemType,
          displayIcon: meta?['displayIcon']?.toString(),
          itemType: itemType,
          kcCost: cost,
          remainingDurationSeconds: remaining,
        ),
      );
    }
  }

  return StorefrontAlertSections(
    hasNightMarketSection: bonusStore != null,
    hasAccessorySection: accessoryStore != null,
    nightMarket: nightMarket,
    accessoryOffers: accessories,
  );
}
