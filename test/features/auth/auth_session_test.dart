import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_session.dart';

void main() {
  group('AuthSession Entity', () {
    const session = AuthSession(
      accessToken: 'test_access_token',
      idToken: 'test_id_token',
      entitlementsToken: 'test_entitlements',
      puuid: '12345678-abcd-ef01-2345-6789abcdef01',
      shard: 'ap',
      region: 'ap',
      cookieJar: 'ssid=abc;',
      gameName: 'TenZ',
      tagLine: 'SEN',
    );

    test('displayName returns gameName#tagLine when both available', () {
      expect(session.displayName, 'TenZ#SEN');
    });

    test('displayName falls back to puuid substring when no gameName', () {
      const namelessSession = AuthSession(
        accessToken: 'a',
        idToken: 'b',
        entitlementsToken: 'c',
        puuid: '12345678-abcd',
        shard: 'ap',
        region: 'ap',
        cookieJar: '',
      );
      expect(namelessSession.displayName, '12345678');
    });

    test('toJson and fromJson preserves data accurately', () {
      final json = session.toJson();
      final restored = AuthSession.fromJson(json);

      expect(restored, equals(session));
      expect(restored.accessToken, 'test_access_token');
      expect(restored.shard, 'ap');
      expect(restored.gameName, 'TenZ');
      expect(restored.tagLine, 'SEN');
    });

    test('copyWith updates fields correctly', () {
      final updated = session.copyWith(
        accessToken: 'new_token',
        shard: 'na',
      );

      expect(updated.accessToken, 'new_token');
      expect(updated.shard, 'na');
      expect(updated.puuid, session.puuid);
      expect(updated.idToken, session.idToken);
    });
  });
}
