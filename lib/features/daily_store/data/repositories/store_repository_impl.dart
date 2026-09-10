import 'package:valorant_store_tracker/core/error/exceptions.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/utils/skin_price_helper.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/riot_store_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/valorant_api_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';

class StoreRepositoryImpl implements StoreRepository {
  final RiotStoreRemoteDataSource _riotRemoteDataSource;
  final ValorantApiRemoteDataSource _valorantApiRemoteDataSource;
  final SecureStorageService _secureStorage;
  final LocalStoreService _localStore;

  StoreRepositoryImpl({
    required RiotStoreRemoteDataSource riotRemoteDataSource,
    required ValorantApiRemoteDataSource valorantApiRemoteDataSource,
    required SecureStorageService secureStorage,
    required LocalStoreService localStore,
  })  : _riotRemoteDataSource = riotRemoteDataSource,
        _valorantApiRemoteDataSource = valorantApiRemoteDataSource,
        _secureStorage = secureStorage,
        _localStore = localStore;

  @override
  Future<Result<List<SkinItem>>> getAllCatalogSkins() async {
    try {
      final cached = await _localStore.getCachedSkins();
      if (cached != null && cached.isNotEmpty) {
        return Result.success(cached);
      }

      final skins = await _valorantApiRemoteDataSource.getWeaponSkins();
      await _localStore.saveCachedSkins(skins);
      return Result.success(skins);
    } catch (e) {
      final cached = await _localStore.getCachedSkins();
      if (cached != null && cached.isNotEmpty) {
        return Result.success(cached);
      }
      return Result.failure(ServerFailure(message: 'Failed to load catalog: $e'));
    }
  }

  bool _isStoreExpired(DailyStore store) {
    if (store.featuredOffers.isEmpty) return true;
    final elapsed = DateTime.now().difference(store.lastFetched).inSeconds;
    return elapsed >= store.remainingDurationSeconds;
  }

  @override
  Future<Result<DailyStore>> getDailyStore({bool forceRefresh = false}) async {
    try {
      final puuid = await _secureStorage.getPuuid();
      final shard = await _secureStorage.getShard() ?? 'ap';

      // If not force-refreshing, check if valid unexpired cached store exists
      if (!forceRefresh) {
        final cached = await _localStore.getCachedDailyStore();
        if (cached != null && !_isStoreExpired(cached)) {
          return Result.success(cached);
        }
      }

      // If user is not logged in, check if a real store was cached offline, otherwise require sign-in
      if (puuid == null || puuid.isEmpty) {
        final cached = await _localStore.getCachedDailyStore();
        if (cached != null && !_isStoreExpired(cached)) {
          return Result.success(cached);
        }
        return const Result.failure(
          AuthFailure(
            message: 'Please sign in with your Riot account to view your live daily store.',
          ),
        );
      }

      // Ensure skin catalog is available
      final catalogResult = await getAllCatalogSkins();
      final allSkins = catalogResult.valueOrNull ?? [];
      final skinMap = {for (var s in allSkins) s.uuid.toLowerCase(): s};

      // Also map skin level UUIDs to skin items because Riot storefront offers level UUIDs
      final levelToSkinMap = <String, SkinItem>{};
      for (final s in allSkins) {
        for (final lvl in s.levels) {
          levelToSkinMap[lvl.uuid.toLowerCase()] = s;
        }
      }

      // Fetch from Riot storefront
      final storefrontData = await _riotRemoteDataSource.getStorefront(
        shard: shard,
        puuid: puuid,
      );

      final resolvedShard = storefrontData['_resolvedShard'] as String?;
      if (resolvedShard != null && resolvedShard != shard) {
        await _secureStorage.setShard(resolvedShard);
      }

      final skinsPanel =
          storefrontData['SkinsPanelLayout'] as Map<String, dynamic>? ?? {};
      final offerUuids =
          (skinsPanel['SingleItemOffers'] as List<dynamic>? ?? [])
              .map((e) => e.toString().toLowerCase())
              .toList();

      // Extract price map from SingleItemStoreOffers if present
      final storeOffers =
          skinsPanel['SingleItemStoreOffers'] as List<dynamic>? ?? [];
      final itemPrices = <String, int>{};

      int? extractVpCost(Map? costMap) {
        if (costMap == null) return null;
        for (final entry in costMap.entries) {
          if (entry.key.toString().toLowerCase() ==
              RiotStoreRemoteDataSourceImpl.vpCurrencyUuid.toLowerCase()) {
            return (entry.value as num?)?.toInt();
          }
        }
        return (costMap.values.firstOrNull as num?)?.toInt();
      }

      for (final offer in storeOffers) {
        if (offer is Map) {
          final offerId = offer['OfferID']?.toString().toLowerCase();
          final price = extractVpCost(offer['Cost'] as Map?);

          if (price != null) {
            if (offerId != null) itemPrices[offerId] = price;
            final rewards = offer['Rewards'] as List?;
            if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
              final rId = rewards.first['ItemID']?.toString().toLowerCase();
              if (rId != null) {
                itemPrices[rId] = price;
                _localStore.saveLivePrice(rId, price);

                // Cross-index with catalog skin item and all its levels
                final s = skinMap[rId] ?? levelToSkinMap[rId];
                if (s != null) {
                  itemPrices[s.uuid.toLowerCase()] = price;
                  _localStore.saveLivePrice(s.uuid, price);
                  for (final lvl in s.levels) {
                    itemPrices[lvl.uuid.toLowerCase()] = price;
                    _localStore.saveLivePrice(lvl.uuid, price);
                  }
                }
              }
            }
          }

          // If SingleItemOffers was empty, populate from SingleItemStoreOffers
          if (offerUuids.isEmpty) {
            final rewards = offer['Rewards'] as List?;
            String? candidateId;
            if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
              candidateId = rewards.first['ItemID']?.toString().toLowerCase();
            }
            candidateId ??= offerId;
            if (candidateId != null && candidateId.isNotEmpty) {
              offerUuids.add(candidateId);
            }
          }
        }
      }

      final remainingSeconds = (skinsPanel[
              'SingleItemOffersRemainingDurationInSeconds'] as num?)
          ?.toInt() ??
          86400;

      final dailySkins = <SkinItem>[];
      for (final offerUuid in offerUuids) {
        // Try matching directly or via level UUID
        SkinItem? matched = skinMap[offerUuid] ?? levelToSkinMap[offerUuid];

        // If offerUuid is an OfferID from Riot, resolve the real skin from storeOffers
        if (matched == null) {
          for (final offer in storeOffers) {
            if (offer is Map &&
                offer['OfferID']?.toString().toLowerCase() == offerUuid) {
              final rewards = offer['Rewards'] as List?;
              if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
                final rId = rewards.first['ItemID']?.toString().toLowerCase();
                if (rId != null) {
                  matched = skinMap[rId] ?? levelToSkinMap[rId];
                  break;
                }
              }
            }
          }
        }

        // Layered price resolution: offerUuid -> matched.uuid -> matched.levels
        int? realPrice = itemPrices[offerUuid];
        if (matched != null) {
          realPrice ??= itemPrices[matched.uuid.toLowerCase()];
          if (realPrice == null) {
            for (final lvl in matched.levels) {
              final p = itemPrices[lvl.uuid.toLowerCase()];
              if (p != null) {
                realPrice = p;
                break;
              }
            }
          }
        }
        realPrice ??= matched?.cost ?? 1775;

        if (matched != null) {
          dailySkins.add(matched.copyWith(cost: realPrice));
        } else {
          // Fallback skin item
          dailySkins.add(
            SkinItem(
              uuid: offerUuid,
              displayName: 'Valorant Skin',
              cost: realPrice,
              weaponName: 'Weapon',
            ),
          );
        }
      }

      // ─── 1. Parse Featured Bundles with Valorant-API metadata ────────
      final bundlesList = <FeaturedBundle>[];
      final featuredBundleData =
          storefrontData['FeaturedBundle'] as Map<String, dynamic>?;

      if (featuredBundleData != null) {
        Map<String, Map<String, dynamic>> bundlesMeta = {};
        try {
          bundlesMeta =
              await _valorantApiRemoteDataSource.getBundlesMetadata();
        } catch (_) {}

        final rawBundles = <Map<String, dynamic>>[];
        if (featuredBundleData['Bundles'] is List &&
            (featuredBundleData['Bundles'] as List).isNotEmpty) {
          for (final b in featuredBundleData['Bundles'] as List) {
            if (b is Map) rawBundles.add(Map<String, dynamic>.from(b));
          }
        } else if (featuredBundleData['Bundle'] is Map) {
          rawBundles.add(
              Map<String, dynamic>.from(featuredBundleData['Bundle'] as Map));
        }

        final bRemaining = (featuredBundleData[
                'BundleRemainingDurationInSeconds'] as num?)
            ?.toInt() ??
            0;

        final seenBundleIds = <String>{};
        for (final bundleDetails in rawBundles) {
          final bId =
              (bundleDetails['ID'] ?? '').toString().trim().toLowerCase();
          final bDataAssetId = (bundleDetails['DataAssetID'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final effectiveUuid = (bDataAssetId.isNotEmpty ? bDataAssetId : bId)
              .toLowerCase();

          if (effectiveUuid.isEmpty) continue;
          if (seenBundleIds.contains(effectiveUuid) ||
              (bId.isNotEmpty && seenBundleIds.contains(bId))) {
            continue; // Skip duplicate bundle
          }
          seenBundleIds.add(effectiveUuid);
          if (bId.isNotEmpty) seenBundleIds.add(bId);
          if (bDataAssetId.isNotEmpty) seenBundleIds.add(bDataAssetId);

          final meta = bundlesMeta[effectiveUuid] ??
              bundlesMeta[bId] ??
              bundlesMeta[bDataAssetId];

          final bName = meta?['displayName']?.toString() ?? 'Featured Collection';
          final bIcon = meta?['displayIcon']?.toString();
          final bIcon2 = meta?['displayIcon2']?.toString();
          final bVertical = meta?['verticalPromoImage']?.toString();

          final bundleItemOffers =
              bundleDetails['Items'] as List<dynamic>? ?? [];

          final bundleSkins = <SkinItem>[];
          final totalDiscounted = bundleDetails['TotalDiscountedCost'] as Map?;
          final totalBase = bundleDetails['TotalBaseCost'] as Map?;
          int bundlePrice = (totalDiscounted?[
                  RiotStoreRemoteDataSourceImpl.vpCurrencyUuid] as num?)
              ?.toInt() ??
              (totalBase?[RiotStoreRemoteDataSourceImpl.vpCurrencyUuid]
                      as num?)
                  ?.toInt() ??
              0;

          for (final item in bundleItemOffers) {
            if (item is! Map) continue;
            final itemOffer = item['Item'] as Map?;
            final itemUuid =
                itemOffer?['ItemID']?.toString().toLowerCase() ?? '';
            final price = (item['DiscountedPrice'] as num?)?.toInt() ??
                (item['BasePrice'] as num?)?.toInt() ??
                0;

            final s = skinMap[itemUuid] ?? levelToSkinMap[itemUuid];
            if (s != null) {
              bundleSkins.add(s.copyWith(cost: price));
            }
          }

          if (bundlePrice == 0 && bundleSkins.isNotEmpty) {
            bundlePrice = bundleSkins.fold<int>(0, (sum, s) => sum + s.cost);
          }

          bundlesList.add(
            FeaturedBundle(
              uuid: effectiveUuid,
              displayName: bName,
              displayIcon: bIcon,
              displayIcon2: bIcon2,
              verticalPromoImage: bVertical,
              price: bundlePrice > 0 ? bundlePrice : 7100,
              remainingDurationSeconds: bRemaining,
              items: bundleSkins,
            ),
          );
        }
      }

      // ─── 2. Parse Night Market (BonusStore) ──────────────────────────
      NightMarket? nightMarket;
      final bonusStoreData =
          storefrontData['BonusStore'] as Map<String, dynamic>?;

      if (bonusStoreData != null) {
        final nmRemaining = (bonusStoreData[
                'BonusStoreRemainingDurationInSeconds'] as num?)
            ?.toInt() ??
            0;
        final bonusOffers =
            bonusStoreData['BonusStoreOffers'] as List<dynamic>? ?? [];

        final nmItems = <NightMarketItem>[];
        for (final rawOffer in bonusOffers) {
          if (rawOffer is! Map) continue;
          final offer = rawOffer['Offer'] as Map?;
          final offerId =
              offer?['OfferID']?.toString().toLowerCase() ?? '';
          final rewards = offer?['Rewards'] as List?;
          String? rewardId;
          if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
            rewardId = rewards.first['ItemID']?.toString().toLowerCase();
          }

          final skin = skinMap[offerId] ??
              levelToSkinMap[offerId] ??
              (rewardId != null ? (skinMap[rewardId] ?? levelToSkinMap[rewardId]) : null);

          if (skin != null) {
            final costMap = offer?['Cost'] as Map?;
            final originalPrice = (costMap?[
                    RiotStoreRemoteDataSourceImpl.vpCurrencyUuid] as num?)
                ?.toInt() ??
                skin.cost;

            final discountCostMap = rawOffer['DiscountCosts'] as Map?;
            final discountedPrice = (discountCostMap?[
                    RiotStoreRemoteDataSourceImpl.vpCurrencyUuid] as num?)
                ?.toInt() ??
                (originalPrice * 0.65).round();

            final discountPct = (rawOffer['DiscountPercent'] as num?)
                    ?.toInt() ??
                (originalPrice > 0
                    ? (((originalPrice - discountedPrice) / originalPrice) * 100)
                        .round()
                    : 35);

            final isSeen = rawOffer['IsSeen'] as bool? ?? true;

            nmItems.add(
              NightMarketItem(
                skin: skin.copyWith(cost: discountedPrice),
                originalCost: originalPrice,
                discountPercent: discountPct,
                discountedCost: discountedPrice,
                isSeen: isSeen,
              ),
            );
          }
        }

        if (nmItems.isNotEmpty) {
          nightMarket = NightMarket(
            offers: nmItems,
            remainingDurationSeconds: nmRemaining,
          );
        }
      }

      // ─── 3. Parse Accessory Store (Kingdom Credits Shop) ─────────────
      final accessoryOffers = <AccessoryStoreItem>[];
      final accessoryStoreData =
          storefrontData['AccessoryStore'] as Map<String, dynamic>?;

      if (accessoryStoreData != null) {
        final accRemaining = (accessoryStoreData[
                'AccessoryStoreRemainingDurationInSeconds'] as num?)
            ?.toInt() ??
            0;
        final rawAccOffers = accessoryStoreData['AccessoryStoreOffers']
            as List<dynamic>? ??
            [];

        if (rawAccOffers.isNotEmpty) {
          Map<String, Map<String, dynamic>> accMeta = {};
          try {
            accMeta =
                await _valorantApiRemoteDataSource.getAccessoriesMetadata();
          } catch (_) {}

          for (final acc in rawAccOffers) {
            if (acc is! Map) continue;
            final offer = (acc['Offer'] is Map)
                ? (acc['Offer'] as Map)
                : acc;
            final rewards = offer['Rewards'] as List?;
            String? itemId;
            String? itemTypeId;
            if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
              itemId = rewards.first['ItemID']?.toString().toLowerCase();
              itemTypeId = rewards.first['ItemTypeID']?.toString().toLowerCase();
            }
            itemId ??= offer['OfferID']?.toString().toLowerCase();

            if (itemId == null || itemId.isEmpty) continue;

            final meta = accMeta[itemId];
            var name = meta?['displayName']?.toString();
            var icon = meta?['displayIcon']?.toString();
            var itemType = meta?['itemType']?.toString();

            // Infer itemType from known Riot ItemTypeID if meta is unavailable
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
            name ??= itemType;

            final costMap = offer['Cost'] as Map?;
            const kcCurrencyUuid = '85ca9543-7697-970b-7caa-e2a3d1a3d49e';
            int kcCost = 4000;
            if (costMap != null && costMap.isNotEmpty) {
              final kcEntry = costMap.entries.firstWhere(
                (e) =>
                    e.key.toString().toLowerCase() ==
                    kcCurrencyUuid.toLowerCase(),
                orElse: () => costMap.entries.first,
              );
              kcCost = (kcEntry.value as num?)?.toInt() ?? 4000;
            }

            accessoryOffers.add(
              AccessoryStoreItem(
                uuid: itemId,
                displayName: name,
                displayIcon: icon,
                itemType: itemType,
                kcCost: kcCost,
                remainingDurationSeconds: accRemaining,
              ),
            );
          }
        }
      }

      final store = DailyStore(
        featuredOffers: dailySkins,
        remainingDurationSeconds: remainingSeconds,
        bundles: bundlesList,
        bundle: bundlesList.isNotEmpty ? bundlesList.first : null,
        nightMarket: nightMarket,
        accessoryOffers: accessoryOffers,
        lastFetched: DateTime.now(),
      );

      await _localStore.saveDailyStore(store);
      return Result.success(store);
    } on AuthException catch (e) {
      if (!forceRefresh) {
        final cached = await _localStore.getCachedDailyStore();
        if (cached != null && !_isStoreExpired(cached)) return Result.success(cached);
      }
      return Result.failure(
        AuthFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      if (!forceRefresh) {
        final cached = await _localStore.getCachedDailyStore();
        if (cached != null && !_isStoreExpired(cached)) return Result.success(cached);
      }
      String cleanMessage = 'Gagal memuat daily store';
      if (e is ServerException) {
        if (e.statusCode == 404) {
          cleanMessage =
              'Daily store tidak ditemukan untuk akun ini di server Riot. Pastikan Anda sudah login akun Valorant yang aktif.';
        } else if (e.statusCode == 401 || e.statusCode == 400) {
          cleanMessage =
              'Sesi login Riot kedaluwarsa atau tidak valid. Silakan sign in ulang dengan akun Riot Anda.';
        } else if (e.statusCode == 405) {
          cleanMessage =
              'Metode request ditolak server Riot (405). Silakan tekan tombol RETRY.';
        } else {
          cleanMessage = 'Server Riot (${e.statusCode}): Gagal memuat rotasi store. Silakan tekan RETRY.';
        }
      } else {
        cleanMessage = 'Gagal memuat daily store: $e';
      }
      return Result.failure(
        ServerFailure(message: cleanMessage),
      );
    }
  }

  @override
  Future<Result<UserWallet>> getUserWallet() async {
    try {
      final puuid = await _secureStorage.getPuuid();
      final shard = await _secureStorage.getShard() ?? 'ap';
      if (puuid == null) return const Result.success(UserWallet());

      final wallet = await _riotRemoteDataSource.getWallet(
        shard: shard,
        puuid: puuid,
      );
      return Result.success(wallet);
    } catch (e) {
      return const Result.success(UserWallet());
    }
  }

  @override
  Future<Result<SkinItem>> getSkinDetail(String skinUuid) async {
    final catalog = await getAllCatalogSkins();
    if (catalog.isSuccess) {
      final skins = catalog.valueOrNull!;
      for (final s in skins) {
        if (s.uuid.toLowerCase() == skinUuid.toLowerCase() ||
            s.levels.any((lvl) => lvl.uuid.toLowerCase() == skinUuid.toLowerCase())) {
          final isMelee = SkinPriceHelper.isMelee(
            displayName: s.displayName,
            weaponName: s.weaponName,
          );
          if (isMelee) {
            final livePrice = _localStore.getLivePrice(s.uuid);
            final expectedPrice = SkinPriceHelper.calculateEstimatedPrice(
              isMelee: true,
              tierName: s.tierName ?? 'Exclusive',
              liveStorePrice: livePrice,
              displayName: s.displayName,
            );
            final weapon = (s.weaponName == null || s.weaponName!.toLowerCase() == 'weapon')
                ? 'Melee'
                : s.weaponName;
            return Result.success(s.copyWith(cost: expectedPrice, weaponName: weapon));
          }
          return Result.success(s);
        }
      }
    }

    // Fallback: check wishlist
    final wishlistItem = (await _localStore.getWishlist())
        .where((w) => w.uuid.toLowerCase() == skinUuid.toLowerCase())
        .firstOrNull;
    if (wishlistItem != null) {
      return Result.success(wishlistItem.toSkinItem());
    }

    return const Result.failure(ServerFailure(message: 'Skin not found'));
  }
}
