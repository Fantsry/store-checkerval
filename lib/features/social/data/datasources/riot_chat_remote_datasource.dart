import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// Friend item parsed from Riot's remote XMPP roster service.
class RiotFriendRosterItem {
  final String puuid;
  final String name; // GameName or GameName#Tag
  final String? tag;
  final String subscription;

  const RiotFriendRosterItem({
    required this.puuid,
    required this.name,
    this.tag,
    this.subscription = 'both',
  });

  @override
  String toString() => 'RiotFriendRosterItem(puuid: $puuid, name: $name, tag: $tag)';
}

/// Remote data source that connects directly to Riot Games' remote chat & roster
/// infrastructure (XMPP over TLS, port 5223) using OAuth Bearer + PAS tokens.
class RiotChatRemoteDataSource {
  final Dio _dio;

  RiotChatRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  /// Step 1: Request PAS (Player Affinity Service) JWT token from Riot
  Future<Map<String, String>?> fetchPasToken({
    required String accessToken,
  }) async {
    try {
      final response = await _dio.get<String>(
        'https://riot-geo.pas.si.riotgames.com/pas/v1/service/chat',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final pasJwt = response.data?.trim();
      if (pasJwt == null || pasJwt.isEmpty) return null;

      // Decode JWT payload (middle section between '.')
      final parts = pasJwt.split('.');
      if (parts.length < 2) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payloadStr = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;

      final affinity = payload['affinity']?.toString() ?? 'ap1';
      return {
        'pasToken': pasJwt,
        'affinity': affinity,
      };
    } catch (_) {
      return null;
    }
  }

  /// Step 2: Establish TLS socket with Riot XMPP server, authenticate with
  /// custom SASL mechanism 'X-Riot-RSO-PAS', and fetch the live friends roster.
  Future<List<RiotFriendRosterItem>> fetchRemoteRoster({
    required String accessToken,
  }) async {
    final pasInfo = await fetchPasToken(accessToken: accessToken);
    if (pasInfo == null) return const [];

    final pasToken = pasInfo['pasToken']!;
    final affinity = pasInfo['affinity']!;
    final host = '$affinity.chat.si.riotgames.com';

    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        host,
        5223,
        timeout: const Duration(seconds: 8),
        onBadCertificate: (_) => true,
      );

      final completer = Completer<List<RiotFriendRosterItem>>();
      final buffer = StringBuffer();
      int step = 0; // 0: init, 1: auth sent, 2: stream reset, 3: bind, 4: roster query
      final List<RiotFriendRosterItem> friends = [];

      final timer = Timer(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          completer.complete(friends);
        }
      });

      socket.listen(
        (data) {
          final str = utf8.decode(data, allowMalformed: true);
          buffer.write(str);

          if (step == 0 && (str.contains('<stream:features>') || str.contains('stream:features'))) {
            step = 1;
            socket!.write(
              '<auth mechanism="X-Riot-RSO-PAS" xmlns="urn:ietf:params:xml:ns:xmpp-sasl">'
              '<rso_token>$accessToken</rso_token>'
              '<pas_token>$pasToken</pas_token>'
              '</auth>',
            );
          } else if (step == 1 && str.contains('<success')) {
            step = 2;
            socket!.write(
              '<?xml version="1.0"?>'
              '<stream:stream to="$host" version="1.0" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams">',
            );
          } else if (step == 2 && (str.contains('<stream:features>') || str.contains('stream:features'))) {
            step = 3;
            socket!.write(
              '<iq type="set" id="bind_1">'
              '<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/>'
              '</iq>',
            );
          } else if (step == 3 && str.contains('bind_1')) {
            step = 4;
            socket!.write(
              '<iq type="get" id="roster_1">'
              '<query xmlns="jabber:iq:roster"/>'
              '</iq>',
            );
          } else if (step == 4 &&
              (str.contains('roster_1') ||
                  str.contains('jabber:iq:roster') ||
                  str.contains('<item '))) {
            final full = buffer.toString();
            final itemRegex = RegExp(
              r'<item\s+[^>]*jid=["\x27]([^@"\x27]+)@[^"\x27]+["\x27](?:[^>]*name=["\x27]([^"\x27]*)["\x27])?',
              caseSensitive: false,
            );

            for (final match in itemRegex.allMatches(full)) {
              final rawPuuid = match.group(1)?.trim() ?? '';
              final rawName = match.group(2)?.trim() ?? '';

              if (rawPuuid.isNotEmpty && !friends.any((f) => f.puuid == rawPuuid)) {
                String name = rawName;
                String? tag;
                if (rawName.contains('#')) {
                  final parts = rawName.split('#');
                  name = parts[0].trim();
                  tag = parts.length > 1 ? parts[1].trim() : null;
                }

                friends.add(RiotFriendRosterItem(
                  puuid: rawPuuid,
                  name: name,
                  tag: tag,
                ));
              }
            }

            if (!completer.isCompleted) {
              timer.cancel();
              completer.complete(friends);
            }
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            timer.cancel();
            completer.complete(friends);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            timer.cancel();
            completer.complete(friends);
          }
        },
      );

      // Send initial XMPP stream initiation
      socket.write(
        '<?xml version="1.0"?>'
        '<stream:stream to="$host" version="1.0" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams">',
      );

      final result = await completer.future;
      try {
        socket.destroy();
      } catch (_) {}
      return result;
    } catch (_) {
      try {
        socket?.destroy();
      } catch (_) {}
      return const [];
    }
  }
}
