import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/social/data/datasources/riot_chat_remote_datasource.dart';

void main() {
  group('parseIncomingChunk presences', () {
    test('keeps split presence payload until the stanza is complete', () {
      const puuid = 'friend-puuid';
      const cardId = '11111111-2222-3333-4444-555555555555';
      final payload = base64Encode(
        utf8.encode(
          jsonEncode({
            'sessionLoopState': 'MENUS',
            'playerCardId': cardId,
            'accountLevel': 227,
          }),
        ),
      );
      final opening =
          '<presence from="$puuid@eu1.pvp.net/RC-1">'
          '<show>chat</show><status></status>'
          '<games><valorant><p>';
      final closing = '$payload</p></valorant></games></presence>';

      final roster = <RiotFriendRosterItem>[];
      final presences = <String, RiotPresenceData>{};
      final messages = <RiotChatMessage>[];
      final messageMap = <String, RiotChatMessage>{};

      void parse(String chunk) {
        RiotChatRemoteDataSource.parseIncomingChunk(
          chunk: chunk,
          rosterList: roster,
          presencesMap: presences,
          messagesMap: messageMap,
          messagesList: messages,
        );
      }

      parse(opening);
      expect(presences, isEmpty);

      parse(opening + closing);
      expect(presences[puuid]?.playerCardId, cardId);
      expect(presences[puuid]?.accountLevel, 227);
      expect(presences[puuid]?.clientActivity, 'In Lobby');
    });
  });

  group('buildChatMessageStanza', () {
    test('builds an escaped direct chat stanza', () {
      final stanza = RiotChatRemoteDataSource.buildChatMessageStanza(
        id: 'm1',
        toJid: 'friend-puuid@eu1.pvp.net',
        body: 'a < b & "c"',
      );

      expect(
        stanza,
        '<message id="m1" to="friend-puuid@eu1.pvp.net" type="chat">'
        '<body>a &lt; b &amp; &quot;c&quot;</body></message>',
      );
    });
  });

  group('parseRosterItems', () {
    test('preserves the full roster JID for direct messages', () {
      const chunk =
          '<iq type="result" id="roster_1">'
          '<query xmlns="jabber:iq:riotgames:roster">'
          '<item jid="friend-puuid@eu1.pvp.net" subscription="both">'
          '<id name="Friend" tagline="123"/>'
          '</item>'
          '</query></iq>';

      final items = RiotChatRemoteDataSource.parseRosterItems(chunk);

      expect(items, hasLength(1));
      expect(items.single.puuid, 'friend-puuid');
      expect(items.single.jid, 'friend-puuid@eu1.pvp.net');
      expect(items.single.name, 'Friend');
      expect(items.single.tag, '123');
    });
  });

  group('parseChatMessages', () {
    test('parses id, sender, timestamp, and unescaped body', () {
      const chunk =
          '<message id="srv-1" from="friend-puuid@eu1.pvp.net/RC-1" '
          'to="self@eu1.pvp.net" type="chat" stamp="2026-10-20 08:07:33.000">'
          '<body>halo &amp; hai</body></message>';

      final messages = RiotChatRemoteDataSource.parseChatMessages(chunk);

      expect(messages, hasLength(1));
      expect(messages.single.id, 'srv-1');
      expect(messages.single.senderPuuid, 'friend-puuid');
      expect(messages.single.body, 'halo & hai');
      expect(messages.single.timestamp, DateTime(2026, 10, 20, 8, 7, 33));
    });

    test('ignores groupchat and error stanzas', () {
      const chunk = '''
<message id="g1" from="friend-puuid@eu1.pvp.net" type="groupchat">
<body>party chat</body>
</message>
<message id="e1" from="friend-puuid@eu1.pvp.net" type="error">
<body>failed</body>
</message>
<message id="d1" from="friend-puuid@eu1.pvp.net" type="chat">
<body>direct</body>
</message>
''';

      final messages = RiotChatRemoteDataSource.parseChatMessages(chunk);

      expect(messages.map((m) => m.id), ['d1']);
    });

    test('uses the XMPP delay stamp when the stanza has no stamp', () {
      const chunk =
          '<message id="srv-2" from="friend-puuid@eu1.pvp.net" type="chat">'
          '<body>offline</body>'
          '<delay xmlns="urn:xmpp:delay" stamp="2026-10-19T21:00:00Z"/>'
          '</message>';

      final messages = RiotChatRemoteDataSource.parseChatMessages(chunk);

      expect(messages.single.timestamp.toUtc(), DateTime.utc(2026, 10, 19, 21));
    });
  });
}
