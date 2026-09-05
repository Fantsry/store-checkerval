import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

class WishlistItem extends Equatable {
  final String uuid;
  final String displayName;
  final String? displayIcon;
  final String? weaponName;
  final int cost;
  final String? tierName;
  final String? tierColor;
  final String? tierIcon;
  final DateTime addedAt;

  const WishlistItem({
    required this.uuid,
    required this.displayName,
    this.displayIcon,
    this.weaponName,
    required this.cost,
    this.tierName,
    this.tierColor,
    this.tierIcon,
    required this.addedAt,
  });

  factory WishlistItem.fromSkinItem(SkinItem skin) {
    return WishlistItem(
      uuid: skin.uuid,
      displayName: skin.displayName,
      displayIcon: skin.displayIcon,
      weaponName: skin.weaponName,
      cost: skin.cost,
      tierName: skin.tierName,
      tierColor: skin.tierColor,
      tierIcon: skin.tierIcon,
      addedAt: DateTime.now(),
    );
  }

  SkinItem toSkinItem() {
    return SkinItem(
      uuid: uuid,
      displayName: displayName,
      displayIcon: displayIcon,
      weaponName: weaponName,
      cost: cost,
      tierName: tierName,
      tierColor: tierColor,
      tierIcon: tierIcon,
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'displayIcon': displayIcon,
        'weaponName': weaponName,
        'cost': cost,
        'tierName': tierName,
        'tierColor': tierColor,
        'tierIcon': tierIcon,
        'addedAt': addedAt.toIso8601String(),
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        uuid: json['uuid'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        displayIcon: json['displayIcon'] as String?,
        weaponName: json['weaponName'] as String?,
        cost: json['cost'] as int? ?? 1775,
        tierName: json['tierName'] as String?,
        tierColor: json['tierColor'] as String?,
        tierIcon: json['tierIcon'] as String?,
        addedAt: json['addedAt'] != null
            ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [
        uuid,
        displayName,
        displayIcon,
        weaponName,
        cost,
        tierName,
        tierColor,
        tierIcon,
        addedAt,
      ];
}
