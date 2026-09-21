import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/constants/api_constants.dart';
import 'package:valorant_store_tracker/features/battlepass/data/datasources/contracts_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ContractsRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = ContractsRemoteDataSourceImpl(dio: mockDio);
  });

  group('ContractsRemoteDataSourceImpl Tests', () {
    test('fetchContractsAndMissions returns Map on HTTP 200', () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'ActiveSpecialContract': 'contract-123', 'Contracts': []},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await dataSource.fetchContractsAndMissions(
        shard: 'ap',
        puuid: 'test-puuid',
      );

      expect(result, isNotNull);
      expect(result!['ActiveSpecialContract'], equals('contract-123'));
    });

    test('fetchContractsAndMissions returns null when request throws DioException', () async {
      when(() => mockDio.get(
            any(),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      final result = await dataSource.fetchContractsAndMissions(
        shard: 'ap',
        puuid: 'test-puuid',
      );

      expect(result, isNull);
    });

    test('fetchMissionsMetadata parses and caches mission data', () async {
      when(() => mockDio.get(ApiConstants.valorantApiMissions))
          .thenAnswer((_) async => Response(
                data: {
                  'data': [
                    {
                      'uuid': 'm-uuid-1',
                      'title': 'Headshot Master',
                      'type': 'EAresMissionType::Daily',
                      'xpGrant': 2000,
                      'progressToComplete': 10,
                    }
                  ]
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final map = await dataSource.fetchMissionsMetadata();

      expect(map.containsKey('m-uuid-1'), isTrue);
      expect(map['m-uuid-1']?['title'], equals('Headshot Master'));
      expect(map['m-uuid-1']?['xpGrant'], equals(2000));
    });

    test('fetchSeasonsMetadata returns list of seasons', () async {
      when(() => mockDio.get(ApiConstants.valorantApiSeasons))
          .thenAnswer((_) async => Response(
                data: {
                  'data': [
                    {
                      'uuid': 'season-1',
                      'displayName': 'Act I',
                    }
                  ]
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final list = await dataSource.fetchSeasonsMetadata();

      expect(list.length, equals(1));
      expect(list.first['uuid'], equals('season-1'));
    });

    test('fetchRewardDetails resolves currency without network call', () async {
      final res = await dataSource.fetchRewardDetails(
        uuid: 'e59aa87c-4cbf-517a-5983-6e81511be9b7',
        type: 'Currency',
      );

      expect(res, isNotNull);
      expect(res!['displayName'], equals('Radianite Points'));
      verifyNever(() => mockDio.get(any()));
    });
  });
}
