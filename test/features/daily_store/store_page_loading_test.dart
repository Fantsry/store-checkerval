import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/pages/store_page.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';

class _MockStoreRepository extends Mock implements StoreRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockWishlistRepository extends Mock implements WishlistRepository {}

class _StubStoreCubit extends StoreCubit {
  _StubStoreCubit() : super(storeRepository: _MockStoreRepository());

  @override
  Future<void> fetchStore({bool forceRefresh = false}) async {}

  void seed(StoreState state) => emit(state);
}

class _StubProfileCubit extends ProfileCubit {
  _StubProfileCubit() : super(profileRepository: _MockProfileRepository());

  @override
  Future<void> loadProfile({bool forceRefresh = false}) async {}

  void seed(ProfileState state) => emit(state);
}

class _StubWishlistCubit extends WishlistCubit {
  _StubWishlistCubit() : super(wishlistRepository: _MockWishlistRepository());

  void seed(WishlistState state) => emit(state);
}

void main() {
  const profile = UserProfile(
    puuid: 'puuid-12345678',
    gameName: 'TenZ',
    tagLine: 'SEN',
    accountLevel: 150,
    region: 'na',
    shard: 'na',
    valorantPoints: 2175,
    radianitePoints: 80,
    walletAvailable: true,
  );

  final store = DailyStore(
    featuredOffers: const [
      SkinItem(
        uuid: 'test-skin-1',
        displayName: 'Prime Vandal',
        weaponName: 'Vandal',
        cost: 1775,
      ),
    ],
    remainingDurationSeconds: 36000,
    lastFetched: DateTime(2026, 10, 21),
  );

  late _StubStoreCubit storeCubit;
  late _StubProfileCubit profileCubit;
  late _StubWishlistCubit wishlistCubit;

  setUp(() {
    storeCubit = _StubStoreCubit();
    profileCubit = _StubProfileCubit();
    wishlistCubit = _StubWishlistCubit();
  });

  tearDown(() async {
    await storeCubit.close();
    await profileCubit.close();
    await wishlistCubit.close();
  });

  testWidgets('keeps store content visible with a thin refresh indicator', (
    tester,
  ) async {
    storeCubit.seed(StoreLoaded(store: store, isRefreshing: true));
    profileCubit.seed(const ProfileLoaded(profile));
    wishlistCubit.seed(const WishlistLoaded(items: []));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<StoreCubit>.value(value: storeCubit),
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: MaterialApp(theme: DarkTheme.darkTheme, home: const StorePage()),
      ),
    );
    await tester.pump();

    expect(find.text('Prime Vandal'), findsOneWidget);
    expect(find.byKey(const Key('store-refresh-progress')), findsOneWidget);
  });
}
