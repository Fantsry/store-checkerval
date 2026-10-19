import 'package:equatable/equatable.dart';

/// Current live activity status of a Valorant friend.
enum FriendLiveStatus {
  inGame, // Actively in a match (CoreGame)
  inAgentSelect, // In Agent Select lobby (PreGame)
  inLobby, // In Menu / Party / Online in client
  away, // Away / Mobile / Idle
  offline, // Offline / Not in client
}

/// Rich telemetry data when friend is actively in a match or pregame.
class FriendLiveActivity extends Equatable {
  final String? matchId;
  final String? mapName;
  final String? mapSplash;
  final String? modeName;
  final String? agentName;
  final String? agentIcon;
  final int? scoreAlly;
  final int? scoreEnemy;
  final DateTime? gameStartTime;
  final int? partySize;
  final int? maxPartySize;
  final String? partyState; // "OPEN", "CLOSED"
  final List<bool> roundHistory; // true = ally won, false = enemy won
  final String? lastRoundOutcome; // "ALLY_WON", "ENEMY_WON", "IN_PROGRESS"
  final DateTime? lastRoundUpdateTime;

  const FriendLiveActivity({
    this.matchId,
    this.mapName,
    this.mapSplash,
    this.modeName,
    this.agentName,
    this.agentIcon,
    this.scoreAlly,
    this.scoreEnemy,
    this.gameStartTime,
    this.partySize,
    this.maxPartySize,
    this.partyState,
    this.roundHistory = const [],
    this.lastRoundOutcome,
    this.lastRoundUpdateTime,
  });

  String get scoreDisplay {
    if (scoreAlly != null && scoreEnemy != null) {
      return '$scoreAlly - $scoreEnemy';
    }
    return '';
  }

  int get currentRound => (scoreAlly ?? 0) + (scoreEnemy ?? 0) + 1;

  int get targetScore {
    final mode = (modeName ?? '').toLowerCase();
    if (mode.contains('swiftplay')) return 5;
    if (mode.contains('spikerush') || mode.contains('spike rush')) return 4;
    return 13;
  }

  bool get isMatchPoint =>
      (scoreAlly != null && scoreAlly == targetScore - 1) ||
      (scoreEnemy != null && scoreEnemy == targetScore - 1);

  bool get isOvertime =>
      (scoreAlly ?? 0) >= targetScore - 1 && (scoreEnemy ?? 0) >= targetScore - 1;

  String get durationDisplay {
    if (gameStartTime == null) return '';
    final elapsed = DateTime.now().difference(gameStartTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  FriendLiveActivity copyWith({
    String? matchId,
    String? mapName,
    String? mapSplash,
    String? modeName,
    String? agentName,
    String? agentIcon,
    int? scoreAlly,
    int? scoreEnemy,
    DateTime? gameStartTime,
    int? partySize,
    int? maxPartySize,
    String? partyState,
    List<bool>? roundHistory,
    String? lastRoundOutcome,
    DateTime? lastRoundUpdateTime,
  }) {
    return FriendLiveActivity(
      matchId: matchId ?? this.matchId,
      mapName: mapName ?? this.mapName,
      mapSplash: mapSplash ?? this.mapSplash,
      modeName: modeName ?? this.modeName,
      agentName: agentName ?? this.agentName,
      agentIcon: agentIcon ?? this.agentIcon,
      scoreAlly: scoreAlly ?? this.scoreAlly,
      scoreEnemy: scoreEnemy ?? this.scoreEnemy,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      partySize: partySize ?? this.partySize,
      maxPartySize: maxPartySize ?? this.maxPartySize,
      partyState: partyState ?? this.partyState,
      roundHistory: roundHistory ?? this.roundHistory,
      lastRoundOutcome: lastRoundOutcome ?? this.lastRoundOutcome,
      lastRoundUpdateTime: lastRoundUpdateTime ?? this.lastRoundUpdateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'mapName': mapName,
        'mapSplash': mapSplash,
        'modeName': modeName,
        'agentName': agentName,
        'agentIcon': agentIcon,
        'scoreAlly': scoreAlly,
        'scoreEnemy': scoreEnemy,
        'gameStartTime': gameStartTime?.toIso8601String(),
        'partySize': partySize,
        'maxPartySize': maxPartySize,
        'partyState': partyState,
        'roundHistory': roundHistory,
        'lastRoundOutcome': lastRoundOutcome,
        'lastRoundUpdateTime': lastRoundUpdateTime?.toIso8601String(),
      };

  factory FriendLiveActivity.fromJson(Map<String, dynamic> json) {
    return FriendLiveActivity(
      matchId: json['matchId'] as String?,
      mapName: json['mapName'] as String?,
      mapSplash: json['mapSplash'] as String?,
      modeName: json['modeName'] as String?,
      agentName: json['agentName'] as String?,
      agentIcon: json['agentIcon'] as String?,
      scoreAlly: json['scoreAlly'] as int?,
      scoreEnemy: json['scoreEnemy'] as int?,
      gameStartTime: json['gameStartTime'] != null
          ? DateTime.tryParse(json['gameStartTime'] as String)
          : null,
      partySize: json['partySize'] as int?,
      maxPartySize: json['maxPartySize'] as int?,
      partyState: json['partyState'] as String?,
      roundHistory: (json['roundHistory'] as List?)?.whereType<bool>().toList() ?? const [],
      lastRoundOutcome: json['lastRoundOutcome'] as String?,
      lastRoundUpdateTime: json['lastRoundUpdateTime'] != null
          ? DateTime.tryParse(json['lastRoundUpdateTime'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        matchId,
        mapName,
        mapSplash,
        modeName,
        agentName,
        agentIcon,
        scoreAlly,
        scoreEnemy,
        gameStartTime,
        partySize,
        maxPartySize,
        partyState,
        roundHistory,
        lastRoundOutcome,
        lastRoundUpdateTime,
      ];
}

/// A tracked friend/squadmate with player card banner, rank, and live presence.
class FriendEntity extends Equatable {
  final String puuid;
  final String gameName;
  final String tagLine;
  final int accountLevel;
  final String? cardUuid;
  final String? cardName;
  final String? cardWideArt;
  final String? cardSmallArt;
  final String? cardLargeArt;
  final int? rankTier;
  final String? rankName;
  final String? rankIcon;
  final int rankedRating;
  final bool isFavorite;
  final FriendLiveStatus status;
  final FriendLiveActivity? liveActivity;
  final String? clientActivity; // e.g. "In Riot Client", "Away", "Competitive · Bind · 2-0"
  final bool isMobile; // Displays phone icon if mobile / away
  final String? lastChatMessage; // e.g. "aman aja"
  final DateTime? lastChatTimestamp; // e.g. Oct 14, 2026
  final DateTime lastUpdated;

  const FriendEntity({
    required this.puuid,
    required this.gameName,
    this.tagLine = '',
    this.accountLevel = 1,
    this.cardUuid,
    this.cardName,
    this.cardWideArt,
    this.cardSmallArt,
    this.cardLargeArt,
    this.rankTier,
    this.rankName,
    this.rankIcon,
    this.rankedRating = 0,
    this.isFavorite = false,
    this.status = FriendLiveStatus.offline,
    this.liveActivity,
    this.clientActivity,
    this.isMobile = false,
    this.lastChatMessage,
    this.lastChatTimestamp,
    required this.lastUpdated,
  });

  String get displayName =>
      tagLine.isNotEmpty ? '$gameName #$tagLine' : gameName;

  bool get isPlaying =>
      status == FriendLiveStatus.inGame ||
      status == FriendLiveStatus.inAgentSelect;

  bool get isOnline =>
      status == FriendLiveStatus.inGame ||
      status == FriendLiveStatus.inAgentSelect ||
      status == FriendLiveStatus.inLobby ||
      status == FriendLiveStatus.away;

  FriendEntity copyWith({
    String? puuid,
    String? gameName,
    String? tagLine,
    int? accountLevel,
    String? cardUuid,
    String? cardName,
    String? cardWideArt,
    String? cardSmallArt,
    String? cardLargeArt,
    int? rankTier,
    String? rankName,
    String? rankIcon,
    int? rankedRating,
    bool? isFavorite,
    FriendLiveStatus? status,
    FriendLiveActivity? liveActivity,
    String? clientActivity,
    bool? isMobile,
    String? lastChatMessage,
    DateTime? lastChatTimestamp,
    DateTime? lastUpdated,
  }) {
    return FriendEntity(
      puuid: puuid ?? this.puuid,
      gameName: gameName ?? this.gameName,
      tagLine: tagLine ?? this.tagLine,
      accountLevel: accountLevel ?? this.accountLevel,
      cardUuid: cardUuid ?? this.cardUuid,
      cardName: cardName ?? this.cardName,
      cardWideArt: cardWideArt ?? this.cardWideArt,
      cardSmallArt: cardSmallArt ?? this.cardSmallArt,
      cardLargeArt: cardLargeArt ?? this.cardLargeArt,
      rankTier: rankTier ?? this.rankTier,
      rankName: rankName ?? this.rankName,
      rankIcon: rankIcon ?? this.rankIcon,
      rankedRating: rankedRating ?? this.rankedRating,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
      liveActivity: liveActivity ?? this.liveActivity,
      clientActivity: clientActivity ?? this.clientActivity,
      isMobile: isMobile ?? this.isMobile,
      lastChatMessage: lastChatMessage ?? this.lastChatMessage,
      lastChatTimestamp: lastChatTimestamp ?? this.lastChatTimestamp,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'puuid': puuid,
        'gameName': gameName,
        'tagLine': tagLine,
        'accountLevel': accountLevel,
        'cardUuid': cardUuid,
        'cardName': cardName,
        'cardWideArt': cardWideArt,
        'cardSmallArt': cardSmallArt,
        'cardLargeArt': cardLargeArt,
        'rankTier': rankTier,
        'rankName': rankName,
        'rankIcon': rankIcon,
        'rankedRating': rankedRating,
        'isFavorite': isFavorite,
        'status': status.name,
        'liveActivity': liveActivity?.toJson(),
        'clientActivity': clientActivity,
        'isMobile': isMobile,
        'lastChatMessage': lastChatMessage,
        'lastChatTimestamp': lastChatTimestamp?.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory FriendEntity.fromJson(Map<String, dynamic> json) {
    return FriendEntity(
      puuid: json['puuid'] as String? ?? '',
      gameName: json['gameName'] as String? ?? 'Agent',
      tagLine: json['tagLine'] as String? ?? '',
      accountLevel: json['accountLevel'] as int? ?? 1,
      cardUuid: json['cardUuid'] as String?,
      cardName: json['cardName'] as String?,
      cardWideArt: json['cardWideArt'] as String?,
      cardSmallArt: json['cardSmallArt'] as String?,
      cardLargeArt: json['cardLargeArt'] as String?,
      rankTier: json['rankTier'] as int?,
      rankName: json['rankName'] as String?,
      rankIcon: json['rankIcon'] as String?,
      rankedRating: json['rankedRating'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      status: FriendLiveStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'offline'),
        orElse: () => FriendLiveStatus.offline,
      ),
      liveActivity: json['liveActivity'] != null
          ? FriendLiveActivity.fromJson(
              Map<String, dynamic>.from(json['liveActivity'] as Map))
          : null,
      clientActivity: json['clientActivity'] as String?,
      isMobile: json['isMobile'] as bool? ?? false,
      lastChatMessage: json['lastChatMessage'] as String?,
      lastChatTimestamp: json['lastChatTimestamp'] != null
          ? DateTime.tryParse(json['lastChatTimestamp'] as String)
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        puuid,
        gameName,
        tagLine,
        accountLevel,
        cardUuid,
        cardName,
        cardWideArt,
        cardSmallArt,
        cardLargeArt,
        rankTier,
        rankName,
        rankIcon,
        rankedRating,
        isFavorite,
        status,
        liveActivity,
        clientActivity,
        isMobile,
        lastChatMessage,
        lastChatTimestamp,
        lastUpdated,
      ];
}
