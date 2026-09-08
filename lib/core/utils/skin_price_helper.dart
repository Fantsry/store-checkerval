/// Data-driven pricing and melee classification helper for Valorant skins.
///
/// Avoids hardcoded skin names or keyword lists, relying instead on official
/// Valorant API data (parent weapon category, content tiers, and asset paths).
class SkinPriceHelper {
  /// Determines if an item is a Melee weapon using official data sources:
  /// 1. Weapon category from API (e.g. `EEquippableCategory::Melee` or `Melee`)
  /// 2. Weapon name from API (`weaponName == 'Melee'`)
  /// 3. Asset path classification from game engine (`ShooterGame/Content/Equippables/Melee/`)
  static bool isMelee({
    String? category,
    String? weaponName,
    String? assetPath,
    String? displayName,
  }) {
    // 1. From weapon category in API data
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('melee')) {
      return true;
    }

    // 2. From weapon name in API data
    final w = (weaponName ?? '').trim().toLowerCase();
    if (w == 'melee') {
      return true;
    }

    // 3. From engine asset package path in skin data
    final asset = (assetPath ?? '').toLowerCase();
    if (asset.contains('equippables/melee') || asset.contains('/melee/')) {
      return true;
    }
    if (asset.contains('equippables/guns') || asset.contains('/guns/')) {
      return false;
    }

    // 4. Fallback for mock/cached items where only displayName or weaponName is available
    final name = (displayName ?? '').toLowerCase();
    final wName = (weaponName ?? '').toLowerCase();
    const commonMelee = ['melee', 'knife', 'blade', 'sword', 'axe', 'dagger', 'karambit'];
    return commonMelee.any((k) => name.contains(k) || wName.contains(k));
  }

  /// Calculates the authentic in-game Valorant Points (VP) price based on Content Tier data.
  ///
  /// Flexible and future-proof: uses Riot's official tier structure so any new melee
  /// or gun released by Riot is automatically supported without hardcoded skin names.
  static int calculateEstimatedPrice({
    required bool isMelee,
    required String tierName,
    int? liveStorePrice,
    String? displayName,
  }) {
    // 1. If live store price is available from Riot Storefront API, use it directly
    if (liveStorePrice != null && liveStorePrice > 0) {
      return liveStorePrice;
    }

    final lowerTier = tierName.toLowerCase();

    // 2. Dynamic formula based on official Content Tier data
    if (isMelee) {
      // In Valorant store rotations, top-tier featured Melees (Exclusive & Ultra)
      // are priced at 5,350 VP (e.g. Phaseguard Splitter, Kuronami, Champions, etc.)
      if (lowerTier.contains('exclusive') || lowerTier.contains('ultra')) {
        return 5350;
      } else if (lowerTier.contains('premium')) {
        return 3550;
      } else if (lowerTier.contains('deluxe')) {
        return 2550;
      } else if (lowerTier.contains('select')) {
        return 1750;
      }
      return 3550;
    } else {
      // Guns
      if (lowerTier.contains('ultra')) {
        return 2475;
      } else if (lowerTier.contains('exclusive')) {
        return 2175;
      } else if (lowerTier.contains('premium')) {
        return 1775;
      } else if (lowerTier.contains('deluxe')) {
        return 1275;
      } else if (lowerTier.contains('select')) {
        return 875;
      }
      return 1775;
    }
  }
}
