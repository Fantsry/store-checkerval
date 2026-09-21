import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/pages/catalog_page.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/pages/wishlist_page.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}
class MockStoreRepository extends Mock implements StoreRepository {}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockImageHttpClient();
  }
}

HttpClient _createMockImageHttpClient() {
  final client = MockHttpClient();
  final request = MockHttpClientRequest();
  final response = MockHttpClientResponse();
  final headers = MockHttpHeaders();

  when(() => client.getUrl(any())).thenAnswer((_) async => request);
  when(() => client.openUrl(any(), any())).thenAnswer((_) async => request);
  when(() => request.headers).thenReturn(headers);
  when(() => request.close()).thenAnswer((_) async => response);
  when(() => response.contentLength).thenReturn(_kTransparentImage.length);
  when(() => response.statusCode).thenReturn(HttpStatus.ok);
  when(() => response.compressionState)
      .thenReturn(HttpClientResponseCompressionState.notCompressed);
  when(() => response.listen(any())).thenAnswer((invocation) {
    final void Function(List<int>) onData = invocation.positionalArguments[0];
    final void Function()? onDone = invocation.namedArguments[#onDone];
    final Function? onError = invocation.namedArguments[#onError];
    final bool? cancelOnError = invocation.namedArguments[#cancelOnError];

    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  });

  return client;
}

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

void main() {
  late MockWishlistRepository mockWishlistRepo;
  late MockStoreRepository mockStoreRepo;
  late WishlistCubit wishlistCubit;
  late StoreCubit storeCubit;

  final tSkin1 = WishlistItem(
    uuid: 'skin-1',
    displayName: 'Prime Vandal',
    displayIcon: 'https://media.valorant-api.com/weaponskins/skin-1/displayicon.png',
    weaponName: 'Vandal',
    cost: 1775,
    tierName: 'Premium',
    addedAt: DateTime(2026, 9, 10),
  );

  final tSkin2 = WishlistItem(
    uuid: 'skin-2',
    displayName: 'Kuronami No Yaiba',
    displayIcon: null, // Test icon fallback
    weaponName: 'Melee',
    cost: 5350,
    tierName: 'Exclusive',
    addedAt: DateTime(2026, 9, 11),
  );

  final tCatalogSkin = SkinItem(
    uuid: 'skin-1',
    displayName: 'Prime Vandal',
    displayIcon: 'https://media.valorant-api.com/weaponskins/skin-1/displayicon.png',
    weaponName: 'Vandal',
    cost: 1775,
    tierName: 'Premium',
  );

  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  setUp(() {
    mockWishlistRepo = MockWishlistRepository();
    mockStoreRepo = MockStoreRepository();

    wishlistCubit = WishlistCubit(wishlistRepository: mockWishlistRepo);
    storeCubit = StoreCubit(storeRepository: mockStoreRepo);
  });

  tearDown(() {
    wishlistCubit.close();
    storeCubit.close();
  });

  Widget buildTestWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        BlocProvider<StoreCubit>.value(value: storeCubit),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('WishlistPage rendering tests', () {
    testWidgets('renders all wishlist items with name, price, and tier', (tester) async {
      when(() => mockWishlistRepo.getWishlist())
          .thenAnswer((_) async => Result.success([tSkin1, tSkin2]));
      when(() => mockWishlistRepo.searchCatalog())
          .thenAnswer((_) async => Result.success([tCatalogSkin]));

      await wishlistCubit.loadWishlist();

      await tester.pumpWidget(buildTestWidget(const WishlistPage()));
      await tester.pumpAndSettle();

      expect(find.text('WISHLIST'), findsOneWidget);
      expect(find.text('2 skins tracked'), findsOneWidget);
      expect(find.text('Prime Vandal'), findsOneWidget);
      expect(find.text('1775 VP'), findsOneWidget);
      expect(find.text('Kuronami No Yaiba'), findsOneWidget);
      expect(find.text('5350 VP'), findsOneWidget);
    });

    testWidgets('renders empty state when wishlist has 0 skins', (tester) async {
      when(() => mockWishlistRepo.getWishlist())
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockWishlistRepo.searchCatalog())
          .thenAnswer((_) async => const Result.success([]));

      await wishlistCubit.loadWishlist();

      await tester.pumpWidget(buildTestWidget(const WishlistPage()));
      await tester.pumpAndSettle();

      expect(find.text('No Skins in Wishlist'), findsOneWidget);
      expect(find.text('BROWSE CATALOG'), findsOneWidget);
    });

    testWidgets('renders error state with RETRY button and retries when tapped', (tester) async {
      when(() => mockWishlistRepo.getWishlist())
          .thenAnswer((_) async => const Result.failure(ServerFailure(message: 'Network offline')));
      when(() => mockWishlistRepo.searchCatalog())
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockWishlistRepo.searchCatalog(forceRefresh: true))
          .thenAnswer((_) async => const Result.success([]));

      await wishlistCubit.loadWishlist();

      await tester.pumpWidget(buildTestWidget(const WishlistPage()));
      await tester.pumpAndSettle();

      expect(find.text('Network offline'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);

      // Now mock success for retry
      when(() => mockWishlistRepo.getWishlist())
          .thenAnswer((_) async => Result.success([tSkin1]));

      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();

      expect(find.text('Prime Vandal'), findsOneWidget);
    });
  });

  group('CatalogPage rendering tests', () {
    testWidgets('renders catalog skins and search/filter controls', (tester) async {
      when(() => mockWishlistRepo.getWishlist())
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockWishlistRepo.searchCatalog())
          .thenAnswer((_) async => Result.success([tCatalogSkin]));

      await wishlistCubit.loadWishlist();

      await tester.pumpWidget(buildTestWidget(const CatalogPage()));
      await tester.pumpAndSettle();

      expect(find.text('SKIN CATALOG'), findsOneWidget);
      expect(find.text('Prime Vandal'), findsOneWidget);
      expect(find.text('1775 VP'), findsOneWidget);
      expect(find.text('Vandal'), findsWidgets);
    });

    testWidgets('renders No skins found with RESET FILTERS button when catalog is empty', (tester) async {
      when(() => mockWishlistRepo.getWishlist())
          .thenAnswer((_) async => const Result.success([]));
      when(() => mockWishlistRepo.searchCatalog())
          .thenAnswer((_) async => const Result.success([]));

      await wishlistCubit.loadWishlist();

      await tester.pumpWidget(buildTestWidget(const CatalogPage()));
      await tester.pumpAndSettle();

      expect(find.text('No skins found'), findsOneWidget);
      expect(find.text('RESET FILTERS'), findsOneWidget);
    });
  });
}
