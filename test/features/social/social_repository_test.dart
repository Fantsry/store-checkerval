import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';
import 'package:valorant_store_tracker/features/live_match/data/datasources/live_match_remote_datasource.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:valorant_store_tracker/features/social/data/repositories/social_repository_impl.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';

class MockLiveMatchRemoteDataSource extends Mock
    implements LiveMatchRemoteDataSource {}

class MockCareerRemoteDataSource extends Mock
    implements CareerRemoteDataSource {}

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockCareerRepository extends Mock implements CareerRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockLocalStoreService extends Mock implements LocalStoreService {}

void main() {
  late MockLiveMatchRemoteDataSource liveDataSource;
  late MockCareerRemoteDataSource careerDataSource;
  late MockProfileRemoteDataSource profileDataSource;
  late MockCareerRepository careerRepository;
  late MockSecureStorageService storage;
  late MockLocalStoreService localStore;
  late SocialRepositoryImpl repository;

  const tPuuid = '11111111-2222-3333-4444-555555555555';
  const tActiveSeasonId = 'season-current';
  const tOldSeasonId = 'season-old';

  setUp(() {
    liveDataSource = MockLiveMatchRemoteDataSource();
    careerDataSource = MockCareerRemoteDataSource();
    profileDataSource = MockProfileRemoteDataSource();
    careerRepository = MockCareerRepository();
    storage = MockSecureStorageService();
    localStore = MockLocalStoreService();

    repository = SocialRepositoryImpl(
      liveDataSource: liveDataSource,
      careerDataSource: careerDataSource,
      profileDataSource: profileDataSource,
      careerRepository: careerRepository,
      storage: storage,
      localStore: localStore,
    );

    when(() => storage.getShard()).thenAnswer((_) async => 'ap');
    when(() => liveDataSource.fetchPlayerNames(
          shard: any(named: 'shard'),
          puuids: any(named: 'puuids'),
        )).thenAnswer((_) async => [
          {'Subject': tPuuid, 'GameName': 'Friend', 'TagLine': '123'},
        ]);
    when(() => profileDataSource.fetchPlayerIdentity(
          shard: any(named: 'shard'),
          puuid: any(named: 'puuid'),
        )).thenAnswer((_) async => {
          'identity': {
            'PlayerCardID': 'card-id',
            'AccountLevel': 42,
          },
        });
    when(() => profileDataSource.fetchPlayerCardDetails(any()))
        .thenAnswer((_) async => {'uuid': 'card-id', 'displayName': 'Card'});
    when(() => localStore.saveFriendJson(any(), any()))
        .thenAnswer((_) async {});
    when(() => careerDataSource.fetchCompetitiveTiersMetadata())
        .thenAnswer((_) async => {
              20: {'tierName': 'Diamond 1', 'largeIcon': 'd1.png'},
              24: {'tierName': 'Ascendant 2', 'largeIcon': 'a2.png'},
            });
    when(() => careerDataSource.fetchSeasonsMetadata()).thenAnswer((_) async => [
          {
            'uuid': tOldSeasonId,
            'displayName': 'ACT OLD',
            'type': 'EAresSeasonType::Act',
            'startTime': '2026-06-01T00:00:00Z',
            'endTime': '2026-10-13T00:00:00Z',
          },
          {
            'uuid': tActiveSeasonId,
            'displayName': 'ACT CURRENT',
            'type': 'EAresSeasonType::Act',
            'startTime': '2026-10-14T00:00:00Z',
            'endTime': '2027-01-06T00:00:00Z',
          },
        ]);
  });

  group('addFriend rank resolution', () {
    test('uses the active act seasonal entry for tier and RR', () async {
      when(() => liveDataSource.fetchPlayerMmr(
            shard: any(named: 'shard'),
            puuid: any(named: 'puuid'),
          )).thenAnswer((_) async => {
            'QueueSkills': {
              'competitive': {
                'SeasonalInfoBySeasonID': {
                  tOldSeasonId: {'CompetitiveTier': 16, 'RankedRating': 10},
                  tActiveSeasonId: {'CompetitiveTier': 24, 'RankedRating': 60},
                },
              },
            },
          });

      final result = await repository.addFriend(puuid: tPuuid);

      expect(result.isSuccess, isTrue);
      final friend = result.valueOrNull!;
      expect(friend.rankTier, equals(24));
      expect(friend.rankedRating, equals(60));
      expect(friend.rankName, equals('Ascendant 2'));
      expect(friend.rankIcon, equals('a2.png'));
    });

    test('does not fall back to a previous act when the current act is reset',
        () async {
      when(() => liveDataSource.fetchPlayerMmr(
            shard: any(named: 'shard'),
            puuid: any(named: 'puuid'),
          )).thenAnswer((_) async => {
            'QueueSkills': {
              'competitive': {
                'SeasonalInfoBySeasonID': {
                  tOldSeasonId: {'CompetitiveTier': 24, 'RankedRating': 99},
                },
              },
            },
          });

      final result = await repository.addFriend(puuid: tPuuid);

      expect(result.isSuccess, isTrue);
      final friend = result.valueOrNull!;
      expect(friend.rankTier, isNull);
      expect(friend.rankedRating, equals(0));
      expect(friend.rankName, equals('Unranked'));
    });

    test('reports placement and keeps a real 0 RR ranked value', () async {
      when(() => liveDataSource.fetchPlayerMmr(
            shard: any(named: 'shard'),
            puuid: any(named: 'puuid'),
          )).thenAnswer((_) async => {
            'QueueSkills': {
              'competitive': {
                'SeasonalInfoBySeasonID': {
                  tActiveSeasonId: {
                    'CompetitiveTier': 20,
                    'RankedRating': 0,
                    'GamesNeededForRating': 2,
                  },
                },
              },
            },
          });

      final result = await repository.addFriend(puuid: tPuuid);

      expect(result.isSuccess, isTrue);
      final friend = result.valueOrNull!;
      expect(friend.rankTier, equals(20));
      expect(friend.rankedRating, equals(0));
      expect(friend.rankName, equals('Placement'));

      final saved = verify(() => localStore.saveFriendJson(tPuuid, captureAny()))
          .captured
          .first as String;
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      expect(decoded['rankedRating'], equals(0));
      expect(FriendEntity.fromJson(decoded).rankedRating, equals(0));
    });
  });
}
