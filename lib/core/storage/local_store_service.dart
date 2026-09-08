import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

class LocalStoreService {
  static const String _wishlistBoxName = 'wishlist_box';
  static const String _skinsCacheBoxName = 'skins_cache_box';
  static const String _storeCacheBoxName = 'store_cache_box';
  static const String _profileCacheBoxName = 'profile_cache_box';
  static const String _alertRulesBoxName = 'alert_rules_box';
  static const String _careerCacheBoxName = 'career_cache_box';

  late Box<String> _wishlistBox;
  late Box<String> _skinsCacheBox;
  late Box<String> _storeCacheBox;
  late Box<String> _profileCacheBox;
  late Box<String> _alertRulesBox;
  late Box<String> _careerCacheBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _wishlistBox = await Hive.openBox<String>(_wishlistBoxName);
    _skinsCacheBox = await Hive.openBox<String>(_skinsCacheBoxName);
    _storeCacheBox = await Hive.openBox<String>(_storeCacheBoxName);
    _profileCacheBox = await Hive.openBox<String>(_profileCacheBoxName);
    _alertRulesBox = await Hive.openBox<String>(_alertRulesBoxName);
    _careerCacheBox = await Hive.openBox<String>(_careerCacheBoxName);
  }

  // ─── Wishlist Operations ───────────────────────────────────

  Future<List<WishlistItem>> getWishlist() async {
    final list = <WishlistItem>[];
    for (final value in _wishlistBox.values) {
      try {
        final map = jsonDecode(value) as Map<String, dynamic>;
        list.add(WishlistItem.fromJson(map));
      } catch (_) {}
    }
    // Sort by newest added first
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  Future<void> addToWishlist(WishlistItem item) async {
    final jsonStr = jsonEncode(item.toJson());
    await _wishlistBox.put(item.uuid, jsonStr);
  }

  Future<void> removeFromWishlist(String uuid) async {
    await _wishlistBox.delete(uuid);
  }

  bool isInWishlist(String uuid) {
    return _wishlistBox.containsKey(uuid);
  }

  Future<void> clearWishlist() async {
    await _wishlistBox.clear();
  }

  // ─── Skins Catalog Cache ───────────────────────────────────

  Future<List<SkinItem>?> getCachedSkins() async {
    final raw = _skinsCacheBox.get('all_skins');
    if (raw == null || raw.isEmpty) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SkinItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCachedSkins(List<SkinItem> skins) async {
    final jsonStr = jsonEncode(skins.map((s) => s.toJson()).toList());
    await _skinsCacheBox.put('all_skins', jsonStr);
    await _skinsCacheBox.put(
      'all_skins_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  // ─── Daily Store Offline Cache ─────────────────────────────

  Future<DailyStore?> getCachedDailyStore() async {
    final raw = _storeCacheBox.get('latest_daily_store');
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DailyStore.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDailyStore(DailyStore store) async {
    final jsonStr = jsonEncode(store.toJson());
    await _storeCacheBox.put('latest_daily_store', jsonStr);
  }

  // ─── Player Profile Offline Cache ──────────────────────────

  Future<UserProfile?> getCachedProfile() async {
    final raw = _profileCacheBox.get('latest_user_profile');
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCachedProfile(UserProfile profile) async {
    final jsonStr = jsonEncode(profile.toJson());
    await _profileCacheBox.put('latest_user_profile', jsonStr);
  }

  Future<void> clearCachedProfile() async {
    await _profileCacheBox.delete('latest_user_profile');
  }

  // ─── Store Alert Rules Operations ─────────────────────────

  static final List<StoreAlertRule> _defaultAlertRules = [
    const StoreAlertRule(
      id: 'default_melee',
      weapon: 'Melee',
      tiers: [],
      isEnabled: true,
      customName: '🗡️ Setiap Melee / Pisau',
    ),
    const StoreAlertRule(
      id: 'default_vandal_premium',
      weapon: 'Vandal',
      tiers: ['Premium', 'Exclusive', 'Ultra'],
      isEnabled: true,
      customName: '🎯 Vandal (Tier Premium+)',
    ),
    const StoreAlertRule(
      id: 'default_phantom_premium',
      weapon: 'Phantom',
      tiers: ['Premium', 'Exclusive', 'Ultra'],
      isEnabled: true,
      customName: '👻 Phantom (Tier Premium+)',
    ),
    const StoreAlertRule(
      id: 'default_operator',
      weapon: 'Operator',
      tiers: ['Premium', 'Exclusive', 'Ultra'],
      isEnabled: false,
      customName: '🔭 Operator (Tier Premium+)',
    ),
    const StoreAlertRule(
      id: 'default_sheriff',
      weapon: 'Sheriff',
      tiers: ['Deluxe', 'Premium', 'Exclusive', 'Ultra'],
      isEnabled: false,
      customName: '🎯 Sheriff (Deluxe/Premium+)',
    ),
    const StoreAlertRule(
      id: 'default_ghost',
      weapon: 'Ghost',
      tiers: ['Deluxe', 'Premium', 'Exclusive'],
      isEnabled: false,
      customName: '🔫 Ghost (Deluxe/Premium)',
    ),
  ];

  Future<List<StoreAlertRule>> getAlertRules() async {
    if (_alertRulesBox.isEmpty) {
      // Seed default rules on first run
      for (final rule in _defaultAlertRules) {
        await _alertRulesBox.put(rule.id, jsonEncode(rule.toJson()));
      }
      return List.from(_defaultAlertRules);
    }

    final rules = <StoreAlertRule>[];
    for (final value in _alertRulesBox.values) {
      try {
        final map = jsonDecode(value) as Map<String, dynamic>;
        rules.add(StoreAlertRule.fromJson(map));
      } catch (_) {}
    }

    // Ensure Phantom preset is seeded if not present
    if (!rules.any((r) => r.weapon.toLowerCase() == 'phantom')) {
      const phantomRule = StoreAlertRule(
        id: 'default_phantom_premium',
        weapon: 'Phantom',
        tiers: ['Premium', 'Exclusive', 'Ultra'],
        isEnabled: true,
        customName: '👻 Phantom (Tier Premium+)',
      );
      await _alertRulesBox.put(
        phantomRule.id,
        jsonEncode(phantomRule.toJson()),
      );
      rules.add(phantomRule);
    }

    return rules;
  }

  Future<void> saveAlertRule(StoreAlertRule rule) async {
    await _alertRulesBox.put(rule.id, jsonEncode(rule.toJson()));
  }

  Future<void> deleteAlertRule(String id) async {
    await _alertRulesBox.delete(id);
  }

  Future<void> toggleAlertRule(String id, bool isEnabled) async {
    final raw = _alertRulesBox.get(id);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final rule =
            StoreAlertRule.fromJson(map).copyWith(isEnabled: isEnabled);
        await _alertRulesBox.put(id, jsonEncode(rule.toJson()));
      } catch (_) {}
    }
  }

  // ─── Notification Deduplication ────────────────────────────

  Future<String?> getLastNotifiedStoreDate() async {
    return _storeCacheBox.get('last_notified_store_date');
  }

  Future<void> setLastNotifiedStoreDate(String dateStr) async {
    await _storeCacheBox.put('last_notified_store_date', dateStr);
  }

  // ─── Career & Match History Cache ──────────────────────────

  Future<String?> getCachedCareerJson(String puuid) async {
    return _careerCacheBox.get('career_$puuid');
  }

  Future<void> saveCachedCareerJson(String puuid, String jsonStr) async {
    await _careerCacheBox.put('career_$puuid', jsonStr);
  }

  Future<void> clearCareerCache() async {
    await _careerCacheBox.clear();
  }

  // ─── Generic Key-Value Map Cache ───────────────────────────

  Map<String, dynamic>? getMap(String key) {
    final raw = _storeCacheBox.get(key);
    if (raw != null) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> setMap(String key, Map<String, dynamic> map) async {
    await _storeCacheBox.put(key, jsonEncode(map));
  }
}
