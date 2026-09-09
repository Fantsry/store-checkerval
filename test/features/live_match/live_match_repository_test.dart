import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/live_match/data/datasources/live_match_remote_datasource.dart';
import 'package:valorant_store_tracker/features/live_match/data/repositories/live_match_repository_impl.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';

class MockLiveMatchRemoteDataSource extends Mock
    implements LiveMatchRemoteDataSource {}

class MockCareerRemoteDataSource extends Mock
    implements CareerRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockLiveMatchRemoteDataSource mockRemote;
  late MockCareerRemoteDataSource mockCareer;
  late MockSecureStorageService mockStorage;
  late LiveMatchRepositoryImpl repository;

  const tPuuid = 'user-puuid-123';
  const tShard = 'ap';
  const tRegion = 'ap';

  setUp(() {
    mockRemote = MockLiveMatchRemoteDataSource();
    mockCareer = MockCareerRemoteDataSource();
    mockStorage = MockSecureStorageService();

    repository = LiveMatchRepositoryImpl(
      remoteDataSource: mockRemote,
      careerDataSource: mockCareer,
      storage: mockStorage,
    );

    when(() => mockStorage.getPuuid()).thenAnswer((_) async => tPuuid);
    when(() => mockStorage.getShard()).thenAnswer((_) async => tShard);
    when(() => mockStorage.getRegion()).thenAnswer((_) async => tRegion);
    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'fake-token');

    when(() => mockCareer.fetchMapsMetadata()).thenAnswer(
      (_) async => {
        '/game/maps/ascent/ascent': {'displayName': 'Ascent', 'splash': 'ascent.jpg'},
      },
    );
    when(() => mockCareer.fetchAgentsMetadata()).thenAnswer(
      (_) async => {
        'agent-jett-id': {'displayName': 'Jett', 'displayIcon': 'jett.png'},
        'agent-reyna-id': {'displayName': 'Reyna', 'displayIcon': 'reyna.png'},
      },
    );
    when(() => mockCareer.fetchCompetitiveTiersMetadata()).thenAnswer(
      (_) async => {
        0: {'tierName': 'Unranked', 'largeIcon': 'unranked.png'},
        20: {'tierName': 'Diamond 1', 'largeIcon': 'd1.png'},
        24: {'tierName': 'Ascendant 2', 'largeIcon': 'a2.png'},
      },
    );
  });

  group('checkLiveMatch', () {
    test('returns AuthFailure when PUUID and access token are missing', () async {
      when(() => mockStorage.getPuuid()).thenAnswer((_) async => null);
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

      final result = await repository.checkLiveMatch();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
    });

    test('returns inLobby when player is not in core-game or pre-game match',
        () async {
      when(() => mockRemote.fetchCoreGamePlayer(
            region: tRegion,
            shard: tShard,
            puuid: tPuuid,
          )).thenAnswer((_) async => null);
      when(() => mockRemote.fetchPreGamePlayer(
            region: tRegion,
            shard: tShard,
            puuid: tPuuid,
          )).thenAnswer((_) async => null);

      final result = await repository.checkLiveMatch();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.phase, equals(LiveMatchPhase.inLobby));
    });

    test('returns ServerFailure when corePlayer has MatchID but match fetch fails',
        () async {
      when(() => mockRemote.fetchCoreGamePlayer(
            region: tRegion,
            shard: tShard,
            puuid: tPuuid,
          )).thenAnswer((_) async => {'MatchID': 'match-core-123'});
      when(() => mockRemote.fetchCoreGameMatch(
            region: tRegion,
            shard: tShard,
            matchId: 'match-core-123',
          )).thenAnswer((_) async => null);

      final result = await repository.checkLiveMatch();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.message, contains('match-core-123'));
    });

    test('returns AuthFailure when DioException 400 BAD_CLAIMS or 401 occurs',
        () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 400,
          data: {'errorCode': 'BAD_CLAIMS'},
        ),
      );

      when(() => mockRemote.fetchCoreGamePlayer(
            region: tRegion,
            shard: tShard,
            puuid: tPuuid,
          )).thenThrow(dioException);

      final result = await repository.checkLiveMatch();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
    });

    test('returns NetworkFailure on connection timeout', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );

      when(() => mockRemote.fetchCoreGamePlayer(
            region: tRegion,
            shard: tShard,
            puuid: tPuuid,
          )).thenThrow(dioException);

      final result = await repository.checkLiveMatch();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('parses core-game match and aligns teams relative to user perspective (Team Red user)',
        () async {
      when(() => mockRemote.fetchCoreGamePlayer(
            region: tRegion,
            shard: tShard,
            puuid: tPuuid,
          )).thenAnswer((_) async => {'MatchID': 'match-core-999'});

      when(() => mockRemote.fetchCoreGameMatch(
            region: tRegion,
            shard: tShard,
            matchId: 'match-core-999',
          )).thenAnswer((_) async => {
            'MapID': '/Game/Maps/Ascent/Ascent',
            'ModeID': '/Game/GameModes/Bomb/BombGameMode.BombGameMode_C',
            'Players': [
              {
                'Subject': tPuuid,
                'TeamID': 'Red',
                'CharacterID': 'agent-jett-id',
              },
              {
                'Subject': 'ally-puuid',
                'TeamID': 'Red',
                'CharacterID': 'agent-reyna-id',
              },
              {
                'Subject': 'enemy-puuid',
                'TeamID': 'Blue',
                'CharacterID': 'agent-jett-id',
              },
            ],
          });

      when(() => mockRemote.fetchPlayerNames(
            shard: tShard,
            puuids: any(named: 'puuids'),
          )).thenAnswer((_) async => [
            {'Subject': tPuuid, 'GameName': 'SelfPlayer', 'TagLine': '123'},
            {'Subject': 'ally-puuid', 'GameName': 'AllyPlayer', 'TagLine': '456'},
            {'Subject': 'enemy-puuid', 'GameName': 'EnemyPlayer', 'TagLine': '789'},
          ]);

      when(() => mockRemote.fetchPlayerMmr(
            shard: tShard,
            puuid: any(named: 'puuid'),
          )).thenAnswer((_) async => {
            'QueueSkills': {
              'competitive': {
                'Tier': 20,
                'RankedRating': 55,
              },
            },
          });

      final result = await repository.checkLiveMatch();

      expect(result.isSuccess, isTrue);
      final match = result.valueOrNull!;
      expect(match.phase, equals(LiveMatchPhase.coreGame));
      expect(match.mapName, equals('Ascent'));

      // Since user is on Red, user and ally-puuid should be placed into blueTeam (Allies)
      expect(match.blueTeam.length, equals(2));
      expect(match.blueTeam.any((p) => p.puuid == tPuuid && p.isSelf), isTrue);
      expect(match.blueTeam.any((p) => p.puuid == 'ally-puuid'), isTrue);

      // Enemy should be placed into redTeam (Enemies)
      expect(match.redTeam.length, equals(1));
      expect(match.redTeam.first.puuid, equals('enemy-puuid'));
    });
  });
}
