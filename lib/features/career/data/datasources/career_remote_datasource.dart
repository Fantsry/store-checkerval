import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';

abstract class CareerRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchMatchHistory({
    required String shard,
    required String puuid,
    int startIndex = 0,
    int endIndex = 15,
  });

  Future<Map<String, dynamic>?> fetchMatchDetails({
    required String shard,
    required String matchId,
  });

  Future<List<Map<String, dynamic>>> fetchCompetitiveUpdates({
    required String shard,
    required String puuid,
    int startIndex = 0,
    int endIndex = 15,
  });

  Future<Map<String, dynamic>?> fetchPlayerMmr({
    required String shard,
    required String puuid,
  });

  Future<Map<String, Map<String, dynamic>>> fetchMapsMetadata();

  Future<Map<String, Map<String, dynamic>>> fetchAgentsMetadata();

  Future<Map<int, Map<String, dynamic>>> fetchCompetitiveTiersMetadata();
}

class CareerRemoteDataSourceImpl implements CareerRemoteDataSource {
  final Dio _dio;

  // In-memory cache for static Valorant-API metadata during session
  Map<String, Map<String, dynamic>>? _cachedMaps;
  Map<String, Map<String, dynamic>>? _cachedAgents;
  Map<int, Map<String, dynamic>>? _cachedTiers;

  CareerRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

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
  Future<List<Map<String, dynamic>>> fetchMatchHistory({
    required String shard,
    required String puuid,
    int startIndex = 0,
    int endIndex = 15,
  }) async {
    final cleanPuuid = puuid.trim();
    if (cleanPuuid.isEmpty) return [];

    final normalized = _normalizeShard(shard);
    final shardsToTry = {normalized, 'ap', 'eu', 'na', 'kr'}.toList();

    for (final s in shardsToTry) {
      try {
        final response = await _dio.get(
          ApiConstants.matchHistoryUrl(
            s,
            cleanPuuid,
            startIndex: startIndex,
            endIndex: endIndex,
          ),
          options: Options(
            headers: {'Accept': 'application/json'},
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != 200) continue;

        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map && body['History'] is List) {
          return (body['History'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      } catch (_) {
        // Try next shard
      }
    }

    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchMatchDetails({
    required String shard,
    required String matchId,
  }) async {
    final cleanMatchId = matchId.trim();
    if (cleanMatchId.isEmpty) return null;

    final normalized = _normalizeShard(shard);
    final shardsToTry = {normalized, 'ap', 'eu', 'na', 'kr'}.toList();

    for (final s in shardsToTry) {
      try {
        final response = await _dio.get(
          ApiConstants.matchDetailsUrl(s, cleanMatchId),
          options: Options(
            headers: {'Accept': 'application/json'},
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != 200) continue;

        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map) {
          return Map<String, dynamic>.from(body);
        }
      } catch (_) {
        // Try next shard
      }
    }

    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCompetitiveUpdates({
    required String shard,
    required String puuid,
    int startIndex = 0,
    int endIndex = 15,
  }) async {
    final cleanPuuid = puuid.trim();
    if (cleanPuuid.isEmpty) return [];

    final normalized = _normalizeShard(shard);
    final shardsToTry = {normalized, 'ap', 'eu', 'na', 'kr'}.toList();

    for (final s in shardsToTry) {
      try {
        final response = await _dio.get(
          ApiConstants.competitiveUpdatesUrl(
            s,
            cleanPuuid,
            startIndex: startIndex,
            endIndex: endIndex,
          ),
          options: Options(
            headers: {'Accept': 'application/json'},
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != 200) continue;

        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map && body['Matches'] is List) {
          return (body['Matches'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      } catch (_) {
        // Try next shard
      }
    }

    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchPlayerMmr({
    required String shard,
    required String puuid,
  }) async {
    final cleanPuuid = puuid.trim();
    if (cleanPuuid.isEmpty) return null;

    final normalized = _normalizeShard(shard);
    final shardsToTry = {normalized, 'ap', 'eu', 'na', 'kr'}.toList();

    for (final s in shardsToTry) {
      try {
        final response = await _dio.get(
          ApiConstants.playerMmrUrl(s, cleanPuuid),
          options: Options(
            headers: {'Accept': 'application/json'},
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != 200) continue;

        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map) {
          return Map<String, dynamic>.from(body);
        }
      } catch (_) {
        // Try next shard
      }
    }

    return null;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> fetchMapsMetadata() async {
    if (_cachedMaps != null && _cachedMaps!.isNotEmpty) {
      return _cachedMaps!;
    }

    try {
      final response = await _dio.get(
        ApiConstants.valorantApiMaps,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map && body['data'] is List) {
          final maps = <String, Map<String, dynamic>>{};
          for (final item in body['data'] as List) {
            if (item is Map) {
              final mapPath = (item['mapUrl'] ?? '').toString();
              final uuid = (item['uuid'] ?? '').toString();
              final displayName = (item['displayName'] ?? '').toString();
              final splash = (item['splash'] ?? item['displayIcon'] ?? '').toString();
              final listViewIcon = (item['listViewIcon'] ?? splash).toString();

              final mapData = {
                'displayName': displayName,
                'splash': splash,
                'listViewIcon': listViewIcon,
              };

              if (mapPath.isNotEmpty) maps[mapPath] = mapData;
              if (mapPath.isNotEmpty) maps[mapPath.toLowerCase()] = mapData;
              if (uuid.isNotEmpty) maps[uuid.toLowerCase()] = mapData;
              if (displayName.isNotEmpty) maps[displayName.toLowerCase()] = mapData;
            }
          }
          _cachedMaps = maps;
          return maps;
        }
      }
    } catch (_) {}

    return _cachedMaps ?? {};
  }

  @override
  Future<Map<String, Map<String, dynamic>>> fetchAgentsMetadata() async {
    if (_cachedAgents != null && _cachedAgents!.isNotEmpty) {
      return _cachedAgents!;
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.valorantApiAgents}?isPlayableCharacter=true',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map && body['data'] is List) {
          final agents = <String, Map<String, dynamic>>{};
          for (final item in body['data'] as List) {
            if (item is Map) {
              final uuid = (item['uuid'] ?? '').toString().toLowerCase();
              final displayName = (item['displayName'] ?? '').toString();
              final displayIcon = (item['displayIcon'] ?? '').toString();

              final agentData = {
                'displayName': displayName,
                'displayIcon': displayIcon,
              };

              if (uuid.isNotEmpty) agents[uuid] = agentData;
              if (displayName.isNotEmpty) agents[displayName.toLowerCase()] = agentData;
            }
          }
          _cachedAgents = agents;
          return agents;
        }
      }
    } catch (_) {}

    return _cachedAgents ?? {};
  }

  @override
  Future<Map<int, Map<String, dynamic>>> fetchCompetitiveTiersMetadata() async {
    if (_cachedTiers != null && _cachedTiers!.isNotEmpty) {
      return _cachedTiers!;
    }

    try {
      final response = await _dio.get(
        ApiConstants.valorantApiCompetitiveTiers,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map && body['data'] is List) {
          final list = body['data'] as List;
          if (list.isNotEmpty) {
            // Pick the latest episode competitive tier set
            final latestEpisode = list.last;
            if (latestEpisode is Map && latestEpisode['tiers'] is List) {
              final tiersMap = <int, Map<String, dynamic>>{};
              for (final t in latestEpisode['tiers'] as List) {
                if (t is Map) {
                  final tierIndex = (t['tier'] as num?)?.toInt() ?? 0;
                  final tierName = (t['tierName'] ?? 'Unrated').toString();
                  final smallIcon = (t['smallIcon'] ?? '').toString();
                  final largeIcon = (t['largeIcon'] ?? smallIcon).toString();

                  tiersMap[tierIndex] = {
                    'tierName': tierName,
                    'smallIcon': smallIcon,
                    'largeIcon': largeIcon,
                  };
                }
              }
              _cachedTiers = tiersMap;
              return tiersMap;
            }
          }
        }
      }
    } catch (_) {}

    return _cachedTiers ?? {};
  }
}
