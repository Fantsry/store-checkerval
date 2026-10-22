import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:valorant_store_tracker/features/settings/presentation/settings_page.dart';
import 'package:valorant_store_tracker/l10n/l10n.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';
import 'package:valorant_store_tracker/ui/widgets/player_banner.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';

class MockLocalStoreService extends Mock implements LocalStoreService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockLocalStoreService localStore;
  late MockSecureStorageService secureStorage;
  late MockProfileRepository profileRepository;
  late ProfileCubit profileCubit;
  late AppSettingsCubit settingsCubit;

  const profile = UserProfile(
    puuid: 'puuid-12345678',
    gameName: 'TenZ',
    tagLine: 'SEN',
    accountLevel: 150,
    titleText: 'VCT Champion',
    region: 'na',
    shard: 'na',
  );

  setUp(() async {
    await getIt.reset();
    localStore = MockLocalStoreService();
    secureStorage = MockSecureStorageService();
    profileRepository = MockProfileRepository();
    profileCubit = ProfileCubit(profileRepository: profileRepository);
    settingsCubit = AppSettingsCubit(localStore);

    getIt.registerSingleton<LocalStoreService>(localStore);
    getIt.registerSingleton<SecureStorageService>(secureStorage);

    when(() => localStore.getLocale()).thenAnswer((_) async => 'en');
    when(
      () => localStore.areNightMarketAlertsEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => localStore.areAccessoryAlertsEnabled(),
    ).thenAnswer((_) async => true);
    when(() => localStore.areChatAlertsEnabled()).thenAnswer((_) async => true);
    when(
      () => secureStorage.areNotificationsEnabled(),
    ).thenAnswer((_) async => true);
    await settingsCubit.load();

    when(
      () => profileRepository.getCachedProfile(),
    ).thenAnswer((_) async => null);
    when(
      () => profileRepository.getUserProfile(forceRefresh: true),
    ).thenAnswer((_) async => const Result.success(profile));
  });

  tearDown(() async {
    await profileCubit.close();
    await settingsCubit.close();
    await getIt.reset();
  });

  testWidgets('renders the wide player banner and refreshes profile once', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(
          theme: DarkTheme.darkTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlayerBannerCard), findsOneWidget);
    expect(find.text('TenZ#SEN'), findsOneWidget);
    expect(find.text('VCT Champion'), findsOneWidget);

    await tester.pump();

    verifyNever(() => profileRepository.getUserProfile(forceRefresh: false));
    verify(
      () => profileRepository.getUserProfile(forceRefresh: true),
    ).called(1);
  });

  testWidgets('shows a banner skeleton only when no cached profile exists', (
    tester,
  ) async {
    final pendingProfile = Completer<Result<UserProfile>>();
    when(
      () => profileRepository.getUserProfile(forceRefresh: true),
    ).thenAnswer((_) => pendingProfile.future);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(
          theme: DarkTheme.darkTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ShimmerBox), findsOneWidget);
    expect(find.byType(PlayerBannerCard), findsNothing);
  });
}
