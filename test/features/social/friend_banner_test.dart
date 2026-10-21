import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/friend_card.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/friend_profile_header.dart';
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

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: DarkTheme.darkTheme,
    home: Scaffold(
      body: SizedBox(width: 400, child: child),
    ),
  );
}

final _friend = FriendEntity(
  puuid: 'friend-puuid',
  gameName: 'Boaster',
  tagLine: 'FNC',
  accountLevel: 240,
  rankName: 'Radiant',
  cardWideArt: 'https://example.com/friend-wide.png',
  cardLargeArt: 'https://example.com/friend-large.png',
  cardSmallArt: 'https://example.com/friend-small.png',
  lastUpdated: DateTime(2026, 10, 20),
);

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('friend card shows the friend player card banner',
      (tester) async {
    await tester.pumpWidget(_wrap(FriendCard(friend: _friend)));
    await tester.pump();

    final banner = tester.widget<PlayerBannerArt>(
      find.byType(PlayerBannerArt),
    );
    expect(banner.wideArt, 'https://example.com/friend-wide.png');
    expect(find.text('BOASTER'), findsOneWidget);
  });

  testWidgets('friend profile header shows the wide banner and close action',
      (tester) async {
    var closed = false;
    await tester.pumpWidget(
      _wrap(
        FriendProfileHeader(
          friend: _friend,
          onClose: () => closed = true,
        ),
      ),
    );
    await tester.pump();

    final banner = tester.widget<PlayerBannerArt>(
      find.byType(PlayerBannerArt),
    );
    expect(banner.wideArt, 'https://example.com/friend-wide.png');
    expect(find.text('PLAYER PROFILE'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closed, isTrue);
  });
}
