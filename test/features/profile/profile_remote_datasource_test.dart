import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProfileRemoteDataSourceImpl dataSource;

  const puuid = '11111111-2222-3333-4444-555555555555';
  const defaultCardUuid = '9fb348bc-41a0-91ad-8a3e-818035c4e561';
  const equippedCardUuid = '2f4d8e5e-88b3-da7d-4ae9-d1b3bc4c0837';

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = MockDio();
    dataSource = ProfileRemoteDataSourceImpl(dio: dio);
  });

  test('uses a non-default card from the first matching shard', () async {
    when(() => dio.get<dynamic>(
          any(),
          options: any(named: 'options'),
        )).thenAnswer((invocation) async {
      final url = invocation.positionalArguments.first as String;
      final isPrimary = url.contains('pd.ap.a.pvp.net');
      return Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        statusCode: 200,
        data: {
          'Identity': {
            'Subject': puuid,
            'PlayerCardID':
                isPrimary ? defaultCardUuid : equippedCardUuid,
            'PlayerTitleID': 'title-id',
          },
        },
      );
    });

    final result = await dataSource.fetchPlayerIdentity(
      shard: 'ap',
      puuid: puuid,
    );

    expect(result['resolvedShard'], equals('eu'));
    expect(
      (result['identity'] as Map)['PlayerCardID'],
      equals(equippedCardUuid),
    );
  });

  test('ignores a response that belongs to a different Riot account', () async {
    when(() => dio.get<dynamic>(
          any(),
          options: any(named: 'options'),
        )).thenAnswer((invocation) async {
      final url = invocation.positionalArguments.first as String;
      final isPrimary = url.contains('pd.ap.a.pvp.net');
      final isEu = url.contains('pd.eu.a.pvp.net');
      return Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        statusCode: 200,
        data: {
          'Identity': {
            'Subject': isEu ? puuid : 'another-puuid',
            'PlayerCardID':
                isPrimary ? defaultCardUuid : equippedCardUuid,
          },
        },
      );
    });

    final result = await dataSource.fetchPlayerIdentity(
      shard: 'ap',
      puuid: puuid,
    );

    expect(result['resolvedShard'], equals('eu'));
    expect(
      (result['identity'] as Map)['PlayerCardID'],
      equals(equippedCardUuid),
    );
  });

  test('falls back to the real default card when every shard returns default',
      () async {
    when(() => dio.get<dynamic>(
          any(),
          options: any(named: 'options'),
        )).thenAnswer((invocation) async {
      final url = invocation.positionalArguments.first as String;
      return Response<dynamic>(
        requestOptions: RequestOptions(path: url),
        statusCode: 200,
        data: {
          'Identity': {
            'Subject': puuid,
            'PlayerCardID': defaultCardUuid,
          },
        },
      );
    });

    final result = await dataSource.fetchPlayerIdentity(
      shard: 'ap',
      puuid: puuid,
    );

    expect(result['resolvedShard'], equals('ap'));
    expect(
      (result['identity'] as Map)['PlayerCardID'],
      equals(defaultCardUuid),
    );
    verify(() => dio.get<dynamic>(
          ApiConstants.playerLoadoutUrl('ap', puuid),
          options: any(named: 'options'),
        )).called(1);
  });
}
