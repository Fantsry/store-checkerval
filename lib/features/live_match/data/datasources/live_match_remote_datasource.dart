import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';

abstract class LiveMatchRemoteDataSource {
  Future<Map<String, dynamic>?> fetchCoreGamePlayer({
    required String region,
    required String shard,
    required String puuid,
  });

  Future<Map<String, dynamic>?> fetchCoreGameMatch({
    required String region,
    required String shard,
    required String matchId,
  });

  Future<Map<String, dynamic>?> fetchPreGamePlayer({
    required String region,
    required String shard,
    required String puuid,
  });

  Future<Map<String, dynamic>?> fetchPreGameMatch({
    required String region,
    required String shard,
    required String matchId,
  });

  Future<List<Map<String, dynamic>>> fetchPlayerNames({
    required String shard,
    required List<String> puuids,
  });

  Future<Map<String, dynamic>?> fetchPlayerMmr({
    required String shard,
    required String puuid,
  });
}

class LiveMatchRemoteDataSourceImpl implements LiveMatchRemoteDataSource {
  final Dio _dio;

  LiveMatchRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  static String _normalizeShard(String shard) {
    final s = shard.trim().toLowerCase();
    switch (s) {
      case 'latam':
      case 'br':
      case 'na':
        return 'na';
      case 'pbe':
        return 'pbe';
      case 'eu':
        return 'eu';
      case 'kr':
        return 'kr';
      case 'ap':
      default:
        return 'ap';
    }
  }

  static String _normalizeRegion(String region, String shard) {
    final r = region.trim().toLowerCase();
    switch (r) {
      case 'latam':
      case 'br':
      case 'pbe':
      case 'na':
      case 'eu':
      case 'kr':
      case 'ap':
        return r;
      default:
        break;
    }
    // Fallback based on shard
    final s = shard.trim().toLowerCase();
    switch (s) {
      case 'latam':
        return 'latam';
      case 'br':
        return 'br';
      case 'pbe':
        return 'pbe';
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
  Future<Map<String, dynamic>?> fetchCoreGamePlayer({
    required String region,
    required String shard,
    required String puuid,
  }) async {
    try {
      final reg = _normalizeRegion(region, shard);
      final sh = _normalizeShard(shard);
      final url = ApiConstants.coreGamePlayerUrl(reg, sh, puuid);

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      // 404 indicates player is not in a core-game match
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchCoreGameMatch({
    required String region,
    required String shard,
    required String matchId,
  }) async {
    try {
      final reg = _normalizeRegion(region, shard);
      final sh = _normalizeShard(shard);
      final url = ApiConstants.coreGameMatchUrl(reg, sh, matchId);

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchPreGamePlayer({
    required String region,
    required String shard,
    required String puuid,
  }) async {
    try {
      final reg = _normalizeRegion(region, shard);
      final sh = _normalizeShard(shard);
      final url = ApiConstants.preGamePlayerUrl(reg, sh, puuid);

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      // 404 indicates player is not in agent select
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchPreGameMatch({
    required String region,
    required String shard,
    required String matchId,
  }) async {
    try {
      final reg = _normalizeRegion(region, shard);
      final sh = _normalizeShard(shard);
      final url = ApiConstants.preGameMatchUrl(reg, sh, matchId);

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPlayerNames({
    required String shard,
    required List<String> puuids,
  }) async {
    if (puuids.isEmpty) return [];
    try {
      final sh = _normalizeShard(shard);
      final url = ApiConstants.nameServiceUrl(sh);

      final response = await _dio.put(
        url,
        data: puuids,
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchPlayerMmr({
    required String shard,
    required String puuid,
  }) async {
    try {
      final sh = _normalizeShard(shard);
      final url = ApiConstants.playerMmrUrl(sh, puuid);

      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
