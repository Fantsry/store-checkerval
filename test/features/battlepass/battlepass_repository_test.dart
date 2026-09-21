import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/battlepass/data/datasources/contracts_remote_datasource.dart';
import 'package:valorant_store_tracker/features/battlepass/data/repositories/battlepass_repository_impl.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/battlepass_overview.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/mission_item.dart';

class MockContractsRemoteDataSource extends Mock
    implements ContractsRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockLocalStoreService extends Mock implements LocalStoreService {}

void main() {
  late MockContractsRemoteDataSource mockDataSource;
  late MockSecureStorageService mockStorage;
  late MockLocalStoreService mockLocalStore;
  late BattlepassRepositoryImpl repository;

  final sampleContractsMetadata = [
    {
      'uuid': '4ef7ddda-4b73-c349-ee84-e8a9794613b5',
      'displayName': 'CLOSED BETA REWARDS',
      'content': {
        'relationType': 'Season',
        'relationUuid': '0df5adb9-4dcb-6899-1306-3e9860661dd3',
        'chapters': [],
      },
    },
    {
      'uuid': '3f04583c-4c7a-6bdf-65ce-d4b6ff53c5e9',
      'displayName': 'Season 2026 // Act V',
      'content': {
        'relationType': 'Season',
        'relationUuid': '8102cd81-43a0-d0d7-bd59-47b8fe9bed1b',
        'chapters': [
          {
            'levels': [
              {
                'xp': 2000,
                'isFree': false,
                'reward': {
                  'type': 'EquippableSkinLevel',
                  'uuid': 'reward-skin-1',
                  'amount': 1,
                },
              },
              {
                'xp': 2750,
                'isFree': false,
                'reward': {
                  'type': 'EquippableCharmLevel',
                  'uuid': 'reward-buddy-1',
                  'amount': 1,
                },
              },
            ],
            'freeRewards': [],
          },
        ],
      },
    },
  ];

  final sampleSeasonsMetadata = [
    {
      'uuid': '8102cd81-43a0-d0d7-bd59-47b8fe9bed1b',
      'displayName': 'ACT V',
      'type': 'EAresSeasonType::Act',
      'startTime': '2026-08-01T00:00:00Z',
      'endTime': '2026-10-31T00:00:00Z',
    },
  ];

  final sampleMissionsMetadata = {
    'm-daily-1': {
      'title': 'Play 10 Rounds',
      'type': 'EAresMissionType::Daily',
      'xpGrant': 1000,
      'progressToComplete': 10,
    },
    'm-weekly-1': {
      'title': 'Kill 50 Enemies',
      'type': 'EAresMissionType::Weekly',
      'xpGrant': 12000,
      'progressToComplete': 50,
    },
  };

  final samplePlayerContractsData = {
    'ActiveSpecialContract': '3f04583c-4c7a-6bdf-65ce-d4b6ff53c5e9',
    'Contracts': [
      {
        'ContractDefinitionID': '3f04583c-4c7a-6bdf-65ce-d4b6ff53c5e9',
        'ProgressionLevelReached': 1,
        'ProgressionTowardsNextLevel': 1500,
        'ContractProgression': {
          'TotalProgressionEarned': 3500,
        },
      },
    ],
    'Missions': [
      {
        'ID': 'm-daily-1',
        'Objectives': {'m-daily-1': 5},
        'Complete': false,
      },
      {
        'ID': 'm-weekly-1',
        'Objectives': {'m-weekly-1': 50},
        'Complete': true,
      },
    ],
  };

  setUp(() {
    mockDataSource = MockContractsRemoteDataSource();
    mockStorage = MockSecureStorageService();
    mockLocalStore = MockLocalStoreService();

    repository = BattlepassRepositoryImpl(
      remoteDataSource: mockDataSource,
      storage: mockStorage,
      localStore: mockLocalStore,
    );

    when(() => mockLocalStore.getMap(any())).thenReturn(null);
    when(() => mockLocalStore.setMap(any(), any())).thenAnswer((_) async => true);
    when(() => mockStorage.getPuuid()).thenAnswer((_) async => 'test-puuid');
    when(() => mockStorage.getShard()).thenAnswer((_) async => 'ap');
  });

  group('BattlepassRepositoryImpl Tests', () {
    test('returns AuthFailure when PUUID is missing', () async {
      when(() => mockStorage.getPuuid()).thenAnswer((_) async => null);
      when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

      final result = await repository.getBattlepassOverview(forceRefresh: true);

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('Expected failure'),
        failure: (f) => expect(f, isA<AuthFailure>()),
      );
    });

    test('returns ServerFailure when remoteDataSource returns null contractsData', () async {
      when(() => mockDataSource.fetchContractsAndMissions(
            shard: any(named: 'shard'),
            puuid: any(named: 'puuid'),
          )).thenAnswer((_) async => null);
      when(() => mockDataSource.fetchMissionsMetadata())
          .thenAnswer((_) async => sampleMissionsMetadata);
      when(() => mockDataSource.fetchContractsMetadata())
          .thenAnswer((_) async => sampleContractsMetadata);
      when(() => mockDataSource.fetchSeasonsMetadata())
          .thenAnswer((_) async => sampleSeasonsMetadata);

      final result = await repository.getBattlepassOverview(forceRefresh: true);

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('Expected failure'),
        failure: (f) => expect(f, isA<ServerFailure>()),
      );
    });

    test('correctly matches active Battlepass and calculates progression', () async {
      when(() => mockDataSource.fetchContractsAndMissions(
            shard: any(named: 'shard'),
            puuid: any(named: 'puuid'),
          )).thenAnswer((_) async => samplePlayerContractsData);
      when(() => mockDataSource.fetchMissionsMetadata())
          .thenAnswer((_) async => sampleMissionsMetadata);
      when(() => mockDataSource.fetchContractsMetadata())
          .thenAnswer((_) async => sampleContractsMetadata);
      when(() => mockDataSource.fetchSeasonsMetadata())
          .thenAnswer((_) async => sampleSeasonsMetadata);
      when(() => mockDataSource.fetchRewardDetails(
            uuid: any(named: 'uuid'),
            type: any(named: 'type'),
          )).thenAnswer((_) async => {
            'displayName': 'Velocity Skin',
            'displayIcon': 'https://example.com/skin.png',
          });

      final result = await repository.getBattlepassOverview(forceRefresh: true);

      expect(result.isSuccess, isTrue);
      result.when(
        success: (overview) {
          expect(overview.battlepassName, equals('Season 2026 // Act V'));
          expect(overview.currentTier, equals(1));
          expect(overview.currentTierXp, equals(1500));
          expect(overview.tierXpRequired, equals(2750));
          expect(overview.totalXpEarned, equals(3500));

          // Missions
          expect(overview.dailyMissions.length, equals(1));
          expect(overview.dailyMissions.first.title, equals('Play 10 Rounds'));
          expect(overview.dailyMissions.first.currentProgress, equals(5));
          expect(overview.dailyMissions.first.isCompleted, isFalse);

          expect(overview.weeklyMissions.length, equals(1));
          expect(overview.weeklyMissions.first.title, equals('Kill 50 Enemies'));
          expect(overview.weeklyMissions.first.isCompleted, isTrue);

          // Rewards
          expect(overview.nextRewards.length, equals(1));
          expect(overview.nextRewards.first.displayName, equals('Velocity Skin'));
        },
        failure: (f) => fail('Expected success but got: ${f.message}'),
      );
    });
  });
}
