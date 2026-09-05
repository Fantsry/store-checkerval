import 'package:equatable/equatable.dart';

/// Represents an authenticated Riot session.
class AuthSession extends Equatable {
  final String accessToken;
  final String idToken;
  final String entitlementsToken;
  final String puuid;
  final String shard;
  final String region;
  final String cookieJar;
  final String? gameName;
  final String? tagLine;

  const AuthSession({
    required this.accessToken,
    required this.idToken,
    required this.entitlementsToken,
    required this.puuid,
    required this.shard,
    required this.region,
    required this.cookieJar,
    this.gameName,
    this.tagLine,
  });

  String get displayName {
    if (gameName != null && tagLine != null) {
      return '$gameName#$tagLine';
    }
    return gameName ?? puuid.substring(0, 8);
  }

  AuthSession copyWith({
    String? accessToken,
    String? idToken,
    String? entitlementsToken,
    String? puuid,
    String? shard,
    String? region,
    String? cookieJar,
    String? gameName,
    String? tagLine,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
      entitlementsToken: entitlementsToken ?? this.entitlementsToken,
      puuid: puuid ?? this.puuid,
      shard: shard ?? this.shard,
      region: region ?? this.region,
      cookieJar: cookieJar ?? this.cookieJar,
      gameName: gameName ?? this.gameName,
      tagLine: tagLine ?? this.tagLine,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'idToken': idToken,
      'entitlementsToken': entitlementsToken,
      'puuid': puuid,
      'shard': shard,
      'region': region,
      'cookieJar': cookieJar,
      'gameName': gameName,
      'tagLine': tagLine,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      idToken: json['idToken'] as String? ?? '',
      entitlementsToken: json['entitlementsToken'] as String? ?? '',
      puuid: json['puuid'] as String? ?? '',
      shard: json['shard'] as String? ?? 'ap',
      region: json['region'] as String? ?? 'ap',
      cookieJar: json['cookieJar'] as String? ?? '',
      gameName: json['gameName'] as String?,
      tagLine: json['tagLine'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        accessToken,
        idToken,
        entitlementsToken,
        puuid,
        shard,
        region,
        cookieJar,
        gameName,
        tagLine,
      ];
}
