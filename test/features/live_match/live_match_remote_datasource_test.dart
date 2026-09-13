import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/features/live_match/data/datasources/live_match_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late LiveMatchRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = LiveMatchRemoteDataSourceImpl(dio: mockDio);
  });

  group('LiveMatchRemoteDataSourceImpl String/Map response resilience', () {
    const region = 'ap';
    const shard = 'ap';
    const puuid = 'test-puuid-123';
    const matchId = 'test-match-456';

    test('fetchCoreGamePlayer parses JSON String successfully', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: '{"Subject": "$puuid", "MatchID": "$matchId", "Version": 1}',
        ),
      );

      final result = await dataSource.fetchCoreGamePlayer(
        region: region,
        shard: shard,
        puuid: puuid,
      );

      expect(result, isNotNull);
      expect(result?['Subject'], equals(puuid));
      expect(result?['MatchID'], equals(matchId));
    });

    test('fetchCoreGamePlayer returns null on empty String', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: '   ',
        ),
      );

      final result = await dataSource.fetchCoreGamePlayer(
        region: region,
        shard: shard,
        puuid: puuid,
      );

      expect(result, isNull);
    });

    test('fetchCoreGamePlayer returns null on 404 DioException', () async {
      when(() => mockDio.get(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
        ),
      );

      final result = await dataSource.fetchCoreGamePlayer(
        region: region,
        shard: shard,
        puuid: puuid,
      );

      expect(result, isNull);
    });

    test('fetchPreGamePlayer parses JSON String successfully', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: '{"Subject": "$puuid", "MatchID": "$matchId"}',
        ),
      );

      final result = await dataSource.fetchPreGamePlayer(
        region: region,
        shard: shard,
        puuid: puuid,
      );

      expect(result, isNotNull);
      expect(result?['MatchID'], equals(matchId));
    });

    test('fetchCoreGameMatch parses Map response correctly', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {
            'MatchID': matchId,
            'MapID': '/Game/Maps/Ascent/Ascent',
          },
        ),
      );

      final result = await dataSource.fetchCoreGameMatch(
        region: region,
        shard: shard,
        matchId: matchId,
      );

      expect(result, isNotNull);
      expect(result?['MatchID'], equals(matchId));
    });

    test('fetchPlayerNames parses JSON String of List', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: '[{"Subject": "$puuid", "GameName": "Player", "TagLine": "123"}]',
        ),
      );

      final result = await dataSource.fetchPlayerNames(
        shard: shard,
        puuids: [puuid],
      );

      expect(result, hasLength(1));
      expect(result.first['GameName'], equals('Player'));
      expect(result.first['TagLine'], equals('123'));
    });

    test('fetchPlayerMmr parses JSON String response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: '{"QueueSkills": {"competitive": {"Tier": 20, "RankedRating": 50}}}',
        ),
      );

      final result = await dataSource.fetchPlayerMmr(
        shard: shard,
        puuid: puuid,
      );

      expect(result, isNotNull);
      expect(result?['QueueSkills'], isNotNull);
    });
  });
}
