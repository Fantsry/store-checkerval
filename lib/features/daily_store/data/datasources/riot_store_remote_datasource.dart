import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/core/error/exceptions.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';

abstract class RiotStoreRemoteDataSource {
  Future<Map<String, dynamic>> getStorefront({
    required String shard,
    required String puuid,
  });

  Future<UserWallet> getWallet({
    required String shard,
    required String puuid,
  });
}

class RiotStoreRemoteDataSourceImpl implements RiotStoreRemoteDataSource {
  final Dio _dio;

  RiotStoreRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  // Valorant Points currency UUID
  static const String vpCurrencyUuid = '85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741';
  // Radianite Points currency UUID
  static const String rpCurrencyUuid = 'e59aa87c-4cbf-517a-5983-6e81511be9b7';

  @override
  Future<Map<String, dynamic>> getStorefront({
    required String shard,
    required String puuid,
  }) async {
    final cleanPuuid = puuid.trim();
    final normalizedShard = shard.trim().toLowerCase();

    // Try user's configured shard first, then all other live shards if 404
    final shardsToTry = {
      if (normalizedShard.isNotEmpty) normalizedShard,
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    DioException? lastDioException;

    for (final s in shardsToTry) {
      for (final version in ['v2', 'v3']) {
        try {
          final url = 'https://pd.$s.a.pvp.net/store/$version/storefront/$cleanPuuid';
          final response = await _dio.get(url);
          if (response.data is Map<String, dynamic>) {
            final data = Map<String, dynamic>.from(response.data as Map);
            // Attach the successfully resolved shard
            data['_resolvedShard'] = s;
            return data;
          }
        } on DioException catch (e) {
          lastDioException = e;
          if (e.response?.statusCode == 404) {
            // Player not on this shard or version, continue trying next
            continue;
          }
          if (e.response?.statusCode == 401) {
            throw const AuthException(message: 'Session expired, please re-authenticate');
          }
          // Continue trying other candidates
          continue;
        } catch (_) {
          continue;
        }
      }
    }

    if (lastDioException?.response?.statusCode == 401) {
      throw const AuthException(message: 'Session expired, please re-authenticate');
    }
    throw ServerException(
      message: lastDioException?.message ?? 'Failed to load storefront across all shards',
      statusCode: lastDioException?.response?.statusCode ?? 404,
    );
  }

  @override
  Future<UserWallet> getWallet({
    required String shard,
    required String puuid,
  }) async {
    final cleanPuuid = puuid.trim();
    final normalizedShard = shard.trim().toLowerCase();

    final shardsToTry = {
      if (normalizedShard.isNotEmpty) normalizedShard,
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    for (final s in shardsToTry) {
      try {
        final url = ApiConstants.walletUrl(s, cleanPuuid);
        final response = await _dio.get(url);
        final data = response.data as Map<String, dynamic>;
        final balances = data['Balances'] as Map<String, dynamic>? ?? {};

        final vp = balances[vpCurrencyUuid] as int? ?? 0;
        final rp = balances[rpCurrencyUuid] as int? ?? 0;

        return UserWallet(
          valorantPoints: vp,
          radianitePoints: rp,
        );
      } catch (_) {
        continue;
      }
    }
    return const UserWallet();
  }
}
