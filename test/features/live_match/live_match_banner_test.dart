import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/live_match_hud_header.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/live_player_card.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';
import 'package:valorant_store_tracker/ui/widgets/player_banner.dart';

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
  when(
    () => response.compressionState,
  ).thenReturn(HttpClientResponseCompressionState.notCompressed);
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
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: DarkTheme.darkTheme,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

const _self = LivePlayerInfo(
  puuid: 'self-puuid',
  gameName: 'TenZ',
  tagLine: 'SEN',
  teamId: 'Blue',
  agentName: 'Jett',
  currentRankTierName: 'Radiant',
  peakRankTierName: 'Radiant',
  isSelf: true,
  cardWideArt: 'https://example.com/self-wide.png',
);

const _teammate = LivePlayerInfo(
  puuid: 'mate-puuid',
  gameName: 'Boaster',
  tagLine: 'FNC',
  teamId: 'Blue',
  agentName: 'Astra',
  currentRankTierName: 'Immortal 2',
  peakRankTierName: 'Radiant',
  cardWideArt: 'https://example.com/mate-wide.png',
);

const _enemy = LivePlayerInfo(
  puuid: 'enemy-puuid',
  gameName: 'Derke',
  tagLine: 'FNC',
  teamId: 'Red',
  agentName: 'Raze',
  currentRankTierName: 'Radiant',
  peakRankTierName: 'Radiant',
  cardWideArt: 'https://example.com/enemy-wide.png',
);

const _allCardArt = LivePlayerInfo(
  puuid: 'all-art-puuid',
  gameName: 'Chronicle',
  tagLine: 'FNC',
  teamId: 'Blue',
  agentName: 'Fade',
  currentRankTierName: 'Radiant',
  peakRankTierName: 'Radiant',
  cardWideArt: 'https://example.com/wide.png',
  cardLargeArt: 'https://example.com/large.png',
  cardSmallArt: 'https://example.com/small.png',
);

const _tenOutcomePlayer = LivePlayerInfo(
  puuid: 'ten-outcome-puuid',
  gameName: 'TenOutcome',
  tagLine: 'FNC',
  teamId: 'Blue',
  agentName: 'Jett',
  currentRankTierName: 'Diamond 1',
  peakRankTierName: 'Diamond 1',
  recentMatchOutcomes: [
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
  ],
);

const _match = LiveMatchData(
  phase: LiveMatchPhase.coreGame,
  mapName: 'Ascent',
  mapSplash: 'https://example.com/ascent.png',
  modeName: 'Competitive',
  blueTeam: [_self, _teammate],
  redTeam: [_enemy],
  blueScore: 7,
  redScore: 5,
);

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('shows each teammate and enemy player card banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            LivePlayerCard(player: _self),
            LivePlayerCard(player: _enemy, isEnemy: true),
          ],
        ),
      ),
    );
    await tester.pump();

    final banners = tester
        .widgetList<PlayerBannerArt>(find.byType(PlayerBannerArt))
        .toList();
    expect(banners, hasLength(2));
    expect(banners[0].wideArt, 'https://example.com/self-wide.png');
    expect(banners[1].wideArt, 'https://example.com/enemy-wide.png');
  });

  testWidgets('uses only the wide card art', (tester) async {
    await tester.pumpWidget(_wrap(const LivePlayerCard(player: _allCardArt)));
    await tester.pump();

    final banner = tester.widget<PlayerBannerArt>(
      find.byType(PlayerBannerArt).first,
    );
    expect(banner.wideArt, 'https://example.com/wide.png');
    expect(banner.largeArt, isNull);
    expect(banner.smallArt, isNull);
  });

  testWidgets('adds a subtle shadow to the card surface', (tester) async {
    await tester.pumpWidget(_wrap(const LivePlayerCard(player: _allCardArt)));
    await tester.pump();

    final surface = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(LivePlayerCard),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.boxShadow!.single.blurRadius, lessThanOrEqualTo(12));
  });

  testWidgets('shows all ten recent match outcomes', (tester) async {
    await tester.pumpWidget(
      _wrap(const LivePlayerCard(player: _tenOutcomePlayer)),
    );
    await tester.pump();

    expect(find.text('W'), findsNWidgets(5));
    expect(find.text('L'), findsNWidgets(5));
  });

  testWidgets('hud hero prefers the self player banner over map splash', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const LiveMatchHudHeader(matchData: _match)));
    await tester.pump();

    final banner = tester.widget<PlayerBannerArt>(find.byType(PlayerBannerArt));
    expect(banner.wideArt, 'https://example.com/self-wide.png');
    expect(find.text('Ascent'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('hud hero falls back to map splash without a self banner', (
    tester,
  ) async {
    const selfWithoutCard = LivePlayerInfo(
      puuid: 'self-puuid',
      gameName: 'TenZ',
      tagLine: 'SEN',
      teamId: 'Blue',
      isSelf: true,
    );
    const matchWithoutCard = LiveMatchData(
      phase: LiveMatchPhase.coreGame,
      mapName: 'Ascent',
      mapSplash: 'https://example.com/ascent.png',
      blueTeam: [selfWithoutCard],
    );

    await tester.pumpWidget(
      _wrap(const LiveMatchHudHeader(matchData: matchWithoutCard)),
    );
    await tester.pump();

    final banner = tester.widget<PlayerBannerArt>(find.byType(PlayerBannerArt));
    expect(banner.wideArt, 'https://example.com/ascent.png');
  });
}
