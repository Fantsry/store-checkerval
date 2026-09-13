import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';

enum LiveMatchPhase {
  preGame, // Agent Select
  coreGame, // Live in Match
  inLobby, // In Menu / Not currently in a match
}

class LiveMatchData extends Equatable {
  final LiveMatchPhase phase;
  final String matchId;
  final String mapName;
  final String? mapSplash;
  final String modeName;
  final List<LivePlayerInfo> blueTeam;
  final List<LivePlayerInfo> redTeam;

  const LiveMatchData({
    required this.phase,
    this.matchId = '',
    this.mapName = 'Unknown Map',
    this.mapSplash,
    this.modeName = 'Competitive',
    this.blueTeam = const [],
    this.redTeam = const [],
  });

  bool get isInMatch => phase != LiveMatchPhase.inLobby;

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'matchId': matchId,
        'mapName': mapName,
        'mapSplash': mapSplash,
        'modeName': modeName,
        'blueTeam': blueTeam.map((p) => p.toJson()).toList(),
        'redTeam': redTeam.map((p) => p.toJson()).toList(),
      };

  factory LiveMatchData.fromJson(Map<String, dynamic> json) {
    final blueRaw =
        json['blueTeam'] is List ? (json['blueTeam'] as List) : const [];
    final redRaw =
        json['redTeam'] is List ? (json['redTeam'] as List) : const [];

    return LiveMatchData(
      phase: LiveMatchPhase.values.firstWhere(
        (p) => p.name == (json['phase'] as String? ?? 'inLobby'),
        orElse: () => LiveMatchPhase.inLobby,
      ),
      matchId: json['matchId'] as String? ?? '',
      mapName: json['mapName'] as String? ?? 'Unknown Map',
      mapSplash: json['mapSplash'] as String?,
      modeName: json['modeName'] as String? ?? 'Competitive',
      blueTeam: blueRaw
          .whereType<Map>()
          .map((p) => LivePlayerInfo.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      redTeam: redRaw
          .whereType<Map>()
          .map((p) => LivePlayerInfo.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        matchId,
        mapName,
        mapSplash,
        modeName,
        blueTeam,
        redTeam,
      ];
}
