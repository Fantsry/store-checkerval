import 'package:equatable/equatable.dart';

enum ChatMessageStatus { sending, sent, failed }

class ChatMessageEntity extends Equatable {
  final String id;
  final String body;
  final DateTime timestamp;
  final bool isMine;
  final ChatMessageStatus status;

  const ChatMessageEntity({
    required this.id,
    required this.body,
    required this.timestamp,
    required this.isMine,
    this.status = ChatMessageStatus.sent,
  });

  ChatMessageEntity copyWith({ChatMessageStatus? status}) {
    return ChatMessageEntity(
      id: id,
      body: body,
      timestamp: timestamp,
      isMine: isMine,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isMine': isMine,
        'status': status.name,
      };

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isMine: json['isMine'] as bool? ?? false,
      status: ChatMessageStatus.values.firstWhere(
        (value) => value.name == (json['status'] as String? ?? 'sent'),
        orElse: () => ChatMessageStatus.sent,
      ),
    );
  }

  @override
  List<Object?> get props => [id, body, timestamp, isMine, status];
}

List<ChatMessageEntity> mergeChatMessages(
  List<ChatMessageEntity> history,
  ChatMessageEntity message, {
  int maxMessages = 200,
}) {
  final byId = <String, ChatMessageEntity>{
    for (final existing in history) existing.id: existing,
    message.id: message,
  };

  final merged = byId.values.toList()
    ..sort((a, b) {
      final byTime = a.timestamp.compareTo(b.timestamp);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

  if (merged.length <= maxMessages) return merged;
  return merged.sublist(merged.length - maxMessages);
}
