import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/career/data/repositories/career_repository_impl.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';

class MockCareerRemoteDataSource extends Mock
    implements CareerRemoteDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockLocalStoreService extends Mock implements LocalStoreService {}

void main() {
  late MockCareerRemoteDataSource mockRemote;
  late MockSecureStorageService mockSecureStorage;
  late MockLocalStoreService mockLocalStore;
  late CareerRepositoryImpl repository;

  const tPuuid = '11111111-2222-3333-4444-555555555555';
  const tShard = 'ap';
  const tActiveSeasonId = 'season-current';
  const tAllyCardUuid = '8edf22c5-4489-ab41-769a-07adb4c454d6';
  const tEnemyCardUuid = 'd5bb04de-6f2f-4f75-9d3a-92d61f02c3f1';

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
    isRanked: true,
    seasonId: tActiveSeasonId,
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
    when(() => mockRemote.fetchSeasonsMetadata()).thenAnswer(
      (_) async => [
        {
          'uuid': tActiveSeasonId,
          'displayName': 'ACT CURRENT',
          'type': 'EAresSeasonType::Act',
          'startTime': '2026-10-14T00:00:00Z',
          'endTime': '2027-01-06T00:00:00Z',
        },
      ],
    );
    when(
      () => mockLocalStore.getCachedMatchDetails(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockLocalStore.saveCachedMatchDetails(any(), any()),
    ).thenAnswer((_) async => {});
    when(
      () => mockLocalStore.getKnownPlayerCards(),
    ).thenAnswer((_) async => {});
    when(
      () => mockLocalStore.saveKnownPlayerCards(any()),
    ).thenAnswer((_) async {});

    repository = CareerRepositoryImpl(
      remoteDataSource: mockRemote,
      storage: mockSecureStorage,
      localStore: mockLocalStore,
    );
  });

  group('CareerRepositoryImpl Tests', () {
    test(
      'returns cached overview when valid and forceRefresh is false',
      () async {
        when(
          () => mockSecureStorage.getPuuid(),
        ).thenAnswer((_) async => tPuuid);
        when(
          () => mockSecureStorage.getShard(),
        ).thenAnswer((_) async => tShard);
        when(
          () => mockLocalStore.getCachedCareerJson(tPuuid),
        ).thenAnswer((_) async => jsonEncode(tCachedOverview.toJson()));

        final result = await repository.getCareerOverview(forceRefresh: false);

        expect(result.isSuccess, true);
        final overview = result.valueOrNull!;
        expect(overview.currentTier, 15);
        expect(overview.currentTierName, 'Platinum 1');
        expect(overview.matches.length, 1);
        expect(overview.matches.first.matchId, 'match-101');
      },
    );

    test('bootstraps known player cards from cached career data', () async {
      const cachedCardUuid = '8edf22c5-4489-ab41-769a-07adb4c454d6';
      final cachedOverview = CareerOverview(
        matches: [
          MatchSummary(
            matchId: 'cached-match',
            mapId: 'ascent',
            mapName: 'Ascent',
            gameMode: 'bomb',
            queueId: 'competitive',
            gameStartTime: DateTime(2026, 10, 1),
            agentId: 'jett',
            agentName: 'Jett',
            teammates: [
              MatchPlayerSummary(
                puuid: 'cached-ally',
                teamId: 'Blue',
                agentId: 'sage',
                agentName: 'Sage',
                cardUuid: cachedCardUuid,
              ),
            ],
          ),
        ],
      );

      when(() => mockSecureStorage.getPuuid()).thenAnswer((_) async => tPuuid);
      when(
        () => mockLocalStore.getKnownPlayerCards(),
      ).thenAnswer((_) async => {});
      when(
        () => mockLocalStore.getCachedCareerJson(tPuuid),
      ).thenAnswer((_) async => jsonEncode(cachedOverview.toJson()));
      when(
        () => mockLocalStore.saveKnownPlayerCards(any()),
      ).thenAnswer((_) async {});

      final cards = await repository.getKnownPlayerCards();

      expect(cards, {'cached-ally': cachedCardUuid});
      verify(() => mockLocalStore.saveKnownPlayerCards(cards)).called(1);
    });

    test('bootstraps known cards from cached raw match details', () async {
      const cachedCardUuid = '8edf22c5-4489-ab41-769a-07adb4c454d6';
      final cachedOverview = CareerOverview(
        matches: [
          MatchSummary(
            matchId: 'raw-cached-match',
            mapId: 'ascent',
            mapName: 'Ascent',
            gameMode: 'bomb',
            queueId: 'competitive',
            gameStartTime: DateTime(2026, 10, 1),
            agentId: 'jett',
            agentName: 'Jett',
            teammates: [
              const MatchPlayerSummary(
                puuid: 'raw-cached-ally',
                teamId: 'Blue',
                agentId: 'sage',
                agentName: 'Sage',
              ),
            ],
          ),
        ],
      );

      when(() => mockSecureStorage.getPuuid()).thenAnswer((_) async => tPuuid);
      when(
        () => mockLocalStore.getKnownPlayerCards(),
      ).thenAnswer((_) async => {});
      when(
        () => mockLocalStore.getCachedCareerJson(tPuuid),
      ).thenAnswer((_) async => jsonEncode(cachedOverview.toJson()));
      when(
        () => mockLocalStore.getCachedMatchDetails('raw-cached-match'),
      ).thenAnswer(
        (_) async => jsonEncode({
          'players': [
            {'subject': 'raw-cached-ally', 'playerCard': cachedCardUuid},
          ],
        }),
      );
      when(
        () => mockLocalStore.saveKnownPlayerCards(any()),
      ).thenAnswer((_) async {});

      final cards = await repository.getKnownPlayerCards();

      expect(cards, {'raw-cached-ally': cachedCardUuid});
      verify(
        () => mockLocalStore.saveKnownPlayerCards({
          'raw-cached-ally': cachedCardUuid,
        }),
      ).called(1);
    });

    test(
      'fetches fresh career overview and parses match details & MMR correctly',
      () async {
        when(
          () => mockSecureStorage.getPuuid(),
        ).thenAnswer((_) async => tPuuid);
        when(
          () => mockSecureStorage.getShard(),
        ).thenAnswer((_) async => tShard);
        when(
          () => mockLocalStore.getCachedCareerJson(tPuuid),
        ).thenAnswer((_) async => null);
        when(
          () => mockLocalStore.saveCachedCareerJson(tPuuid, any()),
        ).thenAnswer((_) async => {});

        // Mock remote responses
        when(
          () => mockRemote.fetchMatchHistory(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {'MatchID': 'match-101'},
          ],
        );

        when(
          () => mockRemote.fetchCompetitiveUpdates(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'MatchID': 'match-101',
              'SeasonID': tActiveSeasonId,
              'TierAfterUpdate': 15,
              'RankRatingAfterUpdate': 74,
              'RankRatingEarned': 24,
            },
          ],
        );

        when(
          () => mockRemote.fetchPlayerMmr(shard: tShard, puuid: tPuuid),
        ).thenAnswer(
          (_) async => {
            'LatestCompetitiveUpdate': {
              'TierAfterUpdate': 15,
              'RankRatingAfterUpdate': 74,
            },
            'QueueSkills': {
              'competitive': {
                'SeasonalInfoBySeasonID': {
                  tActiveSeasonId: {'CompetitiveTier': 15, 'RankedRating': 74},
                  'season-old': {'Rank': 16},
                },
              },
            },
          },
        );

        when(() => mockRemote.fetchMapsMetadata()).thenAnswer(
          (_) async => {
            '/game/maps/ascent/ascent': {
              'displayName': 'Ascent',
              'splash': 'https://media.valorant-api.com/maps/ascent/splash.png',
            },
          },
        );

        when(() => mockRemote.fetchAgentsMetadata()).thenAnswer(
          (_) async => {
            'agent-jett': {
              'displayName': 'Jett',
              'displayIcon':
                  'https://media.valorant-api.com/agents/jett/icon.png',
            },
          },
        );

        when(() => mockRemote.fetchCompetitiveTiersMetadata()).thenAnswer(
          (_) async => {
            15: {
              'tierName': 'Platinum 1',
              'largeIcon': 'https://media.valorant-api.com/tiers/15.png',
            },
            16: {
              'tierName': 'Platinum 2',
              'largeIcon': 'https://media.valorant-api.com/tiers/16.png',
            },
          },
        );

        when(
          () =>
              mockRemote.fetchMatchDetails(shard: tShard, matchId: 'match-101'),
        ).thenAnswer(
          (_) async => {
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
                'gameName': 'MyPlayer',
                'tagLine': '111',
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
              },
              {
                'subject': 'ally-sage',
                'gameName': 'SageHeal',
                'tagLine': '222',
                'teamId': 'Blue',
                'characterId': 'agent-sage',
                'playerCard': tAllyCardUuid,
                'stats': {
                  'score': 3200,
                  'kills': 14,
                  'deaths': 12,
                  'assists': 10,
                  'roundsPlayed': 20,
                },
                'competitiveTier': 16,
              },
              {
                'subject': 'enemy-reyna',
                'gameName': 'EnemyReyna',
                'tagLine': '333',
                'teamId': 'Red',
                'characterId': 'agent-reyna',
                'playerCard': tEnemyCardUuid,
                'stats': {
                  'score': 5100,
                  'kills': 22,
                  'deaths': 14,
                  'assists': 4,
                  'roundsPlayed': 20,
                },
                'competitiveTier': 15,
              },
            ],
            'teams': [
              {'teamId': 'Blue', 'won': true, 'roundsWon': 13},
              {'teamId': 'Red', 'won': false, 'roundsWon': 7},
            ],
            'roundResults': [
              {
                'roundNum': 0,
                'winningTeam': 'Blue',
                'roundResult': 'Eliminated',
                'playerStats': [
                  {
                    'subject': tPuuid,
                    'kills': [
                      {
                        'roundTime': 45000,
                        'killer': tPuuid,
                        'victim': 'enemy-reyna',
                        'assistants': ['ally-sage'],
                        'finishingDamage': {'damageItem': 'vandal-uuid'},
                      },
                    ],
                    'damage': [
                      {
                        'receiver': 'enemy-1',
                        'damage': 150,
                        'headshots': 1,
                        'bodyshots': 2,
                        'legshots': 0,
                      },
                    ],
                  },
                ],
              },
            ],
          },
        );

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
        expect(overview.matches.first.teammates.length, 2);
        expect(overview.matches.first.enemies.length, 1);
        expect(overview.matches.first.teammates.first.isSelf, true);
        expect(overview.matches.first.teammates[1].displayName, 'SageHeal#222');
        expect(overview.matches.first.teammates[1].rankName, 'Platinum 2');
        expect(overview.matches.first.teammates[1].cardUuid, tAllyCardUuid);
        expect(
          overview.matches.first.enemies.first.displayName,
          'EnemyReyna#333',
        );
        expect(overview.matches.first.enemies.first.rankName, 'Platinum 1');
        expect(overview.matches.first.enemies.first.cardUuid, tEnemyCardUuid);
        expect(
          overview.matches.first.enemies.first.rankIconUrl,
          contains('15.png'),
        );
        final savedCards =
            verify(
                  () => mockLocalStore.saveKnownPlayerCards(captureAny()),
                ).captured.single
                as Map<String, String>;
        expect(savedCards, {
          'ally-sage': tAllyCardUuid,
          'enemy-reyna': tEnemyCardUuid,
        });

        // Verify Round Kills
        expect(overview.matches.first.rounds.length, 1);
        final round = overview.matches.first.rounds.first;
        expect(round.roundNum, 0);
        expect(round.won, true);
        expect(round.roundResult, 'Eliminated');
        expect(round.kills.length, 1);
        final kill = round.kills.first;
        expect(kill.killerPuuid, tPuuid);
        expect(kill.killerName, 'MyPlayer#111');
        expect(kill.isKillerSelf, true);
        expect(kill.victimPuuid, 'enemy-reyna');
        expect(kill.victimName, 'EnemyReyna#333');
        expect(kill.assistantNames, ['SageHeal#222']);
        expect(kill.weaponId, 'vandal-uuid');

        verify(
          () => mockLocalStore.saveCachedCareerJson(tPuuid, any()),
        ).called(1);
      },
    );

    test(
      'correctly parses Riot official MMR field names (RankedRatingEarned, RankedRatingAfterUpdate, and compQueue Tier & RankedRating)',
      () async {
        when(
          () => mockSecureStorage.getPuuid(),
        ).thenAnswer((_) async => tPuuid);
        when(
          () => mockSecureStorage.getShard(),
        ).thenAnswer((_) async => tShard);
        when(
          () => mockLocalStore.getCachedCareerJson(tPuuid),
        ).thenAnswer((_) async => null);
        when(
          () => mockLocalStore.saveCachedCareerJson(tPuuid, any()),
        ).thenAnswer((_) async => {});

        when(
          () => mockRemote.fetchMatchHistory(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {'MatchID': 'match-riot-202'},
          ],
        );

        // Riot official endpoint returns 'RankedRatingEarned' and 'RankedRatingAfterUpdate'
        when(
          () => mockRemote.fetchCompetitiveUpdates(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'MatchID': 'match-riot-202',
              'SeasonID': tActiveSeasonId,
              'TierAfterUpdate': 15,
              'RankedRatingAfterUpdate': 88,
              'RankedRatingEarned': 18,
            },
          ],
        );

        // Riot MMR returns Tier and RankedRating directly under compQueue
        when(
          () => mockRemote.fetchPlayerMmr(shard: tShard, puuid: tPuuid),
        ).thenAnswer(
          (_) async => {
            'QueueSkills': {
              'competitive': {
                'Tier': 15,
                'RankedRating': 88,
                'SeasonalInfoBySeasonID': {
                  tActiveSeasonId: {'CompetitiveTier': 16, 'RankedRating': 50},
                },
              },
            },
          },
        );

        when(() => mockRemote.fetchMapsMetadata()).thenAnswer(
          (_) async => {
            '/game/maps/ascent/ascent': {
              'displayName': 'Ascent',
              'splash': 'https://media.valorant-api.com/maps/ascent/splash.png',
            },
          },
        );

        when(() => mockRemote.fetchAgentsMetadata()).thenAnswer(
          (_) async => {
            'agent-jett': {
              'displayName': 'Jett',
              'displayIcon':
                  'https://media.valorant-api.com/agents/jett/icon.png',
            },
          },
        );

        when(() => mockRemote.fetchCompetitiveTiersMetadata()).thenAnswer(
          (_) async => {
            15: {
              'tierName': 'Platinum 1',
              'largeIcon': 'https://media.valorant-api.com/tiers/15.png',
            },
            16: {
              'tierName': 'Platinum 2',
              'largeIcon': 'https://media.valorant-api.com/tiers/16.png',
            },
          },
        );

        when(
          () => mockRemote.fetchMatchDetails(
            shard: tShard,
            matchId: 'match-riot-202',
          ),
        ).thenAnswer(
          (_) async => {
            'matchInfo': {
              'matchId': 'match-riot-202',
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
              },
            ],
            'teams': [
              {'teamId': 'Blue', 'won': true, 'roundsWon': 13},
              {'teamId': 'Red', 'won': false, 'roundsWon': 7},
            ],
            'roundResults': [],
          },
        );

        final result = await repository.getCareerOverview(forceRefresh: true);

        expect(result.isSuccess, true);
        final overview = result.valueOrNull!;
        expect(overview.currentTier, 16);
        expect(overview.currentRankRating, 50);
        expect(overview.peakTier, 16);
        expect(overview.matches.first.rankRatingEarned, 18);
      },
    );

    test(
      'does not cache an empty overview when match details fail to load',
      () async {
        when(
          () => mockSecureStorage.getPuuid(),
        ).thenAnswer((_) async => tPuuid);
        when(
          () => mockLocalStore.getCachedCareerJson(tPuuid),
        ).thenAnswer((_) async => null);

        when(
          () => mockRemote.fetchMatchHistory(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {'MatchID': 'broken-match'},
          ],
        );
        when(
          () => mockRemote.fetchCompetitiveUpdates(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockRemote.fetchPlayerMmr(shard: tShard, puuid: tPuuid),
        ).thenAnswer((_) async => null);
        when(() => mockRemote.fetchMapsMetadata()).thenAnswer((_) async => {});
        when(
          () => mockRemote.fetchAgentsMetadata(),
        ).thenAnswer((_) async => {});
        when(
          () => mockRemote.fetchCompetitiveTiersMetadata(),
        ).thenAnswer((_) async => {});
        when(
          () => mockRemote.fetchMatchDetails(
            shard: tShard,
            matchId: 'broken-match',
          ),
        ).thenThrow(Exception('match details unavailable'));

        final result = await repository.getCareerOverview(forceRefresh: true);

        expect(result.isFailure, isTrue);
        verifyNever(() => mockLocalStore.saveCachedCareerJson(any(), any()));
      },
    );

    test(
      'uses cached match details from LocalStore without calling remote fetchMatchDetails',
      () async {
        when(
          () => mockSecureStorage.getPuuid(),
        ).thenAnswer((_) async => tPuuid);
        when(
          () => mockSecureStorage.getShard(),
        ).thenAnswer((_) async => tShard);
        when(
          () => mockLocalStore.getCachedCareerJson(tPuuid),
        ).thenAnswer((_) async => null);
        when(
          () => mockLocalStore.saveCachedCareerJson(tPuuid, any()),
        ).thenAnswer((_) async => {});

        when(
          () => mockRemote.fetchMatchHistory(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {'MatchID': 'cached-match-999'},
          ],
        );

        when(
          () => mockRemote.fetchCompetitiveUpdates(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer((_) async => []);

        when(
          () => mockRemote.fetchPlayerMmr(shard: tShard, puuid: tPuuid),
        ).thenAnswer((_) async => null);
        when(() => mockRemote.fetchMapsMetadata()).thenAnswer((_) async => {});
        when(
          () => mockRemote.fetchAgentsMetadata(),
        ).thenAnswer((_) async => {});
        when(
          () => mockRemote.fetchCompetitiveTiersMetadata(),
        ).thenAnswer((_) async => {});

        final cachedMatchMap = {
          'matchInfo': {
            'matchId': 'cached-match-999',
            'mapId': 'ascent',
            'gameMode': 'bomb',
            'queueID': 'competitive',
            'gameStartMillis': 1700000000000,
          },
          'players': [
            {
              'subject': tPuuid,
              'teamId': 'Blue',
              'characterId': 'agent-jett',
              'stats': {
                'score': 3000,
                'kills': 15,
                'deaths': 10,
                'assists': 3,
                'roundsPlayed': 18,
              },
              'competitiveTier': 15,
            },
          ],
          'teams': [
            {'teamId': 'Blue', 'won': true, 'roundsWon': 13},
            {'teamId': 'Red', 'won': false, 'roundsWon': 5},
          ],
          'roundResults': [
            {
              'roundNum': 0,
              'winningTeam': 'Blue',
              'roundResult': 'Eliminated',
              'playerStats': [
                {'subject': tPuuid, 'kills': []},
              ],
            },
          ],
        };

        when(
          () => mockLocalStore.getCachedMatchDetails('cached-match-999'),
        ).thenAnswer((_) async => jsonEncode(cachedMatchMap));

        final result = await repository.getCareerOverview(forceRefresh: true);

        expect(result.isSuccess, true);
        expect(result.valueOrNull?.matches.first.matchId, 'cached-match-999');
        verifyNever(
          () => mockRemote.fetchMatchDetails(
            shard: any(named: 'shard'),
            matchId: 'cached-match-999',
          ),
        );
      },
    );

    test(
      'correctly calculates rankRatingEarned when RankedRatingEarned is null in Riot response',
      () async {
        when(
          () => mockSecureStorage.getPuuid(),
        ).thenAnswer((_) async => tPuuid);
        when(
          () => mockSecureStorage.getShard(),
        ).thenAnswer((_) async => tShard);
        when(
          () => mockLocalStore.getCachedCareerJson(tPuuid),
        ).thenAnswer((_) async => null);
        when(
          () => mockLocalStore.saveCachedCareerJson(tPuuid, any()),
        ).thenAnswer((_) async => {});

        when(
          () => mockRemote.fetchMatchHistory(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {'MatchID': 'match-calculated-rr-1'},
          ],
        );

        // RankedRatingEarned is null, but before/after are present (e.g. Promotion from tier 14 to 15)
        // tier 14 to 15 (+1 tier = +100) + (12 - 88 = -76) => +24 RR earned!
        when(
          () => mockRemote.fetchCompetitiveUpdates(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'MatchID': '{match-calculated-rr-1}',
              'SeasonID': tActiveSeasonId,
              'TierBeforeUpdate': 14,
              'TierAfterUpdate': 15,
              'RankedRatingBeforeUpdate': 88,
              'RankedRatingAfterUpdate': 12,
              'RankedRatingEarned': null,
            },
          ],
        );

        when(
          () => mockRemote.fetchPlayerMmr(shard: tShard, puuid: tPuuid),
        ).thenAnswer(
          (_) async => {
            'LatestCompetitiveUpdate': {
              'TierAfterUpdate': 15,
              'RankedRatingAfterUpdate': 12,
            },
            'QueueSkills': {
              'competitive': {
                'SeasonalInfoBySeasonID': {
                  tActiveSeasonId: {'CompetitiveTier': 15, 'RankedRating': 12},
                },
              },
            },
          },
        );

        when(() => mockRemote.fetchMapsMetadata()).thenAnswer(
          (_) async => {
            '/game/maps/ascent/ascent': {'displayName': 'Ascent'},
          },
        );
        when(() => mockRemote.fetchAgentsMetadata()).thenAnswer(
          (_) async => {
            'agent-jett': {'displayName': 'Jett'},
          },
        );
        when(() => mockRemote.fetchCompetitiveTiersMetadata()).thenAnswer(
          (_) async => {
            14: {'tierName': 'Gold 3'},
            15: {'tierName': 'Platinum 1'},
          },
        );

        when(
          () => mockRemote.fetchMatchDetails(
            shard: tShard,
            matchId: 'match-calculated-rr-1',
          ),
        ).thenAnswer(
          (_) async => {
            'matchInfo': {
              'matchId': 'match-calculated-rr-1',
              'mapId': '/game/maps/ascent/ascent',
              'queueID': 'competitive',
              'gameLengthMillis': 1500000,
              'gameStartMillis': 1700000000000,
            },
            'players': [
              {
                'subject': tPuuid,
                'teamId': 'Blue',
                'characterId': 'agent-jett',
                'stats': {
                  'score': 3000,
                  'kills': 15,
                  'deaths': 10,
                  'assists': 3,
                  'roundsPlayed': 20,
                },
                'competitiveTier': 14,
              },
            ],
            'teams': [
              {'teamId': 'Blue', 'won': true, 'roundsWon': 13},
              {'teamId': 'Red', 'won': false, 'roundsWon': 7},
            ],
            'roundResults': [],
          },
        );

        final result = await repository.getCareerOverview(forceRefresh: true);

        expect(result.isSuccess, true);
        final overview = result.valueOrNull!;
        expect(overview.currentTier, 15);
        expect(overview.currentRankRating, 12);
        expect(overview.matches.first.rankRatingEarned, 24);
        expect(overview.matches.first.competitiveTier, 15);
      },
    );

    test(
      'loadMoreMatches fetches the next page and merges it without duplicates',
      () async {
        when(
          () => mockSecureStorage.getPuuid(),
        ).thenAnswer((_) async => tPuuid);
        when(
          () => mockLocalStore.saveCachedCareerJson(tPuuid, any()),
        ).thenAnswer((_) async => {});

        when(
          () => mockRemote.fetchMatchHistory(
            shard: tShard,
            puuid: tPuuid,
            startIndex: 1,
            endIndex: 11,
          ),
        ).thenAnswer(
          (_) async => [
            {'MatchID': 'match-102'},
          ],
        );
        when(
          () => mockRemote.fetchCompetitiveUpdates(
            shard: tShard,
            puuid: tPuuid,
            startIndex: any(named: 'startIndex'),
            endIndex: any(named: 'endIndex'),
          ),
        ).thenAnswer(
          (_) async => [
            {
              'MatchID': 'match-102',
              'SeasonID': tActiveSeasonId,
              'TierAfterUpdate': 15,
              'RankRatingAfterUpdate': 80,
              'RankRatingEarned': 10,
            },
          ],
        );
        when(() => mockRemote.fetchMapsMetadata()).thenAnswer(
          (_) async => {
            '/game/maps/bind/bind': {
              'displayName': 'Bind',
              'splash': 'https://media.valorant-api.com/maps/bind/splash.png',
            },
          },
        );
        when(() => mockRemote.fetchAgentsMetadata()).thenAnswer(
          (_) async => {
            'agent-omen': {
              'displayName': 'Omen',
              'displayIcon':
                  'https://media.valorant-api.com/agents/omen/icon.png',
            },
          },
        );
        when(() => mockRemote.fetchCompetitiveTiersMetadata()).thenAnswer(
          (_) async => {
            15: {
              'tierName': 'Platinum 1',
              'largeIcon': 'https://media.valorant-api.com/tiers/15.png',
            },
          },
        );
        when(
          () =>
              mockRemote.fetchMatchDetails(shard: tShard, matchId: 'match-102'),
        ).thenAnswer(
          (_) async => {
            'matchInfo': {
              'matchId': 'match-102',
              'mapId': '/Game/Maps/Bind/Bind',
              'gameMode': 'bomb',
              'queueID': 'competitive',
              'gameLengthMillis': 2000000,
              'gameStartMillis': 1700000000001,
            },
            'players': [
              {
                'subject': tPuuid,
                'teamId': 'Blue',
                'characterId': 'agent-omen',
                'stats': {
                  'score': 4000,
                  'kills': 15,
                  'deaths': 12,
                  'assists': 6,
                  'roundsPlayed': 20,
                },
                'competitiveTier': 15,
              },
            ],
            'teams': [
              {'teamId': 'Blue', 'won': false, 'roundsWon': 9},
              {'teamId': 'Red', 'won': true, 'roundsWon': 13},
            ],
            'roundResults': [],
          },
        );

        final current = tCachedOverview.withMatches([
          tMatchSummary,
        ], hasMore: true);
        final result = await repository.loadMoreMatches(current);

        expect(result.isSuccess, true);
        final overview = result.valueOrNull!;
        expect(overview.matches.length, 2);
        expect(
          overview.matches.map((m) => m.matchId),
          containsAll(['match-101', 'match-102']),
        );
        expect(overview.hasMore, false);
        expect(overview.totalWins, 1);
        expect(overview.totalLosses, 1);
      },
    );

    test('returns failure when no puuid session exists', () async {
      when(() => mockSecureStorage.getPuuid()).thenAnswer((_) async => null);
      when(
        () => mockSecureStorage.getAccessToken(),
      ).thenAnswer((_) async => null);

      final result = await repository.getCareerOverview();

      expect(result.isFailure, true);
      expect(result.failureOrNull?.message, contains('No active Riot session'));
    });
  });
}
