import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';
import 'package:valorant_store_tracker/features/live_match/domain/repositories/live_match_repository.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';

class MockLiveMatchRepository extends Mock implements LiveMatchRepository {}

void main() {
  late MockLiveMatchRepository mockRepository;
  late LiveMatchCubit cubit;

  const testPlayer = LivePlayerInfo(
    puuid: 'p-1',
    gameName: 'TenZ',
    tagLine: 'SEN',
    teamId: 'Blue',
    agentName: 'Jett',
    currentRankTierName: 'Radiant',
    currentRr: 450,
    peakRankTierName: 'Radiant',
    isSelf: true,
  );

  const testMatch = LiveMatchData(
    phase: LiveMatchPhase.coreGame,
    matchId: 'match-123',
    mapName: 'Ascent',
    modeName: 'Competitive',
    blueTeam: [testPlayer],
    redTeam: [],
  );

  setUp(() {
    mockRepository = MockLiveMatchRepository();
    cubit = LiveMatchCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('LiveMatchData & LivePlayerInfo Entity Tests', () {
    test('isInMatch returns true for preGame and coreGame', () {
      expect(testMatch.isInMatch, isTrue);

      const lobbyMatch = LiveMatchData(phase: LiveMatchPhase.inLobby);
      expect(lobbyMatch.isInMatch, isFalse);
    });

    test('displayName formats gameName #tag correctly', () {
      expect(testPlayer.displayName, equals('TenZ #SEN'));
    });

    test('toJson and fromJson preserves data', () {
      const playerWithStats = LivePlayerInfo(
        puuid: 'p-1',
        gameName: 'TenZ',
        tagLine: 'SEN',
        teamId: 'Blue',
        agentName: 'Jett',
        currentRankTierName: 'Radiant',
        rankIcon: 'https://example.com/radiant.png',
        peakRankTierName: 'Radiant',
        peakRankIcon: 'https://example.com/radiant.png',
        recentWins: 7,
        recentLosses: 3,
        recentMatchOutcomes: [true, true, false, true, false, true, true, false, true, true],
      );

      expect(playerWithStats.recentTotalMatches, equals(10));
      expect(playerWithStats.recentWinRate, equals(70.0));

      final json = playerWithStats.toJson();
      final restored = LivePlayerInfo.fromJson(json);

      expect(restored.recentWins, equals(7));
      expect(restored.recentLosses, equals(3));
      expect(restored.recentTotalMatches, equals(10));
      expect(restored.recentWinRate, equals(70.0));
      expect(restored.recentMatchOutcomes, hasLength(10));
      expect(restored.rankIcon, equals('https://example.com/radiant.png'));
    });
  });

  group('LiveMatchCubit Tests', () {
    test('initial state is LiveMatchInitial', () {
      expect(cubit.state, equals(const LiveMatchInitial()));
    });

    test('emits [LiveMatchLoading, LiveMatchLoaded] on scanLiveMatch success',
        () async {
      when(() => mockRepository.checkLiveMatch())
          .thenAnswer((_) async => const Result.success(testMatch));

      final expectedStates = [
        const LiveMatchLoading(),
        isA<LiveMatchLoaded>()
            .having((s) => s.matchData.mapName, 'mapName', 'Ascent')
            .having((s) => s.matchData.blueTeam.first.agentName, 'agent', 'Jett'),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.scanLiveMatch();
    });
  });
}
