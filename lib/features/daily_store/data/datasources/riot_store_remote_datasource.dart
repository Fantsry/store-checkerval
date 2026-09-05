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
    try {
      final url = ApiConstants.storefrontUrl(shard, puuid);
      final response = await _dio.get(url);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthException(message: 'Session expired, please re-authenticate');
      }
      throw ServerException(
        message: e.message ?? 'Failed to load storefront',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserWallet> getWallet({
    required String shard,
    required String puuid,
  }) async {
    try {
      final url = ApiConstants.walletUrl(shard, puuid);
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
      return const UserWallet();
    }
  }
}
