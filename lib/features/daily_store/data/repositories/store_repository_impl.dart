import 'package:valorant_store_tracker/core/error/exceptions.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
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

  @override
  Future<Result<DailyStore>> getDailyStore({bool forceRefresh = false}) async {
    try {
      final puuid = await _secureStorage.getPuuid();
      final shard = await _secureStorage.getShard() ?? 'ap';

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

      // If user is not logged in, check if a real store was cached offline, otherwise require sign-in
      if (puuid == null || puuid.isEmpty) {
        final cached = await _localStore.getCachedDailyStore();
        if (cached != null) {
          return Result.success(cached);
        }
        return const Result.failure(
          AuthFailure(
            message: 'Please sign in with your Riot account to view your live daily store.',
          ),
        );
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
      for (final offer in storeOffers) {
        if (offer is Map) {
          final offerId = offer['OfferID']?.toString().toLowerCase();
          final costMap = offer['Cost'] as Map?;
          final price = (costMap?[RiotStoreRemoteDataSourceImpl.vpCurrencyUuid]
                  as num?)
              ?.toInt() ??
              (costMap?.values.firstOrNull as num?)?.toInt();

          if (price != null) {
            if (offerId != null) itemPrices[offerId] = price;
            final rewards = offer['Rewards'] as List?;
            if (rewards != null && rewards.isNotEmpty && rewards.first is Map) {
              final rId = rewards.first['ItemID']?.toString().toLowerCase();
              if (rId != null) itemPrices[rId] = price;
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
        final realPrice = itemPrices[offerUuid] ?? matched?.cost ?? 1775;

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

      // Parse Featured Bundle if present
      FeaturedBundle? bundle;
      final featuredBundleData =
          storefrontData['FeaturedBundle'] as Map<String, dynamic>?;
      if (featuredBundleData != null) {
        Map<String, dynamic>? bundleDetails;
        if (featuredBundleData['Bundle'] is Map) {
          bundleDetails =
              Map<String, dynamic>.from(featuredBundleData['Bundle'] as Map);
        } else if (featuredBundleData['Bundles'] is List &&
            (featuredBundleData['Bundles'] as List).isNotEmpty &&
            (featuredBundleData['Bundles'] as List).first is Map) {
          bundleDetails = Map<String, dynamic>.from(
              (featuredBundleData['Bundles'] as List).first as Map);
        }

        if (bundleDetails != null) {
          final bUuid = bundleDetails['DataAssetID']?.toString() ?? '';
          final bRemaining = (featuredBundleData[
                  'BundleRemainingDurationInSeconds'] as num?)
              ?.toInt() ??
              0;
          final bundleItemOffers =
              bundleDetails['Items'] as List<dynamic>? ?? [];

          final bundleSkins = <SkinItem>[];
          final totalDiscounted = bundleDetails['TotalDiscountedCost'] as Map?;
          final totalBase = bundleDetails['TotalBaseCost'] as Map?;
          int bundlePrice = (totalDiscounted?[RiotStoreRemoteDataSourceImpl.vpCurrencyUuid] as num?)?.toInt() ??
              (totalBase?[RiotStoreRemoteDataSourceImpl.vpCurrencyUuid] as num?)?.toInt() ??
              0;

          for (final item in bundleItemOffers) {
            if (item is! Map) continue;
            final itemOffer = item['Item'] as Map?;
            final itemUuid =
                itemOffer?['ItemID']?.toString().toLowerCase() ?? '';
            final price = (item['DiscountedPrice'] as num?)?.toInt() ??
                (item['BasePrice'] as num?)?.toInt() ??
                0;
            if (bundlePrice == 0) {
              bundlePrice += price;
            }

            final s = skinMap[itemUuid] ?? levelToSkinMap[itemUuid];
            if (s != null) {
              bundleSkins.add(s.copyWith(cost: price));
            }
          }

          bundle = FeaturedBundle(
            uuid: bUuid,
            displayName: 'Featured Collection',
            price: bundlePrice > 0 ? bundlePrice : 7100,
            remainingDurationSeconds: bRemaining,
            items: bundleSkins,
          );
        }
      }

      final store = DailyStore(
        featuredOffers: dailySkins,
        remainingDurationSeconds: remainingSeconds,
        bundle: bundle,
        lastFetched: DateTime.now(),
      );

      await _localStore.saveDailyStore(store);
      return Result.success(store);
    } on AuthException catch (e) {
      final cached = await _localStore.getCachedDailyStore();
      if (cached != null) return Result.success(cached);
      return Result.failure(
        AuthFailure(message: e.message, statusCode: e.statusCode),
      );
    } catch (e) {
      final cached = await _localStore.getCachedDailyStore();
      if (cached != null) return Result.success(cached);
      String cleanMessage = 'Gagal memuat daily store';
      if (e is ServerException) {
        if (e.statusCode == 404) {
          cleanMessage =
              'Daily store tidak ditemukan untuk akun ini di server Riot. Pastikan Anda sudah login akun Valorant yang aktif.';
        } else if (e.statusCode == 400) {
          cleanMessage =
              'Sesi login Riot tidak valid atau expired (Bad Claims). Silakan sign in ulang dengan akun Riot Anda.';
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
        if (s.uuid.toLowerCase() == skinUuid.toLowerCase()) {
          return Result.success(s);
        }
        for (final lvl in s.levels) {
          if (lvl.uuid.toLowerCase() == skinUuid.toLowerCase()) {
            return Result.success(s);
          }
        }
      }
    }
    return const Result.failure(ServerFailure(message: 'Skin not found'));
  }
}
