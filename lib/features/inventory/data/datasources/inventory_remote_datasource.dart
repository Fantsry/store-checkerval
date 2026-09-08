import 'dart:convert';
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
    final cleanPuuid = puuid.trim();
    if (cleanPuuid.isEmpty) return [];

    final normalized = _normalizeShard(shard);
    final shardsToTry = {
      if (normalized.isNotEmpty) normalized,
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    final List<String> itemIds = [];

    for (final s in shardsToTry) {
      try {
        final url = ApiConstants.entitlementsUrl(
          s,
          cleanPuuid,
          itemTypeId: ApiConstants.weaponSkinItemTypeId,
        );

        final response = await _dio.get(
          url,
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          _extractItemIds(response.data, itemIds);

          // Also try fetching skin variants/chromas on the same active shard
          try {
            final chromaUrl = ApiConstants.entitlementsUrl(
              s,
              cleanPuuid,
              itemTypeId: ApiConstants.skinChromaItemTypeId,
            );
            final chromaResponse = await _dio.get(
              chromaUrl,
              options: Options(
                validateStatus: (status) => status != null && status < 500,
              ),
            );
            if (chromaResponse.statusCode == 200 &&
                chromaResponse.data != null) {
              _extractItemIds(chromaResponse.data, itemIds);
            }
          } catch (_) {}

          // Successfully retrieved entitlements from this active shard
          return itemIds.toSet().toList();
        }
      } catch (_) {}
    }

    return itemIds.toSet().toList();
  }

  static void _extractItemIds(dynamic data, List<String> out) {
    if (data == null) return;
    dynamic json = data;
    if (json is String) {
      try {
        json = jsonDecode(json);
      } catch (_) {
        return;
      }
    }
    if (json is! Map) return;

    final byTypes = json['EntitlementsByTypes'];
    if (byTypes is List) {
      for (final typeEntry in byTypes) {
        if (typeEntry is Map) {
          final entitlements =
              typeEntry['Entitlements'] as List<dynamic>? ?? [];
          for (final e in entitlements) {
            if (e is Map) {
              final id = e['ItemID'] ?? e['itemId'] ?? e['ItemTypeId'];
              if (id != null) {
                out.add(id.toString().toLowerCase());
              }
            }
          }
        }
      }
    } else if (byTypes is Map) {
      for (final typeEntry in byTypes.values) {
        if (typeEntry is Map) {
          final entitlements =
              typeEntry['Entitlements'] as List<dynamic>? ?? [];
          for (final e in entitlements) {
            if (e is Map) {
              final id = e['ItemID'] ?? e['itemId'];
              if (id != null) {
                out.add(id.toString().toLowerCase());
              }
            }
          }
        }
      }
    }

    final topEntitlements = json['Entitlements'];
    if (topEntitlements is List) {
      for (final e in topEntitlements) {
        if (e is Map) {
          final id = e['ItemID'] ?? e['itemId'];
          if (id != null) {
            out.add(id.toString().toLowerCase());
          }
        }
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchPlayerLoadout({
    required String shard,
    required String puuid,
  }) async {
    final cleanPuuid = puuid.trim();
    if (cleanPuuid.isEmpty) return null;

    final normalized = _normalizeShard(shard);
    final shardsToTry = {
      if (normalized.isNotEmpty) normalized,
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    for (final s in shardsToTry) {
      try {
        final url = ApiConstants.playerLoadoutUrl(s, cleanPuuid);
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
