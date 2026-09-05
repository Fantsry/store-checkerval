import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/core/error/exceptions.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

abstract class ValorantApiRemoteDataSource {
  Future<List<SkinItem>> getWeaponSkins();
  Future<Map<String, Map<String, dynamic>>> getContentTiers();
}

class ValorantApiRemoteDataSourceImpl implements ValorantApiRemoteDataSource {
  final Dio _dio;

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

        // Default cost estimation based on content tier if not provided by storefront
        int estimatedCost = 1775;
        if (tierName.contains('Ultra') || tierName.contains('Exclusive')) {
          estimatedCost = 2175;
        } else if (tierName.contains('Premium')) {
          estimatedCost = 1775;
        } else if (tierName.contains('Deluxe')) {
          estimatedCost = 1275;
        } else if (tierName.contains('Select')) {
          estimatedCost = 875;
        }

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

        // Extract weapon name from display name (e.g. "Prime Vandal" -> "Vandal")
        String? weapon;
        final words = displayName.split(' ');
        if (words.isNotEmpty) {
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
            'Melee',
            'Knife',
            'Blade',
            'Sword',
            'Axe',
            'Dagger',
            'Karambit',
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
}
