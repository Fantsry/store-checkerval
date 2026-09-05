import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';

class MockStoreRepository extends Mock implements StoreRepository {}

void main() {
  late MockStoreRepository mockStoreRepository;
  late StoreCubit storeCubit;

  final tStore = DailyStore(
    featuredOffers: const [
      SkinItem(
        uuid: 'test-skin-1',
        displayName: 'Prime Vandal',
        weaponName: 'Vandal',
        cost: 1775,
      ),
    ],
    remainingDurationSeconds: 36000,
    lastFetched: DateTime(2026, 9, 5),
  );

  const tWallet = UserWallet(valorantPoints: 2175, radianitePoints: 80);

  setUp(() {
    mockStoreRepository = MockStoreRepository();
    storeCubit = StoreCubit(storeRepository: mockStoreRepository);
  });

  tearDown(() {
    storeCubit.close();
  });

  group('StoreCubit', () {
    test('initial state is StoreInitial', () {
      expect(storeCubit.state, equals(const StoreInitial()));
    });

    blocTest<StoreCubit, StoreState>(
      'emits [StoreLoading, StoreLoaded] when fetchStore succeeds',
      build: () {
        when(() => mockStoreRepository.getDailyStore(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => Result.success(tStore));
        when(() => mockStoreRepository.getUserWallet())
            .thenAnswer((_) async => const Result.success(tWallet));
        return storeCubit;
      },
      act: (cubit) => cubit.fetchStore(),
      expect: () => [
        const StoreLoading(),
        StoreLoaded(
          store: tStore,
          wallet: tWallet,
        ),
      ],
    );

    blocTest<StoreCubit, StoreState>(
      'emits [StoreLoading, StoreError] when fetchStore fails',
      build: () {
        when(() => mockStoreRepository.getDailyStore(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async =>
            const Result.failure(ServerFailure(message: 'Store unavailable')));
        when(() => mockStoreRepository.getUserWallet())
            .thenAnswer((_) async => const Result.success(tWallet));
        return storeCubit;
      },
      act: (cubit) => cubit.fetchStore(),
      expect: () => [
        const StoreLoading(),
        const StoreError('Store unavailable'),
      ],
    );
  });
}
