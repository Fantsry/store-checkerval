import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/core/error/exceptions.dart';
import 'package:valorant_store_tracker/core/utils/skin_price_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

abstract class ValorantApiRemoteDataSource {
  Future<List<SkinItem>> getWeaponSkins();
  Future<Map<String, Map<String, dynamic>>> getContentTiers();
  Future<Map<String, Map<String, dynamic>>> getBundlesMetadata();
  Future<Map<String, Map<String, dynamic>>> getAccessoriesMetadata();
}

class ValorantApiRemoteDataSourceImpl implements ValorantApiRemoteDataSource {
  final Dio _dio;

  Map<String, Map<String, dynamic>>? _cachedBundles;
  Map<String, Map<String, dynamic>>? _cachedAccessories;

  ValorantApiRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Map<String, Map<String, dynamic>>> getContentTiers() async {
    try {
      final response = await _dio.get(ApiConstants.valorantApiContentTiers);
      final data = response.data['data'] as List<dynamic>? ?? [];

      final tiers = <String, Map<String, dynamic>>{};
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final uuid = item['uuid'] as String? ?? '';
          tiers[uuid] = {
            'name': item['displayName'] as String? ?? 'Standard',
            'color': item['highlightColor'] as String? ?? 'FFFFFF',
            'icon': item['displayIcon'] as String?,
          };
        }
      }
      return tiers;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<List<SkinItem>> getWeaponSkins() async {
    try {
      final tiers = await getContentTiers();

      final response = await _dio.get(
        ApiConstants.valorantApiWeaponSkins,
        queryParameters: {'language': 'en-US'},
      );

      final data = response.data['data'] as List<dynamic>? ?? [];
      final result = <SkinItem>[];

      for (final raw in data) {
        if (raw is! Map<String, dynamic>) continue;

        final uuid = raw['uuid'] as String? ?? '';
        final displayName = raw['displayName'] as String? ?? '';
        final displayIcon = raw['displayIcon'] as String?;
        final contentTierUuid = raw['contentTierUuid'] as String?;

        // Ignore standard base weapons without skin styling
        if (displayName.toLowerCase().contains('standard') ||
            displayName.toLowerCase().contains('random')) {
          continue;
        }

        // Tier info
        final tierInfo = tiers[contentTierUuid];
        final tierName = tierInfo?['name'] as String? ?? 'Select';
        final tierColor = tierInfo?['color'] as String? ?? '5A9FE2';
        final tierIcon = tierInfo?['icon'] as String?;

        // Accurate melee detection and price calculation
        final assetPath = raw['assetPath'] as String? ?? '';
        final isMelee = SkinPriceHelper.isMelee(
          displayName: displayName,
          assetPath: assetPath,
        );

        final estimatedCost = SkinPriceHelper.calculateEstimatedPrice(
          displayName: displayName,
          isMelee: isMelee,
          tierName: tierName,
        );

        // Chromas
        final chromasRaw = raw['chromas'] as List<dynamic>? ?? [];
        final chromas = chromasRaw.map((c) {
          return SkinChroma(
            uuid: c['uuid'] as String? ?? '',
            displayName: c['displayName'] as String? ?? '',
            displayIcon: c['displayIcon'] as String?,
            fullRender: c['fullRender'] as String?,
            streamedVideo: c['streamedVideo'] as String?,
          );
        }).toList();

        // Levels
        final levelsRaw = raw['levels'] as List<dynamic>? ?? [];
        final levels = levelsRaw.map((l) {
          return SkinLevel(
            uuid: l['uuid'] as String? ?? '',
            displayName: l['displayName'] as String? ?? '',
            levelItem: l['levelItem'] as String?,
            displayIcon: l['displayIcon'] as String?,
            streamedVideo: l['streamedVideo'] as String?,
          );
        }).toList();

        // Extract weapon name from display name (e.g. "Prime Vandal" -> "Vandal", Melee skins -> "Melee")
        String? weapon;
        if (isMelee) {
          weapon = 'Melee';
        } else {
          final weapons = [
            'Vandal',
            'Phantom',
            'Operator',
            'Sheriff',
            'Ghost',
            'Classic',
            'Spectre',
            'Odin',
            'Ares',
            'Judge',
            'Bucky',
            'Marshal',
            'Outlaw',
            'Bulldog',
            'Guardian',
            'Stinger',
            'Frenzy',
            'Shorty',
          ];
          for (final w in weapons) {
            if (displayName.toLowerCase().contains(w.toLowerCase())) {
              weapon = w;
              break;
            }
          }
        }

        // Get preview video if any level has it
        String? videoUrl;
        for (final lvl in levels) {
          if (lvl.streamedVideo != null && lvl.streamedVideo!.isNotEmpty) {
            videoUrl = lvl.streamedVideo;
            break;
          }
        }

        // Get icon from chromas if displayIcon is null
        String? icon = displayIcon;
        if (icon == null && chromas.isNotEmpty) {
          icon = chromas.first.displayIcon ?? chromas.first.fullRender;
        }

        result.add(
          SkinItem(
            uuid: uuid,
            displayName: displayName,
            displayIcon: icon,
            weaponName: weapon ?? 'Weapon',
            cost: estimatedCost,
            contentTierUuid: contentTierUuid,
            tierName: tierName,
            tierColor: tierColor,
            tierIcon: tierIcon,
            streamedVideo: videoUrl,
            chromas: chromas,
            levels: levels,
          ),
        );
      }

      return result;
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch skins from Valorant API',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'Error parsing skin catalog: $e');
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getBundlesMetadata() async {
    if (_cachedBundles != null && _cachedBundles!.isNotEmpty) {
      return _cachedBundles!;
    }

    try {
      final response = await _dio.get(ApiConstants.valorantApiBundles);
      final data = response.data['data'] as List<dynamic>? ?? [];

      final bundles = <String, Map<String, dynamic>>{};
      for (final raw in data) {
        if (raw is Map<String, dynamic>) {
          final uuid = (raw['uuid'] ?? '').toString().toLowerCase();
          final displayName = (raw['displayName'] ?? '').toString();
          final displayIcon = raw['displayIcon']?.toString();
          final displayIcon2 = raw['displayIcon2']?.toString();
          final verticalPromo = raw['verticalPromoImage']?.toString();
          final extraDesc = raw['extraDescription']?.toString();

          final bundleMap = {
            'displayName': displayName,
            'displayIcon': displayIcon,
            'displayIcon2': displayIcon2,
            'verticalPromoImage': verticalPromo,
            'extraDescription': extraDesc,
          };

          if (uuid.isNotEmpty) {
            bundles[uuid] = bundleMap;
          }
        }
      }
      _cachedBundles = bundles;
      return bundles;
    } catch (_) {
      return _cachedBundles ?? {};
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getAccessoriesMetadata() async {
    if (_cachedAccessories != null && _cachedAccessories!.isNotEmpty) {
      return _cachedAccessories!;
    }

    try {
      final accessories = <String, Map<String, dynamic>>{};

      // 1. Buddies
      try {
        final res = await _dio.get(ApiConstants.valorantApiBuddies);
        final list = res.data['data'] as List<dynamic>? ?? [];
        for (final b in list) {
          if (b is Map) {
            final uuid = (b['uuid'] ?? '').toString().toLowerCase();
            accessories[uuid] = {
              'displayName': b['displayName']?.toString() ?? 'Gun Buddy',
              'displayIcon': b['displayIcon']?.toString(),
              'itemType': 'Gun Buddy',
            };
            // Also map levels
            final lvls = b['levels'] as List?;
            if (lvls != null) {
              for (final l in lvls) {
                if (l is Map) {
                  final lUuid = (l['uuid'] ?? '').toString().toLowerCase();
                  accessories[lUuid] = {
                    'displayName': b['displayName']?.toString() ?? 'Gun Buddy',
                    'displayIcon': l['displayIcon']?.toString() ?? b['displayIcon']?.toString(),
                    'itemType': 'Gun Buddy',
                  };
                }
              }
            }
          }
        }
      } catch (_) {}

      // 2. Sprays
      try {
        final res = await _dio.get(ApiConstants.valorantApiSprays);
        final list = res.data['data'] as List<dynamic>? ?? [];
        for (final s in list) {
          if (s is Map) {
            final uuid = (s['uuid'] ?? '').toString().toLowerCase();
            accessories[uuid] = {
              'displayName': s['displayName']?.toString() ?? 'Spray',
              'displayIcon': s['fullTransparentIcon']?.toString() ?? s['displayIcon']?.toString(),
              'itemType': 'Spray',
            };
          }
        }
      } catch (_) {}

      // 3. Player Cards
      try {
        final res = await _dio.get(ApiConstants.valorantApiPlayerCards);
        final list = res.data['data'] as List<dynamic>? ?? [];
        for (final c in list) {
          if (c is Map) {
            final uuid = (c['uuid'] ?? '').toString().toLowerCase();
            accessories[uuid] = {
              'displayName': c['displayName']?.toString() ?? 'Player Card',
              'displayIcon': c['largeArt']?.toString() ?? c['wideArt']?.toString() ?? c['smallArt']?.toString(),
              'itemType': 'Player Card',
            };
          }
        }
      } catch (_) {}

      _cachedAccessories = accessories;
      return accessories;
    } catch (_) {
      return _cachedAccessories ?? {};
    }
  }
}
