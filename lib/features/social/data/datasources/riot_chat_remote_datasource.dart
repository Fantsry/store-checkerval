import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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

/// Rich presence payload extracted from Riot XMPP broadcast.
class RiotPresenceData {
  final String puuid;
  final String show; // 'chat', 'away', 'dnd', 'offline'
  final String status;
  final bool isOnline;
  final bool isAway;
  final bool isMobile;
  final String clientActivity; // 'In Riot Client', 'Away', 'Competitive · Bind · 2-0'
  final String? sessionLoopState; // 'INGAME', 'PREGAME', 'MENUS'
  final String? matchMap; // e.g. '/Game/Maps/Duality/Duality'
  final String? queueId; // e.g. 'competitive'
  final int? scoreAlly;
  final int? scoreEnemy;
  final int? partySize;
  final int? maxPartySize;
  final String? playerCardId;
  final int? competitiveTier;
  final int? accountLevel;

  const RiotPresenceData({
    required this.puuid,
    this.show = 'offline',
    this.status = '',
    this.isOnline = false,
    this.isAway = false,
    this.isMobile = false,
    this.clientActivity = 'Offline',
    this.sessionLoopState,
    this.matchMap,
    this.queueId,
    this.scoreAlly,
    this.scoreEnemy,
    this.partySize,
    this.maxPartySize,
    this.playerCardId,
    this.competitiveTier,
    this.accountLevel,
  });

  bool get isInGame => sessionLoopState == 'INGAME';
  bool get isInPreGame => sessionLoopState == 'PREGAME';
}

/// Simple chat message model parsed from XMPP message stanzas.
class RiotChatMessage {
  final String senderPuuid;
  final String body;
  final DateTime timestamp;

  const RiotChatMessage({
    required this.senderPuuid,
    required this.body,
    required this.timestamp,
  });
}

/// Consolidated snapshot returned by Riot XMPP sync.
class RiotSocialSyncData {
  final List<RiotFriendRosterItem> roster;
  final Map<String, RiotPresenceData> presences; // Key: PUUID
  final Map<String, RiotChatMessage> recentMessages; // Key: PUUID

  const RiotSocialSyncData({
    this.roster = const [],
    this.presences = const {},
    this.recentMessages = const {},
  });
}

/// Remote data source connecting to Riot Games' real-time chat & presence
/// architecture (XMPP over TLS, port 5223) using OAuth Bearer + PAS tokens.
class RiotChatRemoteDataSource {
  final Dio _dio;

  RiotChatRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  /// Step 1: Request PAS (Player Affinity Service) JWT token from Riot.
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

  static const Map<String, String> defaultChatAffinities = {
    'as2': 'as2.chat.si.riotgames.com',
    'asia': 'jp1.chat.si.riotgames.com',
    'ap': 'jp1.chat.si.riotgames.com',
    'ap1': 'jp1.chat.si.riotgames.com',
    'ap2': 'jp1.chat.si.riotgames.com',
    'ap3': 'jp1.chat.si.riotgames.com',
    'br1': 'br.chat.si.riotgames.com',
    'eu': 'ru1.chat.si.riotgames.com',
    'eu1': 'eu1.chat.si.riotgames.com',
    'eu2': 'eu2.chat.si.riotgames.com',
    'eu3': 'eu3.chat.si.riotgames.com',
    'eun1': 'eun1.chat.si.riotgames.com',
    'euw1': 'euw1.chat.si.riotgames.com',
    'jp1': 'jp1.chat.si.riotgames.com',
    'kr1': 'kr1.chat.si.riotgames.com',
    'la1': 'la1.chat.si.riotgames.com',
    'la2': 'la2.chat.si.riotgames.com',
    'na1': 'na2.chat.si.riotgames.com',
    'na2': 'na2.chat.si.riotgames.com',
    'oc1': 'oc1.chat.si.riotgames.com',
    'pbe1': 'pbe1.chat.si.riotgames.com',
    'ru1': 'ru1.chat.si.riotgames.com',
    'sea1': 'sa1.chat.si.riotgames.com',
    'sea2': 'sa2.chat.si.riotgames.com',
    'sea3': 'sa3.chat.si.riotgames.com',
    'sea4': 'sa4.chat.si.riotgames.com',
    'tr1': 'tr1.chat.si.riotgames.com',
    'us': 'la1.chat.si.riotgames.com',
    'us-br1': 'br.chat.si.riotgames.com',
    'us-la2': 'la2.chat.si.riotgames.com',
    'us2': 'us2.chat.si.riotgames.com',
  };

  static const Map<String, String> defaultChatAffinityDomains = {
    'as2': 'as2',
    'asia': 'jp1',
    'ap': 'jp1',
    'ap1': 'jp1',
    'ap2': 'jp1',
    'ap3': 'jp1',
    'br1': 'br1',
    'eu': 'ru1',
    'eu1': 'eu1',
    'eu2': 'eu2',
    'eu3': 'eu3',
    'eun1': 'eu2',
    'euw1': 'eu1',
    'jp1': 'jp1',
    'kr1': 'kr1',
    'la1': 'la1',
    'la2': 'la2',
    'na1': 'na1',
    'na2': 'na2',
    'oc1': 'oc1',
    'pbe1': 'pb1',
    'ru1': 'ru1',
    'sea1': 'sa1',
    'sea2': 'sa2',
    'sea3': 'sa3',
    'sea4': 'sa4',
    'tr1': 'tr1',
    'us': 'la1',
    'us-br1': 'br1',
    'us-la2': 'la2',
    'us2': 'us2',
  };

  /// Step 2: Fetch clientconfig to resolve official chat hosts and domains.
  Future<Map<String, String>> fetchChatRouting({
    required String accessToken,
    required String affinity,
    String? entitlementToken,
  }) async {
    final lowerAffinity = affinity.toLowerCase().trim();
    String host = defaultChatAffinities[lowerAffinity] ?? '$lowerAffinity.chat.si.riotgames.com';
    String rawDomain = defaultChatAffinityDomains[lowerAffinity] ?? lowerAffinity;
    String domain = rawDomain.contains('.') ? rawDomain : '$rawDomain.pvp.net';

    if (entitlementToken != null && entitlementToken.isNotEmpty) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          'https://clientconfig.rpg.riotgames.com/api/v1/config/player?app=Riot%20Client',
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'X-Riot-Entitlements-JWT': entitlementToken,
            },
            sendTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 6),
          ),
        );

        final data = res.data ?? {};
        if (data['chat.affinities'] is Map) {
          final affinities = Map<String, dynamic>.from(data['chat.affinities'] as Map);
          if (affinities.containsKey(lowerAffinity)) {
            host = affinities[lowerAffinity].toString();
          } else if (affinities.containsKey(affinity)) {
            host = affinities[affinity].toString();
          }
        }
        if (data['chat.affinity_domains'] is Map) {
          final domains = Map<String, dynamic>.from(data['chat.affinity_domains'] as Map);
          String? d;
          if (domains.containsKey(lowerAffinity)) {
            d = domains[lowerAffinity].toString();
          } else if (domains.containsKey(affinity)) {
            d = domains[affinity].toString();
          }
          if (d != null && d.isNotEmpty) {
            domain = d.contains('.') ? d : '$d.pvp.net';
          }
        }
      } catch (_) {}
    }

    return {'host': host, 'domain': domain};
  }

  /// Step 3: Connect to Riot XMPP over TLS, perform SASL auth, request roster,
  /// publish presence, and collect live friend presences and chats.
  Future<RiotSocialSyncData> fetchRemoteSocialData({
    required String accessToken,
    String? entitlementToken,
  }) async {
    final pasInfo = await fetchPasToken(accessToken: accessToken);
    if (pasInfo == null) return const RiotSocialSyncData();

    final pasToken = pasInfo['pasToken']!;
    final affinity = pasInfo['affinity']!;
    final routing = await fetchChatRouting(
      accessToken: accessToken,
      affinity: affinity,
      entitlementToken: entitlementToken,
    );

    final host = routing['host']!;
    final domain = routing['domain']!;
    final randomHex = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');

    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        host,
        5223,
        timeout: const Duration(seconds: 7),
      );

      final completer = Completer<RiotSocialSyncData>();
      final buffer = StringBuffer();
      int step = 0; // 0: stream init, 1: auth sent, 2: stream reset, 3: bind sent, 4: session sent, 5: collecting data

      final List<RiotFriendRosterItem> rosterList = [];
      final Map<String, RiotPresenceData> presencesMap = {};
      final Map<String, RiotChatMessage> messagesMap = {};

      Timer? collectionTimer;

      void finish() {
        if (!completer.isCompleted) {
          collectionTimer?.cancel();
          completer.complete(RiotSocialSyncData(
            roster: rosterList,
            presences: presencesMap,
            recentMessages: messagesMap,
          ));
        }
      }

      final timeoutTimer = Timer(const Duration(seconds: 8), finish);

      socket.listen(
        (data) {
          final str = utf8.decode(data, allowMalformed: true);
          buffer.write(str);

          // Step 0: Server sent features after initial connection -> Send SASL auth
          if (step == 0 && (str.contains('<stream:features') || str.contains('stream:features') || str.contains('X-Riot-RSO-PAS'))) {
            step = 1;
            socket!.write(
              '<auth mechanism="X-Riot-RSO-PAS" xmlns="urn:ietf:params:xml:ns:xmpp-sasl">'
              '<rso_token>$accessToken</rso_token>'
              '<pas_token>$pasToken</pas_token>'
              '</auth>',
            );
          }
          // Step 1: Server sent success -> Reset stream
          else if (step == 1 && str.contains('<success')) {
            step = 2;
            socket!.write(
              '<?xml version="1.0" encoding="UTF-8"?>'
              '<stream:stream to="$domain" xml:lang="en" version="1.0" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams">',
            );
          }
          // Step 2: Server sent features after stream restart -> Bind with PUUID mode enabled
          else if (step == 2 && (str.contains('<stream:features') || str.contains('stream:features') || str.contains('<bind'))) {
            step = 3;
            socket!.write(
              '<iq id="_xmpp_bind1" type="set">'
              '<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">'
              '<puuid-mode enabled="true"/>'
              '<resource>RC-$randomHex</resource>'
              '</bind>'
              '</iq>',
            );
          }
          // Step 3: Server sent bind response -> Setup session
          else if (step == 3 && str.contains('_xmpp_bind1')) {
            step = 4;
            socket!.write(
              '<iq id="_xmpp_session1" type="set">'
              '<session xmlns="urn:ietf:params:xml:ns:xmpp-session"/>'
              '</iq>',
            );
          }
          // Step 4: Server sent session response -> Set entitlements & Request roster & presence
          else if (step == 4 && str.contains('_xmpp_session1')) {
            step = 5;

            // Set entitlements token if available
            if (entitlementToken != null && entitlementToken.isNotEmpty) {
              socket!.write(
                '<iq id="xmpp_entitlements_0" type="set">'
                '<entitlements xmlns="urn:riotgames:entitlements">'
                '<token xmlns="">$entitlementToken</token>'
                '</entitlements>'
                '</iq>',
              );
            }

            // Send official Riot Games roster query
            socket!.write(
              '<iq type="get" id="roster_1">'
              '<query xmlns="jabber:iq:riotgames:roster" last_state="true"/>'
              '</iq>',
            );

            // Send archive list query for recent chats
            socket.write(
              '<iq type="get" id="recent_convos_3">'
              '<query xmlns="jabber:iq:riotgames:archive:list"/>'
              '</iq>',
            );

            // Send presence availability to trigger presence broadcasts
            socket.write(
              '<presence>'
              '<show>chat</show>'
              '<status></status>'
              '</presence>',
            );

            // Give the server 3.5 seconds to send roster and all presence broadcasts
            collectionTimer = Timer(const Duration(milliseconds: 3500), finish);
          }

          // Parse any stanzas that arrive
          if (step >= 4) {
            _parseIncomingChunk(
              chunk: str,
              rosterList: rosterList,
              presencesMap: presencesMap,
              messagesMap: messagesMap,
            );
          }
        },
        onError: (_) => finish(),
        onDone: () => finish(),
      );

      // Send initial XMPP stream initiation
      socket.write(
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<stream:stream to="$domain" xml:lang="en" version="1.0" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams">',
      );

      final result = await completer.future;
      timeoutTimer.cancel();
      collectionTimer?.cancel();
      try {
        socket.destroy();
      } catch (_) {}
      return result;
    } catch (_) {
      try {
        socket?.destroy();
      } catch (_) {}
      return const RiotSocialSyncData();
    }
  }

  /// Parse stanzas from stream: `item`, `presence`, and `message`.
  static void _parseIncomingChunk({
    required String chunk,
    required List<RiotFriendRosterItem> rosterList,
    required Map<String, RiotPresenceData> presencesMap,
    required Map<String, RiotChatMessage> messagesMap,
  }) {
    // 1. Parse Roster Items from <item ...>...</item> or self-closing <item .../>
    final itemPattern = RegExp(r'<item\b([^>]*?)>(?:([\s\S]*?)<\/item>)?|<item\b([^>]*?)\/>', caseSensitive: false);

    for (final match in itemPattern.allMatches(chunk)) {
      final attrs = match.group(1) ?? match.group(3) ?? '';
      final inner = match.group(2) ?? '';

      // Extract JID -> PUUID
      final jidMatch = RegExp(r'jid=["\x27]([^@"\x27]+)@', caseSensitive: false).firstMatch(attrs);
      final rawPuuid = jidMatch?.group(1)?.trim() ?? '';
      if (rawPuuid.isEmpty || rawPuuid == 'null') continue;

      // Extract subscription
      final subMatch = RegExp(r'subscription=["\x27]([^"\x27]*)["\x27]', caseSensitive: false).firstMatch(attrs);
      final subscription = subMatch?.group(1) ?? 'both';
      if (subscription == 'remove') continue;

      // Extract name & tagline from <id name="..." tagline="..."/> child or attrs
      String name = '';
      String? tag;

      final idTagMatch = RegExp(r'<id\b[^>]*name=["\x27]([^"\x27]*)["\x27](?:[^>]*tagline=["\x27]([^"\x27]*)["\x27])?', caseSensitive: false).firstMatch(inner);
      if (idTagMatch != null) {
        name = idTagMatch.group(1)?.trim() ?? '';
        tag = idTagMatch.group(2)?.trim();
      }

      if (name.isEmpty) {
        final nameAttrMatch = RegExp(r'name=["\x27]([^"\x27]*)["\x27]', caseSensitive: false).firstMatch(attrs);
        final rawName = nameAttrMatch?.group(1)?.trim() ?? '';
        if (rawName.contains('#')) {
          final parts = rawName.split('#');
          name = parts[0].trim();
          tag = parts.length > 1 ? parts[1].trim() : null;
        } else {
          name = rawName;
        }
      }

      if (!rosterList.any((f) => f.puuid == rawPuuid)) {
        rosterList.add(RiotFriendRosterItem(
          puuid: rawPuuid,
          name: name,
          tag: tag,
          subscription: subscription,
        ));
      }
    }

    // 2. Parse Presence Stanzas
    final presenceRegex = RegExp(
      r'<presence\b([^>]*?)>(?:([\s\S]*?)<\/presence>)?|<presence\b([^>]*?)\/>',
      caseSensitive: false,
    );

    for (final match in presenceRegex.allMatches(chunk)) {
      final presenceAttrs = match.group(1) ?? match.group(3) ?? '';
      final body = match.group(2) ?? '';

      final fromMatch = RegExp(r'from=["\x27]([^@"\x27]+)@[^/"\x27]+(?:\/([^"\x27]*))?["\x27]', caseSensitive: false).firstMatch(presenceAttrs);
      final puuid = fromMatch?.group(1)?.trim() ?? '';
      final resource = fromMatch?.group(2)?.toLowerCase().trim() ?? '';

      if (puuid.isEmpty) continue;

      // Check if unavailable (offline)
      final isUnavailable = presenceAttrs.contains('type="unavailable"') ||
          presenceAttrs.contains("type='unavailable'");

      if (isUnavailable) {
        presencesMap[puuid] = RiotPresenceData(
          puuid: puuid,
          show: 'offline',
          isOnline: false,
          clientActivity: 'Offline',
        );
        continue;
      }

      // Extract <show> (chat, away, dnd, xa)
      final showMatch = RegExp(r'<show>([^<]+)</show>', caseSensitive: false).firstMatch(body);
      final rawShow = showMatch?.group(1)?.toLowerCase().trim() ?? 'chat';

      // Extract <status>
      final statusMatch = RegExp(r'<status>([^<]*)</status>', caseSensitive: false).firstMatch(body);
      final rawStatus = statusMatch?.group(1)?.trim() ?? '';

      // Extract Base64 JSON payload in <p> tag
      final pMatch = RegExp(r'<p>([^<]+)</p>', caseSensitive: false).firstMatch(body);
      Map<String, dynamic>? valorantPayload;
      if (pMatch != null) {
        try {
          final base64Str = pMatch.group(1)!.trim();
          final normalized = base64.normalize(base64Str);
          final decodedJson = utf8.decode(base64.decode(normalized));
          valorantPayload = jsonDecode(decodedJson) as Map<String, dynamic>?;
        } catch (_) {}
      }

      final isMobile = resource.contains('mobile') ||
          resource.contains('phone') ||
          body.contains('<wildrift>') ||
          rawStatus.toLowerCase().contains('mobile');

      final isAway = rawShow == 'away' || rawShow == 'xa' || (valorantPayload?['isIdle'] == true);

      // Determine activity details
      String clientActivity = 'In Riot Client';
      String? sessionLoopState;
      String? matchMap;
      String? queueId;
      int? scoreAlly;
      int? scoreEnemy;
      int? partySize;
      int? maxPartySize;
      String? playerCardId;
      int? competitiveTier;
      int? accountLevel;

      if (valorantPayload != null && valorantPayload.isNotEmpty) {
        sessionLoopState = valorantPayload['sessionLoopState']?.toString();
        matchMap = (valorantPayload['matchMap'] ?? valorantPayload['partyOwnerMatchMap'])?.toString();
        queueId = valorantPayload['queueId']?.toString();

        final sAlly = valorantPayload['partyOwnerMatchScoreAllyTeam'] ??
            valorantPayload['partyOwnerMatchScoreAlly'];
        if (sAlly != null) scoreAlly = int.tryParse(sAlly.toString());

        final sEnemy = valorantPayload['partyOwnerMatchScoreEnemyTeam'] ??
            valorantPayload['partyOwnerMatchScoreEnemy'];
        if (sEnemy != null) scoreEnemy = int.tryParse(sEnemy.toString());

        final pSize = valorantPayload['partySize'];
        if (pSize != null) partySize = int.tryParse(pSize.toString());

        final maxPSize = valorantPayload['maxPartySize'];
        if (maxPSize != null) maxPartySize = int.tryParse(maxPSize.toString());

        playerCardId = valorantPayload['playerCardId']?.toString();
        final cTier = valorantPayload['competitiveTier'];
        if (cTier != null) competitiveTier = int.tryParse(cTier.toString());

        final aLevel = valorantPayload['accountLevel'];
        if (aLevel != null) accountLevel = int.tryParse(aLevel.toString());

        if (sessionLoopState == 'INGAME') {
          clientActivity = 'In Game';
        } else if (sessionLoopState == 'PREGAME') {
          clientActivity = 'Agent Select';
        } else if (isAway) {
          clientActivity = 'Away';
        } else if (sessionLoopState == 'MENUS') {
          clientActivity = 'In Lobby';
        }
      } else {
        if (isAway) {
          clientActivity = 'Away';
        } else if (isMobile) {
          clientActivity = 'Riot Mobile';
        }
      }

      presencesMap[puuid] = RiotPresenceData(
        puuid: puuid,
        show: rawShow,
        status: rawStatus,
        isOnline: true,
        isAway: isAway,
        isMobile: isMobile,
        clientActivity: clientActivity,
        sessionLoopState: sessionLoopState,
        matchMap: matchMap,
        queueId: queueId,
        scoreAlly: scoreAlly,
        scoreEnemy: scoreEnemy,
        partySize: partySize,
        maxPartySize: maxPartySize,
        playerCardId: playerCardId,
        competitiveTier: competitiveTier,
        accountLevel: accountLevel,
      );
    }

    // 3. Parse Chat Messages
    final messageRegex = RegExp(
      r'<message\b[^>]*from=["\x27]([^@"\x27]+)@[^/"\x27]+[^>]*>([\s\S]*?)<\/message>',
      caseSensitive: false,
    );
    for (final match in messageRegex.allMatches(chunk)) {
      final senderPuuid = match.group(1)?.trim() ?? '';
      final body = match.group(2) ?? '';
      final textMatch = RegExp(r'<body>([\s\S]*?)<\/body>', caseSensitive: false).firstMatch(body);
      final text = textMatch?.group(1)?.trim();
      if (senderPuuid.isNotEmpty && text != null && text.isNotEmpty) {
        messagesMap[senderPuuid] = RiotChatMessage(
          senderPuuid: senderPuuid,
          body: text,
          timestamp: DateTime.now(),
        );
      }
    }
  }


  /// Legacy helper for roster fetching
  Future<List<RiotFriendRosterItem>> fetchRemoteRoster({
    required String accessToken,
  }) async {
    final data = await fetchRemoteSocialData(accessToken: accessToken);
    return data.roster;
  }
}
