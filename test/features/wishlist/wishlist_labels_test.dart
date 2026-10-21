import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/l10n/l10n.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';
import 'package:valorant_store_tracker/ui/widgets/skin_preview_dialog.dart';

class MockWishlistRepository extends Mock implements WishlistRepository {}

const _skin = SkinItem(
  uuid: 'skin-uuid',
  displayName: 'Prime Vandal',
  weaponName: 'Vandal',
  cost: 1775,
  tierName: 'Premium',
);

Widget _wrap({
  required WishlistCubit cubit,
  required Locale locale,
  required SkinItem skin,
}) {
  return BlocProvider<WishlistCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: DarkTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SkinPreviewSheet(skin: skin)),
    ),
  );
}

void main() {
  late MockWishlistRepository repository;
  late WishlistCubit cubit;

  setUp(() {
    repository = MockWishlistRepository();
    cubit = WishlistCubit(wishlistRepository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('shows the Indonesian add-to-wishlist label', (tester) async {
    when(() => repository.getWishlist())
        .thenAnswer((_) async => const Result.success([]));
    when(() => repository.searchCatalog())
        .thenAnswer((_) async => const Result.success([]));
    await cubit.loadWishlist();

    await tester.pumpWidget(
      _wrap(cubit: cubit, locale: const Locale('id'), skin: _skin),
    );
    await tester.pumpAndSettle();

    expect(find.text('TAMBAH KE WISHLIST'), findsOneWidget);
    expect(find.text('ADD TO WISHLIST'), findsNothing);
  });

  testWidgets('shows the English wishlisted label', (tester) async {
    when(() => repository.getWishlist()).thenAnswer(
      (_) async => Result.success([
        WishlistItem(
          uuid: _skin.uuid,
          displayName: _skin.displayName,
          cost: _skin.cost,
          addedAt: DateTime(2026, 10, 20),
        ),
      ]),
    );
    when(() => repository.searchCatalog())
        .thenAnswer((_) async => const Result.success([]));
    await cubit.loadWishlist();

    await tester.pumpWidget(
      _wrap(cubit: cubit, locale: const Locale('en'), skin: _skin),
    );
    await tester.pumpAndSettle();

    expect(find.text('WISHLISTED'), findsOneWidget);
    expect(find.text('SUDAH DI WISHLIST'), findsNothing);
  });
}
