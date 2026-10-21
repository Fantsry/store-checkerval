import 'dart:convert';

import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

class BackupPreview {
  final int wishlistCount;
  final int alertRuleCount;
  final int favoriteFriendCount;

  const BackupPreview({
    required this.wishlistCount,
    required this.alertRuleCount,
    required this.favoriteFriendCount,
  });
}

class BackupImportResult {
  final int wishlistCount;
  final int alertRuleCount;
  final int favoriteFriendCount;

  const BackupImportResult({
    required this.wishlistCount,
    required this.alertRuleCount,
    required this.favoriteFriendCount,
  });
}

class BackupService {
  static const int schemaVersion = 1;

  final LocalStoreService _localStore;
  final SecureStorageService _secureStorage;

  const BackupService({
    required LocalStoreService localStore,
    required SecureStorageService secureStorage,
  }) : _localStore = localStore,
       _secureStorage = secureStorage;

  Future<String> exportBackup() async {
    final wishlist = await _localStore.getWishlist();
    final alertRules = await _localStore.getAlertRules();
    final savedFriends = await _localStore.getSavedFriendsJson();

    final favorites = <Map<String, dynamic>>[];
    for (final raw in savedFriends) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map['isFavorite'] == true) favorites.add(map);
      } catch (_) {}
    }

    final settings = <String, dynamic>{
      'locale': await _localStore.getLocale(),
      'notificationsEnabled': await _secureStorage.areNotificationsEnabled(),
      'nightMarketAlertsEnabled': await _localStore
          .areNightMarketAlertsEnabled(),
      'accessoryAlertsEnabled': await _localStore.areAccessoryAlertsEnabled(),
      'chatAlertsEnabled': await _localStore.areChatAlertsEnabled(),
    };

    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'app': 'StoreCheckerVal',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': settings,
      'wishlist': wishlist.map((item) => item.toJson()).toList(),
      'alertRules': alertRules.map((rule) => rule.toJson()).toList(),
      'favoriteFriends': favorites,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  BackupPreview previewBackup(String rawJson) {
    final parsed = _parseBackup(rawJson);
    return BackupPreview(
      wishlistCount: parsed.wishlist.length,
      alertRuleCount: parsed.alertRules.length,
      favoriteFriendCount: parsed.favoriteFriends.length,
    );
  }

  Future<BackupImportResult> importBackup(
    String rawJson, {
    bool replace = false,
  }) async {
    final parsed = _parseBackup(rawJson);

    if (replace) {
      await _localStore.clearWishlist();
      await _localStore.clearAlertRules();
      await _localStore.clearFavoriteFriendFlags();
    }

    for (final item in parsed.wishlist) {
      await _localStore.addToWishlist(item);
    }
    for (final rule in parsed.alertRules) {
      await _localStore.saveAlertRule(rule);
    }
    for (final friend in parsed.favoriteFriends) {
      friend['isFavorite'] = true;
      await _localStore.saveFriendJson(
        friend['puuid'] as String,
        jsonEncode(friend),
      );
    }

    final settings = parsed.settings;
    if (settings != null) {
      if (settings.containsKey('locale')) {
        await _localStore.setLocale(settings['locale'] as String?);
      }
      final notifications = settings['notificationsEnabled'];
      if (notifications is bool) {
        await _secureStorage.setNotificationsEnabled(notifications);
      }
      final nightMarket = settings['nightMarketAlertsEnabled'];
      if (nightMarket is bool) {
        await _localStore.setNightMarketAlertsEnabled(nightMarket);
      }
      final accessories = settings['accessoryAlertsEnabled'];
      if (accessories is bool) {
        await _localStore.setAccessoryAlertsEnabled(accessories);
      }
      final chats = settings['chatAlertsEnabled'];
      if (chats is bool) {
        await _localStore.setChatAlertsEnabled(chats);
      }
    }

    return BackupImportResult(
      wishlistCount: parsed.wishlist.length,
      alertRuleCount: parsed.alertRules.length,
      favoriteFriendCount: parsed.favoriteFriends.length,
    );
  }

  _ParsedBackup _parseBackup(String rawJson) {
    final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        throw const BackupFormatException('Backup harus berupa objek JSON.');
      }
      payload = decoded;
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      throw const BackupFormatException('File backup bukan JSON yang valid.');
    }

    final version = payload['schemaVersion'];
    if (version is! int || version < 1 || version > schemaVersion) {
      throw const BackupFormatException(
        'Versi backup tidak didukung oleh aplikasi ini.',
      );
    }

    return _ParsedBackup(
      wishlist: _parseWishlist(payload['wishlist']),
      alertRules: _parseAlertRules(payload['alertRules']),
      favoriteFriends: _parseFavoriteFriends(payload['favoriteFriends']),
      settings: _parseSettings(payload['settings']),
    );
  }

  Map<String, dynamic>? _parseSettings(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      throw const BackupFormatException('Format settings tidak valid.');
    }
    final locale = raw['locale'];
    if (locale != null && locale is! String) {
      throw const BackupFormatException('Format locale tidak valid.');
    }
    if (locale is String &&
        locale.isNotEmpty &&
        locale != 'en' &&
        locale != 'id') {
      throw const BackupFormatException('Bahasa pada backup tidak didukung.');
    }
    return raw;
  }

  List<WishlistItem> _parseWishlist(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const BackupFormatException('Format wishlist tidak valid.');
    }

    final items = <WishlistItem>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw const BackupFormatException('Item wishlist tidak valid.');
      }
      final item = WishlistItem.fromJson(entry);
      if (item.uuid.isEmpty || item.displayName.isEmpty) {
        throw const BackupFormatException('Item wishlist tidak lengkap.');
      }
      items.add(item);
    }
    return items;
  }

  List<StoreAlertRule> _parseAlertRules(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const BackupFormatException('Format aturan alert tidak valid.');
    }

    final rules = <StoreAlertRule>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw const BackupFormatException('Aturan alert tidak valid.');
      }
      final rule = StoreAlertRule.fromJson(entry);
      if (rule.id.isEmpty) {
        throw const BackupFormatException('Aturan alert tidak lengkap.');
      }
      rules.add(rule);
    }
    return rules;
  }

  List<Map<String, dynamic>> _parseFavoriteFriends(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const BackupFormatException('Format teman favorit tidak valid.');
    }

    final friends = <Map<String, dynamic>>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw const BackupFormatException('Data teman favorit tidak valid.');
      }
      final puuid = entry['puuid'];
      if (puuid is! String || puuid.isEmpty) {
        throw const BackupFormatException('Data teman favorit tidak lengkap.');
      }
      friends.add(Map<String, dynamic>.from(entry));
    }
    return friends;
  }
}

class _ParsedBackup {
  final List<WishlistItem> wishlist;
  final List<StoreAlertRule> alertRules;
  final List<Map<String, dynamic>> favoriteFriends;
  final Map<String, dynamic>? settings;

  const _ParsedBackup({
    required this.wishlist,
    required this.alertRules,
    required this.favoriteFriends,
    required this.settings,
  });
}
