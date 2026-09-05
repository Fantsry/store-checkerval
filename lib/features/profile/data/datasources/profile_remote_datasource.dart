import 'dart:convert';
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
    final shardsToTry = {
      if (shard.trim().isNotEmpty) shard.trim().toLowerCase(),
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    for (final s in shardsToTry) {
      try {
        final response = await _dio.put(
          ApiConstants.nameServiceUrl(s),
          data: [puuid],
          options: Options(
            contentType: Headers.jsonContentType,
            headers: {'Content-Type': 'application/json'},
          ),
        );

        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is List && body.isNotEmpty) {
          final item = body.first;
          if (item is Map) {
            final gameName = (item['GameName'] ?? item['game_name'] ?? '').toString();
            final tagLine = (item['TagLine'] ?? item['tag_line'] ?? '').toString();
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
    final shardsToTry = {
      if (shard.trim().isNotEmpty) shard.trim().toLowerCase(),
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    for (final s in shardsToTry) {
      try {
        final response = await _dio.get(
          ApiConstants.playerLoadoutUrl(s, puuid),
        );

        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map) {
          final identity = body['Identity'] ?? body['identity'];
          if (identity is Map) {
            return {
              'identity': Map<String, dynamic>.from(identity),
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
    final shardsToTry = {
      if (shard.trim().isNotEmpty) shard.trim().toLowerCase(),
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    for (final s in shardsToTry) {
      try {
        final response = await _dio.get(
          ApiConstants.accountXpUrl(s, puuid),
        );

        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map) {
          final map = Map<String, dynamic>.from(body);
          map['resolvedShard'] = s;
          return map;
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

      dynamic body = response.data;
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {}
      }

      if (body is Map) {
        final data = body['data'] as Map?;
        if (data != null) {
          return {
            'uuid': data['uuid']?.toString() ?? cleanUuid,
            'displayName': data['displayName']?.toString() ?? 'Player Card',
            'smallArt': data['smallArt']?.toString() ?? data['displayIcon']?.toString(),
            'wideArt': data['wideArt']?.toString(),
            'largeArt': data['largeArt']?.toString(),
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

      dynamic body = response.data;
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {}
      }

      if (body is Map) {
        final data = body['data'] as Map?;
        if (data != null) {
          final titleText = data['titleText']?.toString();
          final displayName = data['displayName']?.toString();
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
    final shardsToTry = {
      if (shard.trim().isNotEmpty) shard.trim().toLowerCase(),
      'ap',
      'eu',
      'na',
      'kr',
    }.toList();

    for (final s in shardsToTry) {
      try {
        final response = await _dio.get(
          ApiConstants.walletUrl(s, puuid),
        );

        dynamic body = response.data;
        if (body is String) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }

        if (body is Map) {
          final balances = (body['Balances'] as Map?) ?? {};
          return {
            'vp': (balances[vpCurrencyUuid] as num?)?.toInt() ?? 0,
            'rp': (balances[rpCurrencyUuid] as num?)?.toInt() ?? 0,
            'kc': (balances[kcCurrencyUuid] as num?)?.toInt() ?? 0,
          };
        }
      } catch (_) {}
    }

    return {'vp': 0, 'rp': 0, 'kc': 0};
  }
}
