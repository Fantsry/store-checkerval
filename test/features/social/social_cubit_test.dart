import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/domain/repositories/social_repository.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_state.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository mockRepository;
  late SocialCubit cubit;

  final testFriendInGame = FriendEntity(
    puuid: 'p1',
    gameName: 'TenZ',
    tagLine: 'SEN',
    accountLevel: 400,
    cardWideArt: 'https://media.valorant-api.com/playercards/wideart.png',
    cardSmallArt: 'https://media.valorant-api.com/playercards/smallart.png',
    rankName: 'Immortal 3',
    status: FriendLiveStatus.inGame,
    liveActivity: FriendLiveActivity(
      mapName: 'Ascent',
      modeName: 'Competitive',
      agentName: 'Jett',
      scoreAlly: 8,
      scoreEnemy: 5,
      gameStartTime: DateTime(2026, 10, 15, 10, 0),
    ),
    lastUpdated: DateTime(2026, 10, 15, 10, 15),
  );

  final testFriendLobby = FriendEntity(
    puuid: 'p2',
    gameName: 'Chronicle',
    tagLine: 'FNC',
    accountLevel: 250,
    rankName: 'Immortal 1',
    status: FriendLiveStatus.inLobby,
    lastUpdated: DateTime(2026, 10, 15, 10, 15),
  );

  final testFriendOffline = FriendEntity(
    puuid: 'p3',
    gameName: 'Derke',
    tagLine: 'TL',
    accountLevel: 310,
    rankName: 'Immortal 2',
    status: FriendLiveStatus.offline,
    lastUpdated: DateTime(2026, 10, 15, 10, 15),
  );

  final testFriends = [testFriendInGame, testFriendLobby, testFriendOffline];

  setUp(() {
    mockRepository = MockSocialRepository();
    cubit = SocialCubit(socialRepository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('SocialCubit Tests', () {
    test('initial state is SocialInitial', () {
      expect(cubit.state, equals(const SocialInitial()));
    });

    blocTest<SocialCubit, SocialState>(
      'loadFriends emits [SocialLoading, SocialLoaded] on success',
      build: () {
        when(() => mockRepository.getFriends(forceRefresh: false))
            .thenAnswer((_) async => Result.success(testFriends));
        return cubit;
      },
      act: (c) => c.loadFriends(),
      expect: () => [
        const SocialLoading(),
        SocialLoaded(friends: testFriends),
      ],
      verify: (c) {
        final s = c.state as SocialLoaded;
        expect(s.totalCount, 3);
        expect(s.playingCount, 1);
        expect(s.inLobbyCount, 1);
        expect(s.offlineCount, 1);
      },
    );

    test('setFilter filters friends correctly', () async {
      when(() => mockRepository.getFriends(forceRefresh: false))
          .thenAnswer((_) async => Result.success(testFriends));

      await cubit.loadFriends();

      cubit.setFilter(FriendFilter.inGame);
      var state = cubit.state as SocialLoaded;
      expect(state.filteredFriends.length, 1);
      expect(state.filteredFriends.first.gameName, 'TenZ');

      cubit.setFilter(FriendFilter.inLobby);
      state = cubit.state as SocialLoaded;
      expect(state.filteredFriends.length, 1);
      expect(state.filteredFriends.first.gameName, 'Chronicle');

      cubit.setFilter(FriendFilter.offline);
      state = cubit.state as SocialLoaded;
      expect(state.filteredFriends.length, 1);
      expect(state.filteredFriends.first.gameName, 'Derke');
    });

    test('setSearchQuery searches across name, tag, map, mode, agent', () async {
      when(() => mockRepository.getFriends(forceRefresh: false))
          .thenAnswer((_) async => Result.success(testFriends));

      await cubit.loadFriends();

      cubit.setSearchQuery('jett');
      var state = cubit.state as SocialLoaded;
      expect(state.filteredFriends.length, 1);
      expect(state.filteredFriends.first.gameName, 'TenZ');

      cubit.setSearchQuery('ascent');
      state = cubit.state as SocialLoaded;
      expect(state.filteredFriends.length, 1);

      cubit.setSearchQuery('fnc');
      state = cubit.state as SocialLoaded;
      expect(state.filteredFriends.length, 1);
      expect(state.filteredFriends.first.gameName, 'Chronicle');
    });

    test('addFriend prepends friend to list', () async {
      when(() => mockRepository.getFriends(forceRefresh: false))
          .thenAnswer((_) async => Result.success([testFriendLobby]));
      await cubit.loadFriends();

      when(() => mockRepository.addFriend(
            puuid: 'p1',
            gameName: 'TenZ',
            tagLine: 'SEN',
          )).thenAnswer((_) async => Result.success(testFriendInGame));

      final success = await cubit.addFriend(puuid: 'p1', gameName: 'TenZ', tagLine: 'SEN');
      expect(success, isTrue);

      final state = cubit.state as SocialLoaded;
      expect(state.friends.length, 2);
      expect(state.friends.first.puuid, 'p1');
    });

    test('simulateRoundWon updates ally score and round outcome', () async {
      when(() => mockRepository.getFriends(forceRefresh: false))
          .thenAnswer((_) async => Result.success([testFriendInGame]));
      await cubit.loadFriends();

      final updatedFriend = testFriendInGame.copyWith(
        liveActivity: testFriendInGame.liveActivity?.copyWith(
          scoreAlly: 9,
          scoreEnemy: 5,
          roundHistory: [true],
          lastRoundOutcome: 'ALLY_WON',
        ),
      );

      when(() => mockRepository.updateFriendRound(puuid: 'p1', isAllyWon: true))
          .thenAnswer((_) async => Result.success(updatedFriend));

      await cubit.simulateRoundWon('p1');

      final state = cubit.state as SocialLoaded;
      expect(state.friends.first.liveActivity?.scoreAlly, 9);
      expect(state.friends.first.liveActivity?.lastRoundOutcome, 'ALLY_WON');
    });

    test('simulateRoundLost updates enemy score and round outcome', () async {
      when(() => mockRepository.getFriends(forceRefresh: false))
          .thenAnswer((_) async => Result.success([testFriendInGame]));
      await cubit.loadFriends();

      final updatedFriend = testFriendInGame.copyWith(
        liveActivity: testFriendInGame.liveActivity?.copyWith(
          scoreAlly: 8,
          scoreEnemy: 6,
          roundHistory: [false],
          lastRoundOutcome: 'ENEMY_WON',
        ),
      );

      when(() => mockRepository.updateFriendRound(puuid: 'p1', isAllyWon: false))
          .thenAnswer((_) async => Result.success(updatedFriend));

      await cubit.simulateRoundLost('p1');

      final state = cubit.state as SocialLoaded;
      expect(state.friends.first.liveActivity?.scoreEnemy, 6);
      expect(state.friends.first.liveActivity?.lastRoundOutcome, 'ENEMY_WON');
    });
  });
}
