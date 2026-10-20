import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';

/// Friend item parsed from Riot's remote XMPP roster service.
class RiotFriendRosterItem {
  final String puuid;
  final String jid;
  final String name; // GameName or GameName#Tag
  final String? tag;
  final String subscription;

  const RiotFriendRosterItem({
    required this.puuid,
    this.jid = '',
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
  final String id;
  final String senderPuuid;
  final String body;
  final DateTime timestamp;

  const RiotChatMessage({
    this.id = '',
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
  final List<RiotChatMessage> messages;
  final String? sentMessageId;
  final String? sendError;

  const RiotSocialSyncData({
    this.roster = const [],
    this.presences = const {},
    this.recentMessages = const {},
    this.messages = const [],
    this.sentMessageId,
    this.sendError,
  });
}

class RiotChatSendResult {
  final bool isSuccess;
  final String? messageId;
  final String? error;
  final List<RiotChatMessage> messages;

  const RiotChatSendResult({
    required this.isSuccess,
    this.messageId,
    this.error,
    this.messages = const [],
  });

  const RiotChatSendResult.success({
    required String messageId,
    List<RiotChatMessage> messages = const [],
  }) : this(
          isSuccess: true,
          messageId: messageId,
          messages: messages,
        );

  const RiotChatSendResult.failure(String error)
      : this(isSuccess: false, error: error);
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

  Future<RiotChatSendResult> sendChatMessage({
    required String accessToken,
    String? entitlementToken,
    required String recipientJid,
    required String body,
  }) async {
    final pasInfo = await fetchPasToken(accessToken: accessToken);
    if (pasInfo == null) {
      return const RiotChatSendResult.failure(
        'Gagal mendapatkan token chat Riot',
      );
    }

    final pasToken = pasInfo['pasToken']!;
    final affinity = pasInfo['affinity']!;
    final routing = await fetchChatRouting(
      accessToken: accessToken,
      affinity: affinity,
      entitlementToken: entitlementToken,
    );

    final host = routing['host']!;
    final domain = routing['domain']!;
    final randomHex =
        Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final messageId =
        'msg-${DateTime.now().microsecondsSinceEpoch}-$randomHex';

    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        host,
        5223,
        timeout: const Duration(seconds: 7),
      );

      final completer = Completer<RiotChatSendResult>();
      int step = 0;
      bool messageSent = false;
      Timer? successTimer;

      void finish(RiotChatSendResult result) {
        if (!completer.isCompleted) {
          successTimer?.cancel();
          completer.complete(result);
        }
      }

      final timeoutTimer = Timer(
        const Duration(seconds: 8),
        () => finish(
          const RiotChatSendResult.failure(
            'Waktu koneksi chat habis sebelum pesan terkirim',
          ),
        ),
      );

      socket.listen(
        (data) {
          final chunk = utf8.decode(data, allowMalformed: true);
          final lower = chunk.toLowerCase();

          if (messageSent &&
              (lower.contains('type="error"') ||
                  lower.contains("type='error'"))) {
            finish(
              const RiotChatSendResult.failure(
                'Server Riot menolak pesan',
              ),
            );
            return;
          }

          if (step == 0 &&
              (chunk.contains('<stream:features') ||
                  chunk.contains('X-Riot-RSO-PAS'))) {
            step = 1;
            socket!.write(
              '<auth mechanism="X-Riot-RSO-PAS" '
              'xmlns="urn:ietf:params:xml:ns:xmpp-sasl">'
              '<rso_token>$accessToken</rso_token>'
              '<pas_token>$pasToken</pas_token>'
              '</auth>',
            );
          } else if (step == 1 && chunk.contains('<success')) {
            step = 2;
            socket!.write(
              '<?xml version="1.0" encoding="UTF-8"?>'
              '<stream:stream to="$domain" xml:lang="en" version="1.0" '
              'xmlns="jabber:client" '
              'xmlns:stream="http://etherx.jabber.org/streams">',
            );
          } else if (step == 2 &&
              (chunk.contains('<stream:features') ||
                  chunk.contains('<bind'))) {
            step = 3;
            socket!.write(
              '<iq id="_xmpp_bind1" type="set">'
              '<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">'
              '<puuid-mode enabled="true"/>'
              '<resource>RC-$randomHex</resource>'
              '</bind>'
              '</iq>',
            );
          } else if (step == 3 && chunk.contains('_xmpp_bind1')) {
            step = 4;
            socket!.write(
              '<iq id="_xmpp_session1" type="set">'
              '<session xmlns="urn:ietf:params:xml:ns:xmpp-session"/>'
              '</iq>',
            );
          } else if (step == 4 && chunk.contains('_xmpp_session1')) {
            step = 5;

            if (entitlementToken != null && entitlementToken.isNotEmpty) {
              socket!.write(
                '<iq id="xmpp_entitlements_0" type="set">'
                '<entitlements xmlns="urn:riotgames:entitlements">'
                '<token xmlns="">$entitlementToken</token>'
                '</entitlements>'
                '</iq>',
              );
            }

            socket!.write(
              buildChatMessageStanza(
                id: messageId,
                toJid: recipientJid,
                body: body,
              ),
            );
            messageSent = true;

            successTimer = Timer(
              const Duration(milliseconds: 1200),
              () => finish(
                RiotChatSendResult.success(
                  messageId: messageId,
                  messages: const [],
                ),
              ),
            );
          }
        },
        onError: (Object _) {
          if (messageSent) {
            finish(
              RiotChatSendResult.success(
                messageId: messageId,
                messages: const [],
              ),
            );
          } else {
            finish(
              const RiotChatSendResult.failure(
                'Koneksi chat terputus sebelum pesan terkirim',
              ),
            );
          }
        },
        onDone: () {
          if (messageSent && !completer.isCompleted) {
            finish(
              RiotChatSendResult.success(
                messageId: messageId,
                messages: const [],
              ),
            );
          } else if (!messageSent && !completer.isCompleted) {
            finish(
              const RiotChatSendResult.failure(
                'Koneksi chat ditutup sebelum pesan terkirim',
              ),
            );
          }
        },
      );

      socket.write(
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<stream:stream to="$domain" xml:lang="en" version="1.0" '
        'xmlns="jabber:client" '
        'xmlns:stream="http://etherx.jabber.org/streams">',
      );

      final result = await completer.future;
      timeoutTimer.cancel();
      return result;
    } catch (e) {
      return RiotChatSendResult.failure(
        'Gagal mengirim pesan chat: $e',
      );
    } finally {
      try {
        socket?.destroy();
      } catch (_) {}
    }
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
      final List<RiotChatMessage> messagesList = [];

      Timer? collectionTimer;

      void finish() {
        if (!completer.isCompleted) {
          collectionTimer?.cancel();
          completer.complete(RiotSocialSyncData(
            roster: rosterList,
            presences: presencesMap,
            recentMessages: messagesMap,
            messages: messagesList,
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
              messagesList: messagesList,
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
    required List<RiotChatMessage> messagesList,
  }) {
    // 1. Parse Roster Items from <item ...>...</item> or self-closing <item .../>
    for (final item in parseRosterItems(chunk)) {
      if (!rosterList.any((f) => f.puuid == item.puuid)) {
        rosterList.add(item);
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
    for (final message in parseChatMessages(chunk)) {
      messagesList.add(message);
      final existing = messagesMap[message.senderPuuid];
      if (existing == null || message.timestamp.isAfter(existing.timestamp)) {
        messagesMap[message.senderPuuid] = message;
      }
    }
  }

  static List<RiotFriendRosterItem> parseRosterItems(String chunk) {
    final items = <RiotFriendRosterItem>[];
    final itemPattern = RegExp(
      r'<item\b([^>]*?)>(?:([\s\S]*?)<\/item>)?|<item\b([^>]*?)\/>',
      caseSensitive: false,
    );

    for (final match in itemPattern.allMatches(chunk)) {
      final attrs = match.group(1) ?? match.group(3) ?? '';
      final inner = match.group(2) ?? '';

      final jid = _readAttribute(attrs, 'jid') ?? '';
      final atIndex = jid.indexOf('@');
      final rawPuuid =
          atIndex > 0 ? jid.substring(0, atIndex).trim() : '';
      if (rawPuuid.isEmpty || rawPuuid == 'null') continue;

      final subscription = _readAttribute(attrs, 'subscription') ?? 'both';
      if (subscription == 'remove') continue;

      String name = '';
      String? tag;

      final idTagMatch = RegExp(
        r'<id\b[^>]*name=["\x27]([^"\x27]*)["\x27](?:[^>]*tagline=["\x27]([^"\x27]*)["\x27])?',
        caseSensitive: false,
      ).firstMatch(inner);
      if (idTagMatch != null) {
        name = idTagMatch.group(1)?.trim() ?? '';
        tag = idTagMatch.group(2)?.trim();
      }

      if (name.isEmpty) {
        final rawName = _readAttribute(attrs, 'name') ?? '';
        if (rawName.contains('#')) {
          final parts = rawName.split('#');
          name = parts[0].trim();
          tag = parts.length > 1 ? parts[1].trim() : null;
        } else {
          name = rawName;
        }
      }

      items.add(RiotFriendRosterItem(
        puuid: rawPuuid,
        jid: jid,
        name: name,
        tag: tag,
        subscription: subscription,
      ));
    }

    return items;
  }

  static String buildChatMessageStanza({
    required String id,
    required String toJid,
    required String body,
  }) {
    return '<message id="${_escapeXml(id)}" to="${_escapeXml(toJid)}" type="chat">'
        '<body>${_escapeXml(body)}</body>'
        '</message>';
  }

  static List<RiotChatMessage> parseChatMessages(String chunk) {
    final messages = <RiotChatMessage>[];
    final messageRegex = RegExp(
      r'<message\b([^>]*)>([\s\S]*?)<\/message>',
      caseSensitive: false,
    );

    for (final match in messageRegex.allMatches(chunk)) {
      final attrs = match.group(1) ?? '';
      final inner = match.group(2) ?? '';
      final type = _readAttribute(attrs, 'type')?.toLowerCase() ?? 'chat';
      if (type == 'groupchat' || type == 'error') continue;

      final from = _readAttribute(attrs, 'from') ?? '';
      final senderPuuid = from.split('@').first.trim();
      if (senderPuuid.isEmpty || !from.contains('@')) continue;

      final bodyMatch = RegExp(
        r'<body\b[^>]*>([\s\S]*?)<\/body>',
        caseSensitive: false,
      ).firstMatch(inner);
      final text = _unescapeXml(bodyMatch?.group(1)?.trim() ?? '');
      if (text.isEmpty) continue;

      final timestamp =
          _parseTimestamp(_readAttribute(attrs, 'stamp')) ??
          _parseTimestamp(_readAttribute(inner, 'stamp')) ??
          DateTime.now();
      final id = _readAttribute(attrs, 'id') ??
          'srv_${senderPuuid}_${timestamp.microsecondsSinceEpoch}';

      messages.add(RiotChatMessage(
        id: id,
        senderPuuid: senderPuuid,
        body: text,
        timestamp: timestamp,
      ));
    }

    return messages;
  }

  static String? _readAttribute(String source, String name) {
    final match = RegExp(
      '\\b${RegExp.escape(name)}\\s*=\\s*["\']([^"\']*)["\']',
      caseSensitive: false,
    ).firstMatch(source);
    return match?.group(1)?.trim();
  }

  static DateTime? _parseTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _unescapeXml(String value) {
    var result = value
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!)),
    );
    return result;
  }


  /// Legacy helper for roster fetching
  Future<List<RiotFriendRosterItem>> fetchRemoteRoster({
    required String accessToken,
  }) async {
    final data = await fetchRemoteSocialData(accessToken: accessToken);
    return data.roster;
  }
}
