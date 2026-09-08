import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/battlepass_overview.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/mission_item.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/repositories/battlepass_repository.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_cubit.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_state.dart';

class MockBattlepassRepository extends Mock implements BattlepassRepository {}

void main() {
  late MockBattlepassRepository mockRepository;
  late BattlepassCubit cubit;

  const testDaily = MissionItem(
    uuid: 'm-1',
    title: 'Play 10 Rounds',
    type: MissionType.daily,
    currentProgress: 6,
    progressToComplete: 10,
    xpReward: 1000,
    isCompleted: false,
  );

  const testWeekly = MissionItem(
    uuid: 'm-2',
    title: 'Use 200 Ultimate Abilities',
    type: MissionType.weekly,
    currentProgress: 200,
    progressToComplete: 200,
    xpReward: 16000,
    isCompleted: true,
  );

  const testOverview = BattlepassOverview(
    battlepassName: 'EPISODE 9 // ACT 2 BATTLEPASS',
    currentTier: 35,
    maxTier: 55,
    currentTierXp: 12000,
    tierXpRequired: 20000,
    totalXpEarned: 350000,
    dailyMissions: [testDaily],
    weeklyMissions: [testWeekly],
    nextRewards: [
      BattlepassRewardItem(
        tier: 36,
        displayName: 'Overlay Player Card',
        rewardType: 'PlayerCard',
        isFree: true,
      ),
    ],
  );

  setUp(() {
    mockRepository = MockBattlepassRepository();
    cubit = BattlepassCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('BattlepassOverview & MissionItem Entity Tests', () {
    test('tierProgressFraction calculates correct percentage', () {
      expect(testOverview.tierProgressFraction, equals(0.6));
    });

    test('mission progressFraction calculates correct percentage', () {
      expect(testDaily.progressFraction, equals(0.6));
      expect(testWeekly.progressFraction, equals(1.0));
    });

    test('toJson and fromJson preserves data', () {
      final json = testOverview.toJson();
      final restored = BattlepassOverview.fromJson(json);

      expect(restored.battlepassName, equals(testOverview.battlepassName));
      expect(restored.currentTier, equals(35));
      expect(restored.dailyMissions.length, equals(1));
      expect(restored.weeklyMissions.length, equals(1));
      expect(restored.nextRewards.length, equals(1));
      expect(restored.nextRewards.first.displayName, equals('Overlay Player Card'));
    });
  });

  group('BattlepassCubit Tests', () {
    test('initial state is BattlepassInitial', () {
      expect(cubit.state, equals(const BattlepassInitial()));
    });

    test('emits [BattlepassLoading, BattlepassLoaded] on success', () async {
      when(() => mockRepository.getBattlepassOverview(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => const Result.success(testOverview));

      final expectedStates = [
        const BattlepassLoading(),
        isA<BattlepassLoaded>()
            .having((s) => s.overview.currentTier, 'currentTier', 35)
            .having((s) => s.overview.dailyMissions.length, 'dailyCount', 1),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadBattlepass();
    });
  });
}
