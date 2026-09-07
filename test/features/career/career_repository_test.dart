import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/career/data/repositories/career_repository_impl.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';

class MockCareerRemoteDataSource extends Mock implements CareerRemoteDataSource {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockLocalStoreService extends Mock implements LocalStoreService {}

void main() {
  late MockCareerRemoteDataSource mockRemote;
  late MockSecureStorageService mockSecureStorage;
  late MockLocalStoreService mockLocalStore;
  late CareerRepositoryImpl repository;

  const tPuuid = '11111111-2222-3333-4444-555555555555';
  const tShard = 'ap';

  final tMatchSummary = MatchSummary(
    matchId: 'match-101',
    mapId: '/Game/Maps/Ascent/Ascent',
    mapName: 'Ascent',
    gameMode: 'bomb',
    queueId: 'competitive',
    gameStartTime: DateTime(2026, 9, 7),
    won: true,
    scoreWon: 13,
    scoreLost: 7,
    agentId: 'agent-jett',
    agentName: 'Jett',
    kills: 20,
    deaths: 10,
    assists: 5,
    score: 5000,
    roundsPlayed: 20,
    averageCombatScore: 250,
    headshots: 10,
    bodyshots: 30,
    legshots: 0,
    damage: 3000,
    rankRatingEarned: 24,
    competitiveTier: 15,
    rankName: 'Platinum 1',
  );

  final tCachedOverview = CareerOverview(
    currentTier: 15,
    currentTierName: 'Platinum 1',
    currentRankRating: 70,
    totalMatches: 1,
    totalWins: 1,
    totalLosses: 0,
    winRate: 100.0,
    avgCombatScore: 250,
    avgKdRatio: 2.0,
    avgHeadshotPct: 25.0,
    matches: [tMatchSummary],
  );

  setUp(() {
    mockRemote = MockCareerRemoteDataSource();
    mockSecureStorage = MockSecureStorageService();
    mockLocalStore = MockLocalStoreService();

    when(() => mockSecureStorage.getShard()).thenAnswer((_) async => tShard);

    repository = CareerRepositoryImpl(
      remoteDataSource: mockRemote,
      storage: mockSecureStorage,
      localStore: mockLocalStore,
    );
  });

  group('CareerRepositoryImpl Tests', () {
    test('returns cached overview when valid and forceRefresh is false', () async {
      when(() => mockSecureStorage.getPuuid()).thenAnswer((_) async => tPuuid);
      when(() => mockSecureStorage.getShard()).thenAnswer((_) async => tShard);
      when(() => mockLocalStore.getCachedCareerJson(tPuuid))
          .thenAnswer((_) async => jsonEncode(tCachedOverview.toJson()));

      final result = await repository.getCareerOverview(forceRefresh: false);

      expect(result.isSuccess, true);
      final overview = result.valueOrNull!;
      expect(overview.currentTier, 15);
      expect(overview.currentTierName, 'Platinum 1');
      expect(overview.matches.length, 1);
      expect(overview.matches.first.matchId, 'match-101');
    });

    test('fetches fresh career overview and parses match details & MMR correctly', () async {
      when(() => mockSecureStorage.getPuuid()).thenAnswer((_) async => tPuuid);
      when(() => mockSecureStorage.getShard()).thenAnswer((_) async => tShard);
      when(() => mockLocalStore.getCachedCareerJson(tPuuid))
          .thenAnswer((_) async => null);
      when(() => mockLocalStore.saveCachedCareerJson(tPuuid, any()))
          .thenAnswer((_) async => {});

      // Mock remote responses
      when(() => mockRemote.fetchMatchHistory(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          )).thenAnswer((_) async => [
            {'MatchID': 'match-101'},
          ]);

      when(() => mockRemote.fetchCompetitiveUpdates(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          )).thenAnswer((_) async => [
            {
              'MatchID': 'match-101',
              'TierAfterUpdate': 15,
              'RankRatingAfterUpdate': 74,
              'RankRatingEarned': 24,
            }
          ]);

      when(() => mockRemote.fetchPlayerMmr(shard: tShard, puuid: tPuuid))
          .thenAnswer((_) async => {
                'LatestCompetitiveUpdate': {
                  'TierAfterUpdate': 15,
                  'RankRatingAfterUpdate': 74,
                },
                'QueueSkills': {
                  'competitive': {
                    'SeasonalInfoBySeasonID': {
                      'season-1': {'Rank': 16},
                    }
                  }
                }
              });

      when(() => mockRemote.fetchMapsMetadata()).thenAnswer((_) async => {
            '/game/maps/ascent/ascent': {
              'displayName': 'Ascent',
              'splash': 'https://media.valorant-api.com/maps/ascent/splash.png',
            }
          });

      when(() => mockRemote.fetchAgentsMetadata()).thenAnswer((_) async => {
            'agent-jett': {
              'displayName': 'Jett',
              'displayIcon': 'https://media.valorant-api.com/agents/jett/icon.png',
            }
          });

      when(() => mockRemote.fetchCompetitiveTiersMetadata()).thenAnswer((_) async => {
            15: {'tierName': 'Platinum 1', 'largeIcon': 'https://media.valorant-api.com/tiers/15.png'},
            16: {'tierName': 'Platinum 2', 'largeIcon': 'https://media.valorant-api.com/tiers/16.png'},
          });

      when(() => mockRemote.fetchMatchDetails(shard: tShard, matchId: 'match-101'))
          .thenAnswer((_) async => {
                'matchInfo': {
                  'matchId': 'match-101',
                  'mapId': '/Game/Maps/Ascent/Ascent',
                  'gameMode': 'bomb',
                  'queueID': 'competitive',
                  'gameLengthMillis': 2000000,
                  'gameStartMillis': 1700000000000,
                },
                'players': [
                  {
                    'subject': tPuuid,
                    'teamId': 'Blue',
                    'characterId': 'agent-jett',
                    'stats': {
                      'score': 4800,
                      'kills': 20,
                      'deaths': 10,
                      'assists': 5,
                      'roundsPlayed': 20,
                    },
                    'competitiveTier': 15,
                  }
                ],
                'teams': [
                  {
                    'teamId': 'Blue',
                    'won': true,
                    'roundsWon': 13,
                  },
                  {
                    'teamId': 'Red',
                    'won': false,
                    'roundsWon': 7,
                  }
                ],
                'roundResults': [
                  {
                    'playerStats': [
                      {
                        'subject': tPuuid,
                        'damage': [
                          {
                            'receiver': 'enemy-1',
                            'damage': 150,
                            'headshots': 1,
                            'bodyshots': 2,
                            'legshots': 0,
                          }
                        ]
                      }
                    ]
                  }
                ]
              });

      final result = await repository.getCareerOverview(forceRefresh: true);

      expect(result.isSuccess, true);
      final overview = result.valueOrNull!;
      expect(overview.currentTier, 15);
      expect(overview.currentTierName, 'Platinum 1');
      expect(overview.currentRankRating, 74);
      expect(overview.peakTier, 16);
      expect(overview.peakTierName, 'Platinum 2');
      expect(overview.totalWins, 1);
      expect(overview.winRate, 100.0);
      expect(overview.avgKdRatio, 2.0); // 20 / 10
      expect(overview.matches.length, 1);
      expect(overview.matches.first.matchId, 'match-101');
      expect(overview.matches.first.rankRatingEarned, 24);

      verify(() => mockLocalStore.saveCachedCareerJson(tPuuid, any())).called(1);
    });

    test('returns failure when no puuid session exists', () async {
      when(() => mockSecureStorage.getPuuid()).thenAnswer((_) async => null);
      when(() => mockSecureStorage.getAccessToken()).thenAnswer((_) async => null);

      final result = await repository.getCareerOverview();

      expect(result.isFailure, true);
      expect(result.failureOrNull?.message, contains('No active Riot session'));
    });
  });
}
