import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late CareerRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    dataSource = CareerRemoteDataSourceImpl(dio: dio);
  });

  test('fetchMatchHistory throws when every shard request fails', () async {
    when(
      () => dio.get<dynamic>(
        any(),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/match-history'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(
      () => dataSource.fetchMatchHistory(
        shard: 'ap',
        puuid: 'puuid-123',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('fetchMatchHistory returns an empty list for a valid empty history',
      () async {
    when(
      () => dio.get<dynamic>(
        any(),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/match-history'),
        statusCode: 200,
        data: {'History': <dynamic>[]},
      ),
    );

    final history = await dataSource.fetchMatchHistory(
      shard: 'ap',
      puuid: 'puuid-123',
    );

    expect(history, isEmpty);
  });
}
