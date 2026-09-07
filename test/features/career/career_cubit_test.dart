import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';

class MockCareerRepository extends Mock implements CareerRepository {}

void main() {
  late MockCareerRepository mockCareerRepository;
  late CareerCubit careerCubit;

  final tCompMatch = MatchSummary(
    matchId: 'match-1',
    mapId: 'ascent',
    mapName: 'Ascent',
    gameMode: 'bomb',
    queueId: 'competitive',
    gameStartTime: DateTime(2026, 9, 7),
    won: true,
    scoreWon: 13,
    scoreLost: 10,
    agentId: 'jett-uuid',
    agentName: 'Jett',
    kills: 20,
    deaths: 12,
    assists: 4,
    score: 5000,
    roundsPlayed: 23,
    averageCombatScore: 217,
    rankRatingEarned: 22,
    competitiveTier: 16,
    rankName: 'Platinum 2',
  );

  final tDmMatch = MatchSummary(
    matchId: 'match-2',
    mapId: 'bind',
    mapName: 'Bind',
    gameMode: 'deathmatch',
    queueId: 'deathmatch',
    gameStartTime: DateTime(2026, 9, 7),
    won: false,
    scoreWon: 35,
    scoreLost: 40,
    agentId: 'reyna-uuid',
    agentName: 'Reyna',
    kills: 35,
    deaths: 18,
    assists: 2,
    score: 3500,
    roundsPlayed: 1,
    averageCombatScore: 350,
  );

  final tOverview = CareerOverview(
    currentTier: 16,
    currentTierName: 'Platinum 2',
    currentRankRating: 54,
    peakTier: 18,
    peakTierName: 'Diamond 1',
    totalMatches: 2,
    totalWins: 1,
    totalLosses: 1,
    winRate: 50.0,
    avgCombatScore: 283,
    avgKdRatio: 1.83,
    avgHeadshotPct: 24.5,
    matches: [tCompMatch, tDmMatch],
  );

  setUp(() {
    mockCareerRepository = MockCareerRepository();
    careerCubit = CareerCubit(careerRepository: mockCareerRepository);
  });

  tearDown(() {
    careerCubit.close();
  });

  group('CareerCubit Tests', () {
    test('initial state is CareerInitial', () {
      expect(careerCubit.state, equals(const CareerInitial()));
    });

    blocTest<CareerCubit, CareerState>(
      'emits [CareerLoading, CareerLoaded] when loadCareer succeeds',
      build: () {
        when(() => mockCareerRepository.getCareerOverview(forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => Result.success(tOverview));
        return careerCubit;
      },
      act: (cubit) => cubit.loadCareer(),
      expect: () => [
        const CareerLoading(cachedOverview: null),
        CareerLoaded(overview: tOverview, selectedQueueFilter: 'all'),
      ],
      verify: (_) {
        verify(() => mockCareerRepository.getCareerOverview(forceRefresh: false)).called(1);
      },
    );

    blocTest<CareerCubit, CareerState>(
      'emits [CareerLoading, CareerError] when loadCareer fails and no cached overview',
      build: () {
        when(() => mockCareerRepository.getCareerOverview(forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => const Result.failure(ServerFailure(message: 'Network timeout')));
        return careerCubit;
      },
      act: (cubit) => cubit.loadCareer(),
      expect: () => [
        const CareerLoading(cachedOverview: null),
        const CareerError('Network timeout', cachedOverview: null),
      ],
    );

    blocTest<CareerCubit, CareerState>(
      'filterQueue updates selectedQueueFilter on CareerLoaded and filters matches',
      build: () => careerCubit,
      seed: () => CareerLoaded(overview: tOverview, selectedQueueFilter: 'all'),
      act: (cubit) => cubit.filterQueue('competitive'),
      expect: () => [
        CareerLoaded(overview: tOverview, selectedQueueFilter: 'competitive'),
      ],
      verify: (cubit) {
        final state = cubit.state as CareerLoaded;
        expect(state.filteredMatches.length, 1);
        expect(state.filteredMatches.first.queueId, 'competitive');
      },
    );

    blocTest<CareerCubit, CareerState>(
      'refresh calls getCareerOverview with forceRefresh: true and keeps current overview during loading',
      build: () {
        when(() => mockCareerRepository.getCareerOverview(forceRefresh: true))
            .thenAnswer((_) async => Result.success(tOverview));
        return careerCubit;
      },
      seed: () => CareerLoaded(overview: tOverview, selectedQueueFilter: 'competitive'),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        CareerLoading(cachedOverview: tOverview),
        CareerLoaded(overview: tOverview, selectedQueueFilter: 'competitive'),
      ],
      verify: (_) {
        verify(() => mockCareerRepository.getCareerOverview(forceRefresh: true)).called(1);
      },
    );
  });
}
