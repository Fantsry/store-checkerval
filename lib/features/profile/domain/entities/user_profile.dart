import 'package:equatable/equatable.dart';

/// Represents a Valorant player's profile and equipped customization.
class UserProfile extends Equatable {
  final String puuid;
  final String gameName;
  final String tagLine;
  final int accountLevel;
  final int accountXp;
  final String? cardUuid;
  final String? cardName;
  final String? cardSmallArt;
  final String? cardWideArt;
  final String? cardLargeArt;
  final String? titleUuid;
  final String? titleText;
  final String region;
  final String shard;
  final int valorantPoints;
  final int radianitePoints;
  final int kingdomCredits;

  const UserProfile({
    required this.puuid,
    required this.gameName,
    required this.tagLine,
    this.accountLevel = 1,
    this.accountXp = 0,
    this.cardUuid,
    this.cardName,
    this.cardSmallArt,
    this.cardWideArt,
    this.cardLargeArt,
    this.titleUuid,
    this.titleText,
    required this.region,
    required this.shard,
    this.valorantPoints = 0,
    this.radianitePoints = 0,
    this.kingdomCredits = 0,
  });

  /// Formatted Riot ID (e.g. "Irfan#1234").
  String get displayName {
    if (gameName.isNotEmpty && tagLine.isNotEmpty) {
      return '$gameName#$tagLine';
    }
    if (gameName.isNotEmpty) return gameName;
    return puuid.length > 8 ? puuid.substring(0, 8) : puuid;
  }

  UserProfile copyWith({
    String? puuid,
    String? gameName,
    String? tagLine,
    int? accountLevel,
    int? accountXp,
    String? cardUuid,
    String? cardName,
    String? cardSmallArt,
    String? cardWideArt,
    String? cardLargeArt,
    String? titleUuid,
    String? titleText,
    String? region,
    String? shard,
    int? valorantPoints,
    int? radianitePoints,
    int? kingdomCredits,
  }) {
    return UserProfile(
      puuid: puuid ?? this.puuid,
      gameName: gameName ?? this.gameName,
      tagLine: tagLine ?? this.tagLine,
      accountLevel: accountLevel ?? this.accountLevel,
      accountXp: accountXp ?? this.accountXp,
      cardUuid: cardUuid ?? this.cardUuid,
      cardName: cardName ?? this.cardName,
      cardSmallArt: cardSmallArt ?? this.cardSmallArt,
      cardWideArt: cardWideArt ?? this.cardWideArt,
      cardLargeArt: cardLargeArt ?? this.cardLargeArt,
      titleUuid: titleUuid ?? this.titleUuid,
      titleText: titleText ?? this.titleText,
      region: region ?? this.region,
      shard: shard ?? this.shard,
      valorantPoints: valorantPoints ?? this.valorantPoints,
      radianitePoints: radianitePoints ?? this.radianitePoints,
      kingdomCredits: kingdomCredits ?? this.kingdomCredits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puuid': puuid,
      'gameName': gameName,
      'tagLine': tagLine,
      'accountLevel': accountLevel,
      'accountXp': accountXp,
      'cardUuid': cardUuid,
      'cardName': cardName,
      'cardSmallArt': cardSmallArt,
      'cardWideArt': cardWideArt,
      'cardLargeArt': cardLargeArt,
      'titleUuid': titleUuid,
      'titleText': titleText,
      'region': region,
      'shard': shard,
      'valorantPoints': valorantPoints,
      'radianitePoints': radianitePoints,
      'kingdomCredits': kingdomCredits,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      puuid: json['puuid'] as String? ?? '',
      gameName: json['gameName'] as String? ?? '',
      tagLine: json['tagLine'] as String? ?? '',
      accountLevel: json['accountLevel'] as int? ?? 1,
      accountXp: json['accountXp'] as int? ?? 0,
      cardUuid: json['cardUuid'] as String?,
      cardName: json['cardName'] as String?,
      cardSmallArt: json['cardSmallArt'] as String?,
      cardWideArt: json['cardWideArt'] as String?,
      cardLargeArt: json['cardLargeArt'] as String?,
      titleUuid: json['titleUuid'] as String?,
      titleText: json['titleText'] as String?,
      region: json['region'] as String? ?? 'ap',
      shard: json['shard'] as String? ?? 'ap',
      valorantPoints: json['valorantPoints'] as int? ?? 0,
      radianitePoints: json['radianitePoints'] as int? ?? 0,
      kingdomCredits: json['kingdomCredits'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        puuid,
        gameName,
        tagLine,
        accountLevel,
        accountXp,
        cardUuid,
        cardName,
        cardSmallArt,
        cardWideArt,
        cardLargeArt,
        titleUuid,
        titleText,
        region,
        shard,
        valorantPoints,
        radianitePoints,
        kingdomCredits,
      ];
}
