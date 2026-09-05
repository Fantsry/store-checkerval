import 'package:dio/dio.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, String>> fetchPlayerName({
    required String shard,
    required String puuid,
  });

  Future<Map<String, dynamic>> fetchPlayerIdentity({
    required String shard,
    required String puuid,
  });

  Future<Map<String, dynamic>> fetchAccountXp({
    required String shard,
    required String puuid,
  });

  Future<Map<String, dynamic>?> fetchPlayerCardDetails(String cardUuid);

  Future<String?> fetchPlayerTitleText(String titleUuid);

  Future<Map<String, int>> fetchWallet({
    required String shard,
    required String puuid,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  // Valorant currency UUIDs
  static const String vpCurrencyUuid = '85ad13f7-3d1b-5128-9eb2-7cd8ee0b5741';
  static const String rpCurrencyUuid = 'e59aa87c-4cbf-517a-5983-6e81511be9b7';
  static const String kcCurrencyUuid = '85ca9543-7697-970b-7caa-e2a3d1a3d49e';

  @override
  Future<Map<String, String>> fetchPlayerName({
    required String shard,
    required String puuid,
  }) async {
    final shardsToTry = {shard.trim().toLowerCase(), 'ap', 'eu', 'na', 'kr'};

    for (final s in shardsToTry) {
      if (s.isEmpty) continue;
      try {
        final response = await _dio.put(
          ApiConstants.nameServiceUrl(s),
          data: [puuid],
        );

        if (response.statusCode == 200 && response.data is List) {
          final list = response.data as List;
          if (list.isNotEmpty) {
            final first = list.first as Map<String, dynamic>;
            final gameName = first['GameName'] as String? ?? '';
            final tagLine = first['TagLine'] as String? ?? '';
            if (gameName.isNotEmpty) {
              return {
                'gameName': gameName,
                'tagLine': tagLine,
                'resolvedShard': s,
              };
            }
          }
        }
      } catch (_) {
        // Try next shard on failure
      }
    }

    return {'gameName': '', 'tagLine': '', 'resolvedShard': shard};
  }

  @override
  Future<Map<String, dynamic>> fetchPlayerIdentity({
    required String shard,
    required String puuid,
  }) async {
    final shardsToTry = {shard.trim().toLowerCase(), 'ap', 'eu', 'na', 'kr'};

    for (final s in shardsToTry) {
      if (s.isEmpty) continue;
      try {
        final response = await _dio.get(
          ApiConstants.playerLoadoutUrl(s, puuid),
        );

        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          final identity = data['Identity'] as Map<String, dynamic>?;
          if (identity != null) {
            return {
              'identity': identity,
              'resolvedShard': s,
            };
          }
        }
      } catch (_) {
        // Try next shard on failure
      }
    }

    return {'identity': <String, dynamic>{}, 'resolvedShard': shard};
  }

  @override
  Future<Map<String, dynamic>> fetchAccountXp({
    required String shard,
    required String puuid,
  }) async {
    final shardsToTry = {shard.trim().toLowerCase(), 'ap', 'eu', 'na', 'kr'};

    for (final s in shardsToTry) {
      if (s.isEmpty) continue;
      try {
        final response = await _dio.get(
          ApiConstants.accountXpUrl(s, puuid),
        );

        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      } catch (_) {
        // Try next shard on failure
      }
    }

    return {};
  }

  @override
  Future<Map<String, dynamic>?> fetchPlayerCardDetails(String cardUuid) async {
    final cleanUuid = cardUuid.trim().toLowerCase();
    if (cleanUuid.isEmpty) return null;

    try {
      final response = await _dio.get(
        ApiConstants.playerCardUrl(cleanUuid),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          return {
            'uuid': data['uuid'] as String? ?? cleanUuid,
            'displayName': data['displayName'] as String? ?? 'Player Card',
            'smallArt': data['smallArt'] as String? ?? data['displayIcon'] as String?,
            'wideArt': data['wideArt'] as String?,
            'largeArt': data['largeArt'] as String?,
          };
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<String?> fetchPlayerTitleText(String titleUuid) async {
    final cleanUuid = titleUuid.trim().toLowerCase();
    if (cleanUuid.isEmpty || cleanUuid == '00000000-0000-0000-0000-000000000000') {
      return null;
    }

    try {
      final response = await _dio.get(
        ApiConstants.playerTitleUrl(cleanUuid),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final titleText = data['titleText'] as String?;
          final displayName = data['displayName'] as String?;
          return titleText ?? displayName;
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<Map<String, int>> fetchWallet({
    required String shard,
    required String puuid,
  }) async {
    final shardsToTry = {shard.trim().toLowerCase(), 'ap', 'eu', 'na', 'kr'};

    for (final s in shardsToTry) {
      if (s.isEmpty) continue;
      try {
        final response = await _dio.get(
          ApiConstants.walletUrl(s, puuid),
        );

        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          final balances = data['Balances'] as Map<String, dynamic>? ?? {};

          return {
            'vp': balances[vpCurrencyUuid] as int? ?? 0,
            'rp': balances[rpCurrencyUuid] as int? ?? 0,
            'kc': balances[kcCurrencyUuid] as int? ?? 0,
          };
        }
      } catch (_) {}
    }

    return {'vp': 0, 'rp': 0, 'kc': 0};
  }
}
