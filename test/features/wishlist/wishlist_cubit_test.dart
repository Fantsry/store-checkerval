import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}

class FakeWishlistItem extends Fake implements WishlistItem {}

void main() {
  late MockWishlistRepository mockWishlistRepository;
  late WishlistCubit wishlistCubit;

  final tWishlistItem = WishlistItem(
    uuid: 'w-1',
    displayName: 'Reaver Vandal',
    weaponName: 'Vandal',
    cost: 1775,
    addedAt: DateTime(2026, 9, 5),
  );

  const tCatalogSkin = SkinItem(
    uuid: 'w-1',
    displayName: 'Reaver Vandal',
    weaponName: 'Vandal',
    cost: 1775,
  );

  setUpAll(() {
    registerFallbackValue(FakeWishlistItem());
  });

  setUp(() {
    mockWishlistRepository = MockWishlistRepository();
    wishlistCubit = WishlistCubit(wishlistRepository: mockWishlistRepository);
  });

  tearDown(() {
    wishlistCubit.close();
  });

  group('WishlistCubit', () {
    test('initial state is WishlistInitial', () {
      expect(wishlistCubit.state, equals(const WishlistInitial()));
    });

    blocTest<WishlistCubit, WishlistState>(
      'emits [WishlistLoading, WishlistLoaded] when loadWishlist succeeds',
      build: () {
        when(() => mockWishlistRepository.getWishlist())
            .thenAnswer((_) async => Result.success([tWishlistItem]));
        when(() => mockWishlistRepository.searchCatalog(
              query: any(named: 'query'),
              weaponType: any(named: 'weaponType'),
              tier: any(named: 'tier'),
            )).thenAnswer((_) async => const Result.success([tCatalogSkin]));
        return wishlistCubit;
      },
      act: (cubit) => cubit.loadWishlist(),
      expect: () => [
        const WishlistLoading(),
        WishlistLoaded(
          items: [tWishlistItem],
          catalog: const [tCatalogSkin],
        ),
      ],
    );

    blocTest<WishlistCubit, WishlistState>(
      'emits [WishlistLoading, WishlistError] when loadWishlist fails',
      build: () {
        when(() => mockWishlistRepository.getWishlist()).thenAnswer((_) async =>
            const Result.failure(CacheFailure(message: 'Disk error')));
        when(() => mockWishlistRepository.searchCatalog(
              query: any(named: 'query'),
              weaponType: any(named: 'weaponType'),
              tier: any(named: 'tier'),
            )).thenAnswer((_) async => const Result.success([]));
        return wishlistCubit;
      },
      act: (cubit) => cubit.loadWishlist(),
      expect: () => [
        const WishlistLoading(),
        const WishlistError('Disk error'),
      ],
    );
  });
}
