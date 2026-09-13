import 'dart:convert';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/valorant_api_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';
import 'package:valorant_store_tracker/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource _remoteDataSource;
  final ValorantApiRemoteDataSource _valorantApiDataSource;
  final SecureStorageService _storage;
  final LocalStoreService _localStore;

  InventoryRepositoryImpl({
    required InventoryRemoteDataSource remoteDataSource,
    required ValorantApiRemoteDataSource valorantApiDataSource,
    required SecureStorageService storage,
    required LocalStoreService localStore,
  })  : _remoteDataSource = remoteDataSource,
        _valorantApiDataSource = valorantApiDataSource,
        _storage = storage,
        _localStore = localStore;

  String? _extractPuuidFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      return payload['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<InventoryOverview>> getInventoryOverview({
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Resolve credentials
      var puuid = await _storage.getPuuid();
      if (puuid == null || puuid.isEmpty) {
        final token = await _storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final extracted = _extractPuuidFromJwt(token);
          if (extracted != null && extracted.isNotEmpty) {
            puuid = extracted;
            await _storage.setPuuid(puuid);
          }
        }
      }

      final shard = await _storage.getShard() ?? 'ap';

      if (puuid == null || puuid.isEmpty) {
        return const Result.failure(
          AuthFailure(message: 'No active Riot session. Please sign in.'),
        );
      }

      final cacheKey = 'cached_inventory_overview_v2_$puuid';

      // 2. Check local cache first if not force refresh
      if (!forceRefresh) {
        final cached = _localStore.getMap(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          try {
            final overview = InventoryOverview.fromJson(cached);
            // If the cached overview has skins but 0 battlepass skins while owning > 3 skins,
            // it's likely a stale cache from an older version. Discard and re-fetch!
            final isStale =
                overview.totalSkinsCount > 3 && overview.battlepassSkinsCount == 0;
            if (!isStale) {
              return Result.success(overview);
            }
          } catch (_) {}
        }
      }

      // 3. Fetch entitlements, loadout, all skins database, and battlepass contract reward UUIDs
      final futures = await Future.wait<dynamic>([
        _remoteDataSource.fetchSkinEntitlements(shard: shard, puuid: puuid),
        _remoteDataSource.fetchPlayerLoadout(shard: shard, puuid: puuid),
        _valorantApiDataSource.getWeaponSkins().catchError((_) async {
          final cached = await _localStore.getCachedSkins();
          return cached ?? <SkinItem>[];
        }),
        _remoteDataSource.fetchWeaponsMetadata(),
        _valorantApiDataSource
            .getBattlepassRewardUuids()
            .catchError((_) => <String>{}),
      ]);

      final ownedItemIds = futures[0] as List<String>;
      final loadoutData = futures[1] as Map<String, dynamic>?;
      final allSkins = futures[2] as List<SkinItem>;
      final weaponsMap = futures[3] as Map<String, String>;
      final bpRewardUuids = futures[4] as Set<String>;

      // If fresh skins catalog was obtained, save it to local catalog cache
      if (allSkins.isNotEmpty) {
        await _localStore.saveCachedSkins(allSkins);
      }

      // 4. Index skin catalog:
      // itemId -> SkinItem
      final Map<String, SkinItem> itemToSkinMap = {};
      for (final skin in allSkins) {
        itemToSkinMap[skin.uuid.toLowerCase()] = skin;
        for (final level in skin.levels) {
          itemToSkinMap[level.uuid.toLowerCase()] = skin;
        }
        for (final chroma in skin.chromas) {
          itemToSkinMap[chroma.uuid.toLowerCase()] = skin;
        }
      }

      // 5. Parse equipped loadout
      final Set<String> equippedSkinUuids = {};
      final List<EquippedWeaponSkin> equippedWeapons = [];

      if (loadoutData != null && loadoutData['Guns'] is List) {
        final guns = loadoutData['Guns'] as List<dynamic>;
        for (final gun in guns) {
          if (gun is Map) {
            final weaponId = (gun['ID'] ?? '').toString().toLowerCase();
            final skinId = (gun['SkinID'] ?? '').toString().toLowerCase();
            final skinLevelId =
                (gun['SkinLevelID'] ?? '').toString().toLowerCase();

            final equippedSkin =
                itemToSkinMap[skinId] ?? itemToSkinMap[skinLevelId];

            if (equippedSkin != null) {
              equippedSkinUuids.add(equippedSkin.uuid.toLowerCase());

              final weaponName = weaponsMap[weaponId] ??
                  equippedSkin.displayName.split(' ').last;

              final isBpEquipped = equippedSkin.isBattlepass ||
                  bpRewardUuids.contains(equippedSkin.uuid.toLowerCase()) ||
                  equippedSkin.levels.any(
                      (l) => bpRewardUuids.contains(l.uuid.toLowerCase())) ||
                  equippedSkin.chromas.any(
                      (c) => bpRewardUuids.contains(c.uuid.toLowerCase()));

              equippedWeapons.add(
                EquippedWeaponSkin(
                  weaponId: weaponId,
                  weaponName: weaponName,
                  skinId: equippedSkin.uuid,
                  skinName: equippedSkin.displayName,
                  skinIcon: equippedSkin.displayIcon,
                  tierColor: equippedSkin.tierColor,
                  isBattlepass: isBpEquipped,
                ),
              );
            }
          }
        }
      }

      // 6. Match owned entitlements to unique skins
      final Map<String, SkinItem> uniqueOwnedSkins = {};
      for (final itemId in ownedItemIds) {
        final skin = itemToSkinMap[itemId.toLowerCase()];
        if (skin != null) {
          // Exclude default "Standard" weapons if cost is 0 and name begins with Standard
          final isStandard =
              skin.displayName.toLowerCase().startsWith('standard ');
          if (!isStandard) {
            uniqueOwnedSkins[skin.uuid.toLowerCase()] = skin;
          }
        }
      }

      // 7. Calculate total VP, tier breakdown, and owned skins list
      int totalVp = 0;
      final Map<String, int> tierBreakdown = {
        'Exclusive': 0,
        'Ultra': 0,
        'Premium': 0,
        'Deluxe': 0,
        'Select': 0,
      };

      final List<OwnedSkinItem> ownedSkinsList = [];

      for (final skin in uniqueOwnedSkins.values) {
        final skinUuidLower = skin.uuid.toLowerCase();
        final isBpSkin = skin.isBattlepass ||
            bpRewardUuids.contains(skinUuidLower) ||
            skin.levels
                .any((l) => bpRewardUuids.contains(l.uuid.toLowerCase())) ||
            skin.chromas
                .any((c) => bpRewardUuids.contains(c.uuid.toLowerCase()));

        // Only count store skins for purchase valuation; battlepass rewards are earned via XP
        if (!isBpSkin && skin.cost > 0) {
          totalVp += skin.cost;
        }

        final tier = skin.tierName ?? 'Select';
        if (tierBreakdown.containsKey(tier)) {
          tierBreakdown[tier] = (tierBreakdown[tier] ?? 0) + 1;
        } else {
          tierBreakdown[tier] = 1;
        }

        final isEquipped =
            equippedSkinUuids.contains(skin.uuid.toLowerCase());

        // Extract weapon name
        String weaponName = 'Weapon';
        final words = skin.displayName.split(' ');
        if (words.isNotEmpty) {
          weaponName = words.last;
        }

        ownedSkinsList.add(
          OwnedSkinItem(
            uuid: skin.uuid,
            displayName: skin.displayName,
            displayIcon: skin.displayIcon,
            cost: isBpSkin ? 0 : skin.cost,
            tierName: skin.tierName,
            tierColor: skin.tierColor,
            weapon: weaponName,
            isEquipped: isEquipped,
            isBattlepass: isBpSkin,
          ),
        );
      }

      // Sort owned skins by equipped first, then by cost descending
      ownedSkinsList.sort((a, b) {
        if (a.isEquipped && !b.isEquipped) return -1;
        if (!a.isEquipped && b.isEquipped) return 1;
        return b.cost.compareTo(a.cost);
      });

      // Estimated IDR at ~Rp 135 per VP
      final totalIdr = totalVp * 135;

      final overview = InventoryOverview(
        totalVpSpent: totalVp,
        totalEstimatedIdr: totalIdr,
        totalSkinsCount: ownedSkinsList.length,
        tierBreakdown: tierBreakdown,
        ownedSkins: ownedSkinsList,
        equippedWeapons: equippedWeapons,
      );

      // Cache overview locally per puuid and clear legacy unversioned key
      await _localStore.setMap(cacheKey, overview.toJson());
      await _localStore.deleteMap('cached_inventory_overview');

      return Result.success(overview);
    } catch (e) {
      // If error occurs, fallback to cached overview if available
      final puuid = await _storage.getPuuid();
      final cacheKey = puuid != null && puuid.isNotEmpty
          ? 'cached_inventory_overview_v2_$puuid'
          : 'cached_inventory_overview';
      final cached = _localStore.getMap(cacheKey) ??
          _localStore.getMap('cached_inventory_overview');
      if (cached != null && cached.isNotEmpty) {
        try {
          return Result.success(InventoryOverview.fromJson(cached));
        } catch (_) {}
      }

      final errorMsg = e.toString();
      if (errorMsg.contains('401') ||
          errorMsg.toLowerCase().contains('unauthorized')) {
        return const Result.failure(
          AuthFailure(message: 'Session expired. Please sign in again.'),
        );
      }

      return Result.failure(
        ServerFailure(
          message:
              'Failed to calculate account inventory: ${e.toString().replaceAll(RegExp(r'DioException.*?:'), '').trim()}',
        ),
      );
    }
  }
}
