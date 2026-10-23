import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/core/utils/card_diagnostics_log.dart';

void main() {
  test('keeps only the latest diagnostic events', () {
    final log = CardDiagnosticsLog(maxEvents: 2);

    log.record(const CardDiagnosticEvent(source: 'loadout', shard: 'ap'));
    log.record(const CardDiagnosticEvent(source: 'loadout', shard: 'eu'));
    log.record(const CardDiagnosticEvent(source: 'loadout', shard: 'na'));

    expect(log.events.map((event) => event.shard), ['eu', 'na']);
  });
}
