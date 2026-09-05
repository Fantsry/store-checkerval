import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

class LocalStoreService {
  static const String _wishlistBoxName = 'wishlist_box';
  static const String _skinsCacheBoxName = 'skins_cache_box';
  static const String _storeCacheBoxName = 'store_cache_box';
  static const String _profileCacheBoxName = 'profile_cache_box';

  late Box<String> _wishlistBox;
  late Box<String> _skinsCacheBox;
  late Box<String> _storeCacheBox;
  late Box<String> _profileCacheBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _wishlistBox = await Hive.openBox<String>(_wishlistBoxName);
    _skinsCacheBox = await Hive.openBox<String>(_skinsCacheBoxName);
    _storeCacheBox = await Hive.openBox<String>(_storeCacheBoxName);
    _profileCacheBox = await Hive.openBox<String>(_profileCacheBoxName);
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
}
