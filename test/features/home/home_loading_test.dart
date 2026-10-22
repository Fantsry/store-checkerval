import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/repositories/battlepass_repository.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_cubit.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/home/presentation/pages/home_page.dart';
import 'package:valorant_store_tracker/features/live_match/domain/repositories/live_match_repository.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/features/social/domain/repositories/social_repository.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockCareerRepository extends Mock implements CareerRepository {}

class _MockStoreRepository extends Mock implements StoreRepository {}

class _MockBattlepassRepository extends Mock implements BattlepassRepository {}

class _MockSocialRepository extends Mock implements SocialRepository {}

class _MockLiveMatchRepository extends Mock implements LiveMatchRepository {}

class _StubProfileCubit extends ProfileCubit {
  _StubProfileCubit() : super(profileRepository: _MockProfileRepository());

  @override
  Future<void> loadProfile({bool forceRefresh = false}) async {}

  void seed(ProfileState state) => emit(state);
}

class _StubCareerCubit extends CareerCubit {
  _StubCareerCubit() : super(careerRepository: _MockCareerRepository());

  @override
  Future<void> loadCareer({bool forceRefresh = false}) async {}

  void seed(CareerState state) => emit(state);
}

class _StubStoreCubit extends StoreCubit {
  _StubStoreCubit() : super(storeRepository: _MockStoreRepository());

  @override
  Future<void> fetchStore({bool forceRefresh = false}) async {}

  void seed(StoreState state) => emit(state);
}

class _StubBattlepassCubit extends BattlepassCubit {
  _StubBattlepassCubit() : super(repository: _MockBattlepassRepository());

  @override
  Future<void> loadBattlepass({bool forceRefresh = false}) async {}
}

class _StubSocialCubit extends SocialCubit {
  _StubSocialCubit() : super(socialRepository: _MockSocialRepository());

  @override
  Future<void> loadFriends({bool forceRefresh = false}) async {}
}

class _StubLiveMatchCubit extends LiveMatchCubit {
  _StubLiveMatchCubit() : super(repository: _MockLiveMatchRepository());

  @override
  Future<void> scanLiveMatch({bool silent = false}) async {}
}

void main() {
  const profile = UserProfile(
    puuid: 'puuid-12345678',
    gameName: 'TenZ',
    tagLine: 'SEN',
    accountLevel: 150,
    region: 'na',
    shard: 'na',
  );

  final career = CareerOverview(
    currentTierName: 'Diamond 1',
    currentRankRating: 55,
    totalMatches: 18,
    totalWins: 10,
    totalLosses: 8,
    winRate: 55.0,
  );

  late _StubProfileCubit profileCubit;
  late _StubCareerCubit careerCubit;
  late _StubStoreCubit storeCubit;
  late _StubBattlepassCubit battlepassCubit;
  late _StubSocialCubit socialCubit;
  late _StubLiveMatchCubit liveMatchCubit;

  setUp(() {
    profileCubit = _StubProfileCubit();
    careerCubit = _StubCareerCubit();
    storeCubit = _StubStoreCubit();
    battlepassCubit = _StubBattlepassCubit();
    socialCubit = _StubSocialCubit();
    liveMatchCubit = _StubLiveMatchCubit();
  });

  tearDown(() async {
    await profileCubit.close();
    await careerCubit.close();
    await storeCubit.close();
    await battlepassCubit.close();
    await socialCubit.close();
    await liveMatchCubit.close();
  });

  testWidgets('keeps cached profile and career visible while refreshing', (
    tester,
  ) async {
    profileCubit.seed(const ProfileLoading(cachedProfile: profile));
    careerCubit.seed(CareerLoading(cachedOverview: career));
    storeCubit.seed(
      StoreLoaded(
        store: DailyStore(
          featuredOffers: const [],
          remainingDurationSeconds: 36000,
          lastFetched: DateTime(2026, 10, 21),
        ),
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<CareerCubit>.value(value: careerCubit),
          BlocProvider<StoreCubit>.value(value: storeCubit),
          BlocProvider<BattlepassCubit>.value(value: battlepassCubit),
          BlocProvider<SocialCubit>.value(value: socialCubit),
          BlocProvider<LiveMatchCubit>.value(value: liveMatchCubit),
        ],
        child: MaterialApp(theme: DarkTheme.darkTheme, home: const HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('TenZ'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -700),
    );
    await tester.pump();

    expect(find.text('55.0%'), findsOneWidget);
  });
}
