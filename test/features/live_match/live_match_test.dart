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
      final json = testMatch.toJson();
      final restored = LiveMatchData.fromJson(json);

      expect(restored.phase, equals(LiveMatchPhase.coreGame));
      expect(restored.matchId, equals('match-123'));
      expect(restored.mapName, equals('Ascent'));
      expect(restored.blueTeam.length, equals(1));
      expect(restored.blueTeam.first.gameName, equals('TenZ'));
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
