import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';
import 'package:valorant_store_tracker/ui/widgets/player_banner.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: DarkTheme.darkTheme,
    home: Scaffold(body: SizedBox(width: 400, child: child)),
  );
}

void main() {
  group('resolveBannerArtUrl', () {
    test('prefers wide art, then large art, then small art', () {
      expect(
        resolveBannerArtUrl(
          wideArt: 'wide.png',
          largeArt: 'large.png',
          smallArt: 'small.png',
        ),
        'wide.png',
      );
      expect(
        resolveBannerArtUrl(
          wideArt: '  ',
          largeArt: 'large.png',
          smallArt: 'small.png',
        ),
        'large.png',
      );
      expect(
        resolveBannerArtUrl(largeArt: null, smallArt: 'small.png'),
        'small.png',
      );
      expect(resolveBannerArtUrl(), isNull);
    });
  });

  group('PlayerBannerArt', () {
    testWidgets('fades banner art in quickly and decodes at display width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const PlayerBannerArt(wideArt: 'https://example.com/wide.png')),
      );
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final expectedCacheWidth = (400 * tester.view.devicePixelRatio).round();

      expect(image.fadeInDuration, const Duration(milliseconds: 180));
      expect(image.memCacheWidth, expectedCacheWidth);
    });
  });

  group('PlayerBannerCard', () {
    testWidgets('renders identity, title, badge, and metadata', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PlayerBannerCard(
            displayName: 'TenZ#SEN',
            title: 'VCT Champion',
            badge: 'PROFILE',
            meta: 'NA / LVL 150',
          ),
        ),
      );

      expect(find.text('TenZ#SEN'), findsOneWidget);
      expect(find.text('VCT Champion'), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('NA / LVL 150'), findsOneWidget);
    });

    testWidgets('renders fallback art marker when no card art exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const PlayerBannerCard(displayName: 'TenZ#SEN')),
      );

      expect(find.byKey(const Key('player-banner-fallback')), findsOneWidget);
    });

    testWidgets('keeps compact height when requested', (tester) async {
      await tester.pumpWidget(
        _wrap(const PlayerBannerCard(displayName: 'TenZ#SEN', height: 120)),
      );

      final size = tester.getSize(find.byType(PlayerBannerCard));
      expect(size.height, 120);
    });
  });
}
