import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late ProfileCubit profileCubit;

  const tInGameProfile = UserProfile(
    puuid: 'puuid-12345678',
    gameName: 'TenZ',
    tagLine: 'SEN',
    accountLevel: 150,
    accountXp: 4500,
    cardUuid: 'custom-card-uuid-champions',
    cardName: 'Champions 2024 Card',
    cardSmallArt: 'https://media.valorant-api.com/playercards/custom-card-uuid-champions/smallart.png',
    cardWideArt: 'https://media.valorant-api.com/playercards/custom-card-uuid-champions/wideart.png',
    cardLargeArt: 'https://media.valorant-api.com/playercards/custom-card-uuid-champions/largeart.png',
    titleText: 'VCT Champion',
    region: 'na',
    shard: 'na',
    valorantPoints: 2500,
    radianitePoints: 120,
    kingdomCredits: 8000,
  );

  const tDefaultBannerProfile = UserProfile(
    puuid: 'puuid-12345678',
    gameName: 'TenZ',
    tagLine: 'SEN',
    accountLevel: 150,
    cardUuid: '9fb348bc-41a0-91ad-8a3e-818035c4e561',
    cardName: 'VALORANT Card',
    cardSmallArt: 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/smallart.png',
    cardWideArt: 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/wideart.png',
    region: 'na',
    shard: 'na',
  );

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    profileCubit = ProfileCubit(profileRepository: mockProfileRepository);
  });

  tearDown(() {
    profileCubit.close();
  });

  group('ProfileCubit', () {
    test('initial state is ProfileInitial', () {
      expect(profileCubit.state, equals(const ProfileInitial()));
    });

    blocTest<ProfileCubit, ProfileState>(
      'emits [ProfileLoaded] from cache then updates when fresh in-game profile arrives',
      build: () {
        when(() => mockProfileRepository.getCachedProfile())
            .thenAnswer((_) async => tInGameProfile);
        when(() => mockProfileRepository.getUserProfile(forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => const Result.success(tInGameProfile));
        return profileCubit;
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileLoaded(tInGameProfile),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'detects default Valorant banner in cache as placeholder and force refreshes in-game card',
      build: () {
        when(() => mockProfileRepository.getCachedProfile())
            .thenAnswer((_) async => tDefaultBannerProfile);
        when(() => mockProfileRepository.getUserProfile(forceRefresh: true))
            .thenAnswer((_) async => const Result.success(tInGameProfile));
        return profileCubit;
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileLoading(cachedProfile: null),
        const ProfileLoaded(tInGameProfile),
      ],
      verify: (_) {
        verify(() => mockProfileRepository.getUserProfile(forceRefresh: true)).called(1);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'forceRefresh = true bypasses cache and emits fresh in-game card profile',
      build: () {
        when(() => mockProfileRepository.getCachedProfile())
            .thenAnswer((_) async => tInGameProfile);
        when(() => mockProfileRepository.getUserProfile(forceRefresh: true))
            .thenAnswer((_) async => const Result.success(tInGameProfile));
        return profileCubit;
      },
      act: (cubit) => cubit.loadProfile(forceRefresh: true),
      expect: () => [
        const ProfileLoading(cachedProfile: tInGameProfile),
        const ProfileLoaded(tInGameProfile),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits ProfileError when repository fails and no cache exists',
      build: () {
        when(() => mockProfileRepository.getCachedProfile())
            .thenAnswer((_) async => null);
        when(() => mockProfileRepository.getUserProfile(forceRefresh: any(named: 'forceRefresh')))
            .thenAnswer((_) async => const Result.failure(ServerFailure(message: 'Network error')));
        return profileCubit;
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileLoading(cachedProfile: null),
        const ProfileError('Network error', cachedProfile: null),
      ],
    );

    test('updateWithWallet updates balances on ProfileLoaded', () {
      profileCubit.emit(const ProfileLoaded(tInGameProfile));
      profileCubit.updateWithWallet(vp: 5000, rp: 200, kc: 9000);

      expect(profileCubit.state, isA<ProfileLoaded>());
      final loaded = profileCubit.state as ProfileLoaded;
      expect(loaded.profile.valorantPoints, equals(5000));
      expect(loaded.profile.radianitePoints, equals(200));
      expect(loaded.profile.kingdomCredits, equals(9000));
      // In-game card remains intact
      expect(loaded.profile.cardUuid, equals('custom-card-uuid-champions'));
      expect(loaded.profile.cardName, equals('Champions 2024 Card'));
    });
  });
}
