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
}

class ContractsRemoteDataSourceImpl implements ContractsRemoteDataSource {
  final Dio _dio;

  Map<String, Map<String, dynamic>>? _cachedMissions;
  List<Map<String, dynamic>>? _cachedContracts;

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
        return 'ap';
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
            validateStatus: (status) => status != null && status < 500,
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
      } catch (_) {}
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
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _cachedContracts = list;
        return list;
      }
    } catch (_) {}
    return _cachedContracts ?? [];
  }
}
