import 'dart:convert';
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
  // Kingdom Credits currency UUID
  static const String kcCurrencyUuid = '85ca9543-7697-970b-7caa-e2a3d1a3d49e';

  @override
  Future<Map<String, dynamic>> getStorefront({
    required String shard,
    required String puuid,
  }) async {
    final cleanPuuid = puuid.trim();
    final normalizedShard = shard.trim().toLowerCase();

    // Try user's configured shard first, then all other live shards
    final shardsToTry = {
      if (normalizedShard.isNotEmpty) normalizedShard,
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    DioException? lastDioException;

    for (final s in shardsToTry) {
      // 1. Primary: POST /store/v3/storefront/{puuid} with empty JSON body
      try {
        final urlV3 = ApiConstants.storefrontV3Url(s, cleanPuuid);
        final response = await _dio.post(
          urlV3,
          data: '{}',
          options: Options(
            contentType: Headers.jsonContentType,
            headers: {'Content-Type': 'application/json'},
          ),
        );

        dynamic rawData = response.data;
        if (rawData is String) {
          try {
            rawData = jsonDecode(rawData);
          } catch (_) {}
        }

        if (rawData is Map) {
          final data = Map<String, dynamic>.from(rawData);
          // Attach the successfully resolved shard
          data['_resolvedShard'] = s;

          // Riot v3 storefront endpoint often omits AccessoryStore (Kingdom Credits shop)
          // or BonusStore (Night Market). If missing, enrich with v2 data on the same shard.
          if (data['AccessoryStore'] == null || data['BonusStore'] == null) {
            try {
              final urlV2 = ApiConstants.storefrontUrl(s, cleanPuuid);
              final responseV2 = await _dio.get(urlV2);
              dynamic rawV2 = responseV2.data;
              if (rawV2 is String) {
                try {
                  rawV2 = jsonDecode(rawV2);
                } catch (_) {}
              }
              if (rawV2 is Map) {
                if (data['AccessoryStore'] == null &&
                    rawV2['AccessoryStore'] != null) {
                  data['AccessoryStore'] = rawV2['AccessoryStore'];
                }
                if (data['BonusStore'] == null &&
                    rawV2['BonusStore'] != null) {
                  data['BonusStore'] = rawV2['BonusStore'];
                }
              }
            } catch (_) {}
          }

          return data;
        }
      } on DioException catch (e) {
        lastDioException = e;
        if (e.response?.statusCode == 401) {
          throw const AuthException(
            message: 'Session expired, please re-authenticate',
          );
        }
        // Fall through to try v2 on this shard
      } catch (_) {
        // Fall through to try v2 on this shard
      }

      // 2. Fallback: GET /store/v2/storefront/{puuid}
      try {
        final urlV2 = ApiConstants.storefrontUrl(s, cleanPuuid);
        final response = await _dio.get(urlV2);

        dynamic rawData = response.data;
        if (rawData is String) {
          try {
            rawData = jsonDecode(rawData);
          } catch (_) {}
        }

        if (rawData is Map) {
          final data = Map<String, dynamic>.from(rawData);
          // Attach the successfully resolved shard
          data['_resolvedShard'] = s;
          return data;
        }
      } on DioException catch (e) {
        lastDioException = e;
        if (e.response?.statusCode == 401) {
          throw const AuthException(
            message: 'Session expired, please re-authenticate',
          );
        }
        // Player not on this shard, try next shard
        continue;
      } catch (_) {
        continue;
      }
    }

    if (lastDioException?.response?.statusCode == 401) {
      throw const AuthException(
        message: 'Session expired, please re-authenticate',
      );
    }

    final statusCode = lastDioException?.response?.statusCode ?? 404;
    throw ServerException(
      message: 'Gagal memuat storefront dari server Riot ($statusCode)',
      statusCode: statusCode,
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

        dynamic rawData = response.data;
        if (rawData is String) {
          try {
            rawData = jsonDecode(rawData);
          } catch (_) {}
        }

        if (rawData is Map) {
          final balances = (rawData['Balances'] as Map?) ?? {};
          final vp = (balances[vpCurrencyUuid] as num?)?.toInt() ?? 0;
          final rp = (balances[rpCurrencyUuid] as num?)?.toInt() ?? 0;
          final kc = (balances[kcCurrencyUuid] as num?)?.toInt() ??
              (balances[kcCurrencyUuid.toUpperCase()] as num?)?.toInt() ??
              0;

          return UserWallet(
            valorantPoints: vp,
            radianitePoints: rp,
            kingdomCredits: kc,
          );
        }
      } catch (_) {
        continue;
      }
    }
    return const UserWallet();
  }
}
