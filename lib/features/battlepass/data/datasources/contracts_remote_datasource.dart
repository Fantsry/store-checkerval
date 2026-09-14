import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';

abstract class ContractsRemoteDataSource {
  Future<Map<String, dynamic>?> fetchContractsAndMissions({
    required String shard,
    required String puuid,
  });

  Future<Map<String, Map<String, dynamic>>> fetchMissionsMetadata();

  Future<List<Map<String, dynamic>>> fetchContractsMetadata();

  Future<List<Map<String, dynamic>>> fetchSeasonsMetadata();

  Future<Map<String, dynamic>?> fetchRewardDetails({
    required String uuid,
    required String type,
  });
}

class ContractsRemoteDataSourceImpl implements ContractsRemoteDataSource {
  final Dio _dio;

  Map<String, Map<String, dynamic>>? _cachedMissions;
  List<Map<String, dynamic>>? _cachedContracts;
  List<Map<String, dynamic>>? _cachedSeasons;
  final Map<String, Map<String, dynamic>> _cachedRewardDetails = {};

  ContractsRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  static String _normalizeShard(String shard) {
    final s = shard.trim().toLowerCase();
    switch (s) {
      case 'latam':
      case 'br':
      case 'pbe':
      case 'na':
        return 'na';
      case 'eu':
        return 'eu';
      case 'kr':
        return 'kr';
      case 'ap':
      default:
        return s.isNotEmpty ? s : 'ap';
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchContractsAndMissions({
    required String shard,
    required String puuid,
  }) async {
    final cleanPuuid = puuid.trim();
    if (cleanPuuid.isEmpty) return null;

    final normShard = _normalizeShard(shard);
    final shardsToTry = {
      if (normShard.isNotEmpty) normShard,
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    for (final s in shardsToTry) {
      try {
        final url = ApiConstants.contractsUrl(s, cleanPuuid);
        final response = await _dio.get(
          url,
          options: Options(
            headers: {'Accept': 'application/json'},
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          dynamic raw = response.data;
          if (raw is String) {
            try {
              raw = jsonDecode(raw);
            } catch (_) {}
          }
          if (raw is Map) {
            return Map<String, dynamic>.from(raw);
          }
        }
      } on DioException {
        // Individual shard failures (404/400) continue to other candidate shards.
        // 401 triggers AuthInterceptor retry automatically.
        continue;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> fetchMissionsMetadata() async {
    if (_cachedMissions != null) return _cachedMissions!;

    try {
      final response = await _dio.get(ApiConstants.valorantApiMissions);
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        final Map<String, Map<String, dynamic>> map = {};
        for (final item in list) {
          if (item is Map) {
            final uuid = (item['uuid'] ?? '').toString().toLowerCase();
            if (uuid.isNotEmpty) {
              map[uuid] = {
                'title': item['title']?.toString() ??
                    item['displayName']?.toString() ??
                    'Mission Objective',
                'type': item['type']?.toString() ?? 'NPE',
                'xpGrant': item['xpGrant'] as int? ?? 1000,
                'progressToComplete': item['progressToComplete'] as int? ?? 1,
              };
            }
          }
        }
        _cachedMissions = map;
        return map;
      }
    } catch (_) {}
    return _cachedMissions ?? {};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchContractsMetadata() async {
    if (_cachedContracts != null) return _cachedContracts!;

    try {
      final response = await _dio.get(ApiConstants.valorantApiContracts);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _cachedContracts = list;
        return list;
      }
    } catch (_) {}
    return _cachedContracts ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSeasonsMetadata() async {
    if (_cachedSeasons != null) return _cachedSeasons!;

    try {
      final response = await _dio.get(ApiConstants.valorantApiSeasons);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _cachedSeasons = list;
        return list;
      }
    } catch (_) {}
    return _cachedSeasons ?? [];
  }

  @override
  Future<Map<String, dynamic>?> fetchRewardDetails({
    required String uuid,
    required String type,
  }) async {
    final cleanUuid = uuid.trim().toLowerCase();
    if (cleanUuid.isEmpty) return null;

    if (_cachedRewardDetails.containsKey(cleanUuid)) {
      return _cachedRewardDetails[cleanUuid];
    }

    // Direct local resolution for Currencies
    if (type.toLowerCase().contains('currency') ||
        cleanUuid == '85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741' ||
        cleanUuid == 'e59aa87c-4cbf-517a-5983-6e81511be9b7' ||
        cleanUuid == '85ca9543-7697-970b-7caa-e2a3d1a3d49e') {
      String name = 'Valorant Points';
      if (cleanUuid == 'e59aa87c-4cbf-517a-5983-6e81511be9b7') {
        name = 'Radianite Points';
      } else if (cleanUuid == '85ca9543-7697-970b-7caa-e2a3d1a3d49e') {
        name = 'Kingdom Credits';
      }
      final res = {
        'displayName': name,
        'displayIcon':
            'https://media.valorant-api.com/currencies/$cleanUuid/displayicon.png',
        'type': 'Currency',
      };
      _cachedRewardDetails[cleanUuid] = res;
      return res;
    }

    String endpoint;
    final lowerType = type.toLowerCase();
    if (lowerType.contains('skinlevel')) {
      endpoint = '${ApiConstants.valorantApiWeaponSkinLevels}/$cleanUuid';
    } else if (lowerType.contains('charm') || lowerType.contains('buddy')) {
      endpoint = '${ApiConstants.valorantApiBuddies}/levels/$cleanUuid';
    } else if (lowerType.contains('card')) {
      endpoint = '${ApiConstants.valorantApiPlayerCards}/$cleanUuid';
    } else if (lowerType.contains('spray')) {
      endpoint = '${ApiConstants.valorantApiSprays}/$cleanUuid';
    } else if (lowerType.contains('title')) {
      endpoint = '${ApiConstants.valorantApiPlayerTitles}/$cleanUuid';
    } else {
      endpoint = '${ApiConstants.valorantApiBaseUrl}/$lowerType/$cleanUuid';
    }

    try {
      final response = await _dio.get(endpoint);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is Map) {
          final name = data['displayName']?.toString() ??
              data['titleText']?.toString() ??
              'Reward';
          final icon = data['displayIcon']?.toString() ??
              data['smallArt']?.toString() ??
              data['fullTransparentIcon']?.toString();

          final item = {
            'displayName': name,
            'displayIcon': icon,
            'type': type,
          };
          _cachedRewardDetails[cleanUuid] = item;
          return item;
        }
      }
    } catch (_) {}

    return null;
  }
}
