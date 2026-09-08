import 'package:equatable/equatable.dart';

class OwnedSkinItem extends Equatable {
  final String uuid;
  final String displayName;
  final String? displayIcon;
  final int cost;
  final String? tierName;
  final String? tierColor;
  final String weapon;
  final bool isEquipped;

  const OwnedSkinItem({
    required this.uuid,
    required this.displayName,
    this.displayIcon,
    this.cost = 0,
    this.tierName,
    this.tierColor,
    this.weapon = 'Weapon',
    this.isEquipped = false,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'displayIcon': displayIcon,
        'cost': cost,
        'tierName': tierName,
        'tierColor': tierColor,
        'weapon': weapon,
        'isEquipped': isEquipped,
      };

  factory OwnedSkinItem.fromJson(Map<String, dynamic> json) => OwnedSkinItem(
        uuid: json['uuid'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        displayIcon: json['displayIcon'] as String?,
        cost: json['cost'] as int? ?? 0,
        tierName: json['tierName'] as String?,
        tierColor: json['tierColor'] as String?,
        weapon: json['weapon'] as String? ?? 'Weapon',
        isEquipped: json['isEquipped'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        uuid,
        displayName,
        displayIcon,
        cost,
        tierName,
        tierColor,
        weapon,
        isEquipped,
      ];
}

class EquippedWeaponSkin extends Equatable {
  final String weaponId;
  final String weaponName;
  final String skinId;
  final String skinName;
  final String? skinIcon;
  final String? tierColor;

  const EquippedWeaponSkin({
    required this.weaponId,
    required this.weaponName,
    required this.skinId,
    required this.skinName,
    this.skinIcon,
    this.tierColor,
  });

  Map<String, dynamic> toJson() => {
        'weaponId': weaponId,
        'weaponName': weaponName,
        'skinId': skinId,
        'skinName': skinName,
        'skinIcon': skinIcon,
        'tierColor': tierColor,
      };

  factory EquippedWeaponSkin.fromJson(Map<String, dynamic> json) =>
      EquippedWeaponSkin(
        weaponId: json['weaponId'] as String? ?? '',
        weaponName: json['weaponName'] as String? ?? '',
        skinId: json['skinId'] as String? ?? '',
        skinName: json['skinName'] as String? ?? '',
        skinIcon: json['skinIcon'] as String?,
        tierColor: json['tierColor'] as String?,
      );

  @override
  List<Object?> get props => [
        weaponId,
        weaponName,
        skinId,
        skinName,
        skinIcon,
        tierColor,
      ];
}

class InventoryOverview extends Equatable {
  final int totalVpSpent;
  final int totalEstimatedIdr;
  final int totalSkinsCount;
  final Map<String, int> tierBreakdown;
  final List<OwnedSkinItem> ownedSkins;
  final List<EquippedWeaponSkin> equippedWeapons;

  const InventoryOverview({
    this.totalVpSpent = 0,
    this.totalEstimatedIdr = 0,
    this.totalSkinsCount = 0,
    this.tierBreakdown = const {},
    this.ownedSkins = const [],
    this.equippedWeapons = const [],
  });

  /// Formatted Rupiah string (e.g. "Rp 1.450.000")
  String get formattedEstimatedIdr {
    final s = totalEstimatedIdr.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  Map<String, dynamic> toJson() => {
        'totalVpSpent': totalVpSpent,
        'totalEstimatedIdr': totalEstimatedIdr,
        'totalSkinsCount': totalSkinsCount,
        'tierBreakdown': tierBreakdown,
        'ownedSkins': ownedSkins.map((s) => s.toJson()).toList(),
        'equippedWeapons': equippedWeapons.map((w) => w.toJson()).toList(),
      };

  factory InventoryOverview.fromJson(Map<String, dynamic> json) {
    final skinsRaw = json['ownedSkins'] as List<dynamic>? ?? [];
    final equippedRaw = json['equippedWeapons'] as List<dynamic>? ?? [];
    final tierMap = (json['tierBreakdown'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as int? ?? 0),
        ) ??
        {};

    return InventoryOverview(
      totalVpSpent: json['totalVpSpent'] as int? ?? 0,
      totalEstimatedIdr: json['totalEstimatedIdr'] as int? ?? 0,
      totalSkinsCount: json['totalSkinsCount'] as int? ?? 0,
      tierBreakdown: tierMap,
      ownedSkins: skinsRaw
          .map((s) => OwnedSkinItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      equippedWeapons: equippedRaw
          .map((w) => EquippedWeaponSkin.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        totalVpSpent,
        totalEstimatedIdr,
        totalSkinsCount,
        tierBreakdown,
        ownedSkins,
        equippedWeapons,
      ];
}
