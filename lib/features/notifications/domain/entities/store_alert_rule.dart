import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

class StoreAlertRule extends Equatable {
  final String id;
  final String weapon;
  final List<String> tiers;
  final bool isEnabled;
  final String? customName;

  const StoreAlertRule({
    required this.id,
    required this.weapon,
    this.tiers = const [],
    this.isEnabled = true,
    this.customName,
  });

  /// Readable display name for this rule.
  String get displayName {
    if (customName != null && customName!.isNotEmpty) {
      return customName!;
    }
    final tierLabel = tiers.isEmpty ? 'Semua Tier' : tiers.join(', ');
    final weaponLabel = weapon == 'Any' ? 'Semua Senjata' : weapon;
    return '$weaponLabel ($tierLabel)';
  }

  /// Evaluates whether a [SkinItem] satisfies this alert rule.
  bool matches(SkinItem skin) {
    if (!isEnabled) return false;

    // 1. Weapon check
    final w = (skin.weaponName ?? '').trim().toLowerCase();
    final name = skin.displayName.toLowerCase();
    final targetWeapon = weapon.trim().toLowerCase();

    bool weaponMatches = false;
    if (targetWeapon == 'any') {
      weaponMatches = true;
    } else if (targetWeapon == 'melee') {
      const meleeAliases = [
        'melee',
        'knife',
        'blade',
        'sword',
        'axe',
        'dagger',
        'karambit',
        'scythe',
        'mace',
        'bat',
        'fan',
      ];
      weaponMatches = meleeAliases.contains(w) ||
          meleeAliases.any((alias) => name.contains(alias));
    } else {
      weaponMatches = w == targetWeapon || name.contains(targetWeapon);
    }

    if (!weaponMatches) return false;

    // 2. Tier check
    if (tiers.isEmpty) return true;

    final skinTier = (skin.tierName ?? '').toLowerCase();
    return tiers.any((t) => skinTier.contains(t.toLowerCase()));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'weapon': weapon,
        'tiers': tiers,
        'isEnabled': isEnabled,
        'customName': customName,
      };

  factory StoreAlertRule.fromJson(Map<String, dynamic> json) => StoreAlertRule(
        id: json['id'] as String? ?? '',
        weapon: json['weapon'] as String? ?? 'Any',
        tiers: (json['tiers'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        isEnabled: json['isEnabled'] as bool? ?? true,
        customName: json['customName'] as String?,
      );

  StoreAlertRule copyWith({
    String? id,
    String? weapon,
    List<String>? tiers,
    bool? isEnabled,
    String? customName,
  }) {
    return StoreAlertRule(
      id: id ?? this.id,
      weapon: weapon ?? this.weapon,
      tiers: tiers ?? this.tiers,
      isEnabled: isEnabled ?? this.isEnabled,
      customName: customName ?? this.customName,
    );
  }

  @override
  List<Object?> get props => [id, weapon, tiers, isEnabled, customName];
}
