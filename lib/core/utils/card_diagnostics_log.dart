class CardDiagnosticEvent {
  final String source;
  final String? shard;
  final int? statusCode;
  final String? error;
  final String? detail;
  final List<String> bodyKeys;
  final List<String> identityKeys;
  final String? cardId;
  final bool hasAuthorization;
  final bool hasEntitlements;
  final bool hasClientVersion;

  const CardDiagnosticEvent({
    required this.source,
    this.shard,
    this.statusCode,
    this.error,
    this.detail,
    this.bodyKeys = const [],
    this.identityKeys = const [],
    this.cardId,
    this.hasAuthorization = false,
    this.hasEntitlements = false,
    this.hasClientVersion = false,
  });
}

class CardDiagnosticsLog {
  CardDiagnosticsLog({this.maxEvents = 80}) : assert(maxEvents > 0);

  static final CardDiagnosticsLog instance = CardDiagnosticsLog();

  final int maxEvents;
  final List<CardDiagnosticEvent> _events = [];

  List<CardDiagnosticEvent> get events => List.unmodifiable(_events);

  void record(CardDiagnosticEvent event) {
    _events.add(event);
    if (_events.length > maxEvents) {
      _events.removeRange(0, _events.length - maxEvents);
    }
  }

  void clear() => _events.clear();
}
