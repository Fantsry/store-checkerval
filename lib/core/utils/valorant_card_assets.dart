class ValorantCardAssets {
  ValorantCardAssets._();

  static const String defaultCardUuid = '9fb348bc-41a0-91ad-8a3e-818035c4e561';
  static const String _zeroUuid = '00000000-0000-0000-0000-000000000000';
  static const String _mediaBaseUrl =
      'https://media.valorant-api.com/playercards';

  static String? normalizeCardUuid(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty || normalized == _zeroUuid) {
      return null;
    }
    return normalized;
  }

  static bool isDefaultCard(String? value) =>
      normalizeCardUuid(value) == defaultCardUuid;

  static String? smallArt(String? cardUuid) => _artUrl(cardUuid, 'smallart');

  static String? wideArt(String? cardUuid) => _artUrl(cardUuid, 'wideart');

  static String? largeArt(String? cardUuid) => _artUrl(cardUuid, 'largeart');

  static String? _artUrl(String? cardUuid, String variant) {
    final normalized = normalizeCardUuid(cardUuid);
    if (normalized == null) return null;
    return '$_mediaBaseUrl/$normalized/$variant.png';
  }

  static String? cardIdFrom(Map<String, dynamic> source) {
    final pending = <Map<dynamic, dynamic>>[source];
    var inspected = 0;

    while (pending.isNotEmpty && inspected < 16) {
      final map = pending.removeAt(0);
      inspected++;

      for (final entry in map.entries) {
        final key = _normalizeKey(entry.key.toString());
        if (_cardKeys.contains(key)) {
          final cardId = normalizeCardUuid(entry.value?.toString());
          if (cardId != null) return cardId;
        }
      }

      for (final entry in map.entries) {
        if (entry.value is Map &&
            _containerKeys.contains(_normalizeKey(entry.key.toString()))) {
          pending.add(entry.value as Map);
        }
      }
    }

    return null;
  }

  static const Set<String> _cardKeys = {
    'playercard',
    'playercardid',
    'playercarduuid',
    'cardid',
    'carduuid',
  };

  static const Set<String> _containerKeys = {
    'identity',
    'playeridentity',
    'loadout',
    'data',
    'player',
    'playerinfo',
  };

  static String _normalizeKey(String key) =>
      key.toLowerCase().replaceAll('_', '').replaceAll('-', '');
}
