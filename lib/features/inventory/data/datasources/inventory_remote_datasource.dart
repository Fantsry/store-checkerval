import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';

abstract class InventoryRemoteDataSource {
  Future<List<String>> fetchSkinEntitlements({
    required String shard,
    required String puuid,
  });

  Future<Map<String, dynamic>?> fetchPlayerLoadout({
    required String shard,
    required String puuid,
  });

  Future<Map<String, String>> fetchWeaponsMetadata();
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final Dio _dio;
  Map<String, String>? _cachedWeapons;

  InventoryRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

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
  Future<List<String>> fetchSkinEntitlements({
    required String shard,
    required String puuid,
  }) async {
    final normShard = _normalizeShard(shard);
    final url = ApiConstants.entitlementsUrl(normShard, puuid);

    final response = await _dio.get(url);
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      final entitlementsByTypes =
          data['EntitlementsByTypes'] as List<dynamic>? ?? [];

      final List<String> itemIds = [];
      for (final typeEntry in entitlementsByTypes) {
        if (typeEntry is Map) {
          final entitlements = typeEntry['Entitlements'] as List<dynamic>? ?? [];
          for (final e in entitlements) {
            if (e is Map && e['ItemID'] != null) {
              itemIds.add(e['ItemID'].toString().toLowerCase());
            }
          }
        }
      }
      return itemIds;
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchPlayerLoadout({
    required String shard,
    required String puuid,
  }) async {
    final normShard = _normalizeShard(shard);
    final url = ApiConstants.playerLoadoutUrl(normShard, puuid);

    final response = await _dio.get(url);
    if (response.statusCode == 200 && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<Map<String, String>> fetchWeaponsMetadata() async {
    if (_cachedWeapons != null) return _cachedWeapons!;

    try {
      final response = await _dio.get('https://valorant-api.com/v1/weapons');
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        final Map<String, String> map = {};
        for (final item in list) {
          if (item is Map) {
            final uuid = (item['uuid'] ?? '').toString().toLowerCase();
            final name = (item['displayName'] ?? '').toString();
            if (uuid.isNotEmpty && name.isNotEmpty) {
              map[uuid] = name;
            }
          }
        }
        _cachedWeapons = map;
        return map;
      }
    } catch (_) {}
    return _cachedWeapons ?? {};
  }
}
