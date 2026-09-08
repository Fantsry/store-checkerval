class SkinPriceHelper {
  static const List<String> gunSuffixes = [
    'classic',
    'shorty',
    'frenzy',
    'ghost',
    'sheriff',
    'stinger',
    'spectre',
    'bucky',
    'judge',
    'bulldog',
    'guardian',
    'phantom',
    'vandal',
    'marshal',
    'operator',
    'ares',
    'odin',
    'outlaw',
    'bandit',
  ];

  static const List<String> meleeKeywords = [
    'melee',
    'knife',
    'blade',
    'sword',
    'axe',
    'dagger',
    'karambit',
    'splitter',
    'fist',
    'scythe',
    'bat',
    'cane',
    'wand',
    'hammer',
    'drill',
    'kunai',
    'katana',
    'fan',
    'sparkswitch',
    'flail',
    'mace',
    'claw',
    'relic',
    'glove',
    'knuckle',
    'chainsaw',
    'staff',
    'lasso',
    'misericórdia',
    'misericordia',
    'scepter',
    'crowbar',
    'baton',
    'stiletto',
    'gauntlet',
    'foil',
    'balisong',
    'bio-harvester',
    'firefly',
    'anchor',
    'crescent',
    'harvester',
    'edge',
    'judgement',
    'sugarslice',
    'flamethrower',
    'coiler',
    'prosperity',
    'divide',
    'kaimana',
    'kogitsune',
    'obsidiana',
    'songsteel',
    'terminus a quo',
    'waveform',
    'equilibrium',
    'catrina',
    'caeruleus',
    'genesis arc',
    'bound',
    'luna\'s descent',
    'keys to elysium',
    'suit of aeris',
    'hu else',
    'vct 2026 sigil',
    'spellcaster',
    'hack',
    'yaiba',
    'naru-kami',
    'comb',
    'atomizer',
    'hook',
    'wrath',
    'fury',
    'light stick',
    'onimaru',
    'kunitsuna',
    'ascender',
    'holoflare',
    'eternal sovereign',
  ];

  /// Accurately detects whether an item is a Melee skin.
  static bool isMelee({
    required String displayName,
    String? assetPath,
    String? weaponName,
  }) {
    final asset = (assetPath ?? '').toLowerCase();
    if (asset.contains('/melee/') || asset.contains('equippables/melee')) {
      return true;
    }

    final w = (weaponName ?? '').toLowerCase();
    if (w == 'melee') {
      return true;
    }

    final name = displayName.toLowerCase().trim();

    // If item ends with a known gun name, it is a gun
    for (final g in gunSuffixes) {
      if (name.endsWith(' $g') || name == g) {
        return false;
      }
    }

    if (meleeKeywords.any((k) => name.contains(k))) {
      return true;
    }

    final hasAnyGunWord =
        gunSuffixes.any((g) => name.contains(' $g') || name.startsWith('$g '));
    return !hasAnyGunWord;
  }

  /// Calculates the authentic in-game Valorant Points (VP) price.
  static int calculateEstimatedPrice({
    required String displayName,
    required bool isMelee,
    required String tierName,
  }) {
    final lowerName = displayName.toLowerCase();
    final lowerTier = tierName.toLowerCase();

    // ─── 1. Exact Special Melees ───────────────────────────
    if (isMelee) {
      // 5,950 VP (Radiant Entertainment System Ultra Melee)
      if (lowerName.contains('power fist')) {
        return 5950;
      }

      // 5,440 VP (VCT LOCK//IN)
      if (lowerName.contains('misericórdia') ||
          lowerName.contains('misericordia')) {
        return 5440;
      }

      // 5,350 VP (Phaseguard, Kuronami, Champions, Waveform, Onimaru Kunitsuna, Nocturnum)
      if (lowerName.contains('phaseguard splitter') ||
          lowerName.contains('phaseguard') ||
          lowerName.contains('kuronami') ||
          lowerName.contains('waveform') ||
          lowerName.contains('kunitsuna') ||
          lowerName.contains('nocturnum') ||
          (lowerName.contains('champions') &&
              (lowerName.contains('2021') ||
                  lowerName.contains('2022') ||
                  lowerName.contains('2023') ||
                  lowerName.contains('2024')))) {
        return 5350;
      }

      // 4,950 VP (Ultra Edition melees: Protocol 77-A, Elderflame, Evori's Spellcaster)
      if (lowerName.contains('protocol 77-a') ||
          lowerName.contains('elderflame') ||
          lowerName.contains('evori') ||
          lowerTier.contains('ultra')) {
        return 4950;
      }

      // 3,550 VP (Special priced Exclusive/Premium: Prime//2.0 Karambit, Prosperity, Aemondir, Switchback, Oni Claw)
      if (lowerName.contains('prime//2.0') ||
          lowerName.contains('prime 2.0') ||
          lowerName.contains('prosperity') ||
          lowerName.contains('aemondir') ||
          lowerName.contains('switchback') ||
          lowerName.contains('oni claw')) {
        return 3550;
      }

      // Tier-based Melee Pricing:
      if (lowerTier.contains('exclusive')) {
        return 4350; // Standard Exclusive Melee (Araxys, Reaver Karambit, RGX, Glitchpop, Singularity, etc.)
      } else if (lowerTier.contains('premium')) {
        return 3550; // Standard Premium Melee
      } else if (lowerTier.contains('deluxe')) {
        return 2550; // Standard Deluxe Melee
      } else if (lowerTier.contains('select')) {
        return 1750; // Standard Select Melee
      }

      return 3550; // Default melee fallback
    }

    // ─── 2. Guns ───────────────────────────────────────────
    if (lowerName.contains('radiant entertainment system')) {
      return 2975;
    }
    if (lowerName.contains('spectrum') || lowerName.contains('champions')) {
      return 2675;
    }
    if (lowerName.contains('kuronami')) {
      return 2375;
    }

    // Tier-based Gun Pricing:
    if (lowerTier.contains('ultra')) {
      return 2475; // Protocol, Elderflame, Evori, Phaseguard guns
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
