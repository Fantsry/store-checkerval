import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/chat_message.dart';

void main() {
  group('ChatMessageEntity', () {
    test('round-trips through JSON with delivery status', () {
      final message = ChatMessageEntity(
        id: 'm1',
        body: 'halo <&>',
        timestamp: DateTime.utc(2026, 10, 20, 8, 7, 33),
        isMine: true,
        status: ChatMessageStatus.failed,
      );

      final decoded = ChatMessageEntity.fromJson(message.toJson());

      expect(decoded.id, 'm1');
      expect(decoded.body, 'halo <&>');
      expect(decoded.timestamp, DateTime.utc(2026, 10, 20, 8, 7, 33));
      expect(decoded.isMine, isTrue);
      expect(decoded.status, ChatMessageStatus.failed);
    });

    test('merge deduplicates by id and keeps the newest copy', () {
      final old = ChatMessageEntity(
        id: 'm1',
        body: 'halo',
        timestamp: DateTime.utc(2026, 10, 20, 8, 7, 33),
        isMine: true,
      );
      final updated = old.copyWith(status: ChatMessageStatus.sent);

      final merged = mergeChatMessages([old], updated);

      expect(merged, [updated]);
      expect(merged.single.status, ChatMessageStatus.sent);
    });

    test('merge caps history to the 200 newest messages', () {
      final history = List.generate(
        200,
        (i) => ChatMessageEntity(
          id: '$i',
          body: 'm$i',
          timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
          isMine: false,
        ),
      );
      final newest = ChatMessageEntity(
        id: 'new',
        body: 'baru',
        timestamp: DateTime.utc(2026, 1, 1).add(const Duration(seconds: 200)),
        isMine: true,
      );

      final merged = mergeChatMessages(history, newest);

      expect(merged.length, 200);
      expect(merged.first.id, '1');
      expect(merged.last.id, 'new');
    });
  });
}
