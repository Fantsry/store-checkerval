import 'package:equatable/equatable.dart';

class SkinChroma extends Equatable {
  final String uuid;
  final String displayName;
  final String? displayIcon;
  final String? fullRender;
  final String? streamedVideo;

  const SkinChroma({
    required this.uuid,
    required this.displayName,
    this.displayIcon,
    this.fullRender,
    this.streamedVideo,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'displayIcon': displayIcon,
        'fullRender': fullRender,
        'streamedVideo': streamedVideo,
      };

  factory SkinChroma.fromJson(Map<String, dynamic> json) => SkinChroma(
        uuid: json['uuid'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        displayIcon: json['displayIcon'] as String?,
        fullRender: json['fullRender'] as String?,
        streamedVideo: json['streamedVideo'] as String?,
      );

  @override
  List<Object?> get props => [uuid, displayName, displayIcon, fullRender, streamedVideo];
}

class SkinLevel extends Equatable {
  final String uuid;
  final String displayName;
  final String? levelItem;
  final String? displayIcon;
  final String? streamedVideo;

  const SkinLevel({
    required this.uuid,
    required this.displayName,
    this.levelItem,
    this.displayIcon,
    this.streamedVideo,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'levelItem': levelItem,
        'displayIcon': displayIcon,
        'streamedVideo': streamedVideo,
      };

  factory SkinLevel.fromJson(Map<String, dynamic> json) => SkinLevel(
        uuid: json['uuid'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        levelItem: json['levelItem'] as String?,
        displayIcon: json['displayIcon'] as String?,
        streamedVideo: json['streamedVideo'] as String?,
      );

  @override
  List<Object?> get props => [uuid, displayName, levelItem, displayIcon, streamedVideo];
}

class SkinItem extends Equatable {
  final String uuid;
  final String displayName;
  final String? displayIcon;
  final String? weaponName;
  final int cost;
  final String? contentTierUuid;
  final String? tierName;
  final String? tierColor;
  final String? tierIcon;
  final String? streamedVideo;
  final List<SkinChroma> chromas;
  final List<SkinLevel> levels;

  const SkinItem({
    required this.uuid,
    required this.displayName,
    this.displayIcon,
    this.weaponName,
    this.cost = 1775,
    this.contentTierUuid,
    this.tierName,
    this.tierColor,
    this.tierIcon,
    this.streamedVideo,
    this.chromas = const [],
    this.levels = const [],
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'displayIcon': displayIcon,
        'weaponName': weaponName,
        'cost': cost,
        'contentTierUuid': contentTierUuid,
        'tierName': tierName,
        'tierColor': tierColor,
        'tierIcon': tierIcon,
        'streamedVideo': streamedVideo,
        'chromas': chromas.map((c) => c.toJson()).toList(),
        'levels': levels.map((l) => l.toJson()).toList(),
      };

  factory SkinItem.fromJson(Map<String, dynamic> json) {
    final chromasData = json['chromas'] as List<dynamic>? ?? [];
    final levelsData = json['levels'] as List<dynamic>? ?? [];

    return SkinItem(
      uuid: json['uuid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      displayIcon: json['displayIcon'] as String?,
      weaponName: json['weaponName'] as String?,
      cost: json['cost'] as int? ?? 1775,
      contentTierUuid: json['contentTierUuid'] as String?,
      tierName: json['tierName'] as String?,
      tierColor: json['tierColor'] as String?,
      tierIcon: json['tierIcon'] as String?,
      streamedVideo: json['streamedVideo'] as String?,
      chromas: chromasData
          .map((c) => SkinChroma.fromJson(c as Map<String, dynamic>))
          .toList(),
      levels: levelsData
          .map((l) => SkinLevel.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  SkinItem copyWith({
    String? uuid,
    String? displayName,
    String? displayIcon,
    String? weaponName,
    int? cost,
    String? contentTierUuid,
    String? tierName,
    String? tierColor,
    String? tierIcon,
    String? streamedVideo,
    List<SkinChroma>? chromas,
    List<SkinLevel>? levels,
  }) {
    return SkinItem(
      uuid: uuid ?? this.uuid,
      displayName: displayName ?? this.displayName,
      displayIcon: displayIcon ?? this.displayIcon,
      weaponName: weaponName ?? this.weaponName,
      cost: cost ?? this.cost,
      contentTierUuid: contentTierUuid ?? this.contentTierUuid,
      tierName: tierName ?? this.tierName,
      tierColor: tierColor ?? this.tierColor,
      tierIcon: tierIcon ?? this.tierIcon,
      streamedVideo: streamedVideo ?? this.streamedVideo,
      chromas: chromas ?? this.chromas,
      levels: levels ?? this.levels,
    );
  }

  @override
  List<Object?> get props => [
        uuid,
        displayName,
        displayIcon,
        weaponName,
        cost,
        contentTierUuid,
        tierName,
        tierColor,
        tierIcon,
        streamedVideo,
        chromas,
        levels,
      ];
}
