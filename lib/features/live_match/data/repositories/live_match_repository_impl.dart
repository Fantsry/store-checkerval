import 'dart:convert';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/live_match/data/datasources/live_match_remote_datasource.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_player_info.dart';
import 'package:valorant_store_tracker/features/live_match/domain/repositories/live_match_repository.dart';

class LiveMatchRepositoryImpl implements LiveMatchRepository {
  final LiveMatchRemoteDataSource _remoteDataSource;
  final CareerRemoteDataSource _careerDataSource;
  final SecureStorageService _storage;

  LiveMatchRepositoryImpl({
    required LiveMatchRemoteDataSource remoteDataSource,
    required CareerRemoteDataSource careerDataSource,
    required SecureStorageService storage,
  })  : _remoteDataSource = remoteDataSource,
        _careerDataSource = careerDataSource,
        _storage = storage;

  String? _extractPuuidFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      return payload['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<LiveMatchData>> checkLiveMatch() async {
    try {
      var puuid = await _storage.getPuuid();
      if (puuid == null || puuid.isEmpty) {
        final token = await _storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          final extracted = _extractPuuidFromJwt(token);
          if (extracted != null && extracted.isNotEmpty) {
            puuid = extracted;
            await _storage.setPuuid(puuid);
          }
        }
      }

      final shard = await _storage.getShard() ?? 'ap';
      final region = await _storage.getRegion() ?? shard;

      if (puuid == null || puuid.isEmpty) {
        return const Result.failure(
          AuthFailure(message: 'No active Riot session. Please sign in.'),
        );
      }

      // Step 1: Check CoreGame (Live in-match)
      final corePlayer = await _remoteDataSource.fetchCoreGamePlayer(
        region: region,
        shard: shard,
        puuid: puuid,
      );

      if (corePlayer != null && corePlayer['MatchID'] != null) {
        final matchId = corePlayer['MatchID'].toString();
        final match = await _remoteDataSource.fetchCoreGameMatch(
          region: region,
          shard: shard,
          matchId: matchId,
        );

        if (match != null) {
          return await _parseCoreGameMatch(
            shard: shard,
            selfPuuid: puuid,
            matchId: matchId,
            matchData: match,
          );
        }
      }

      // Step 2: Check PreGame (Agent Select)
      final prePlayer = await _remoteDataSource.fetchPreGamePlayer(
        region: region,
        shard: shard,
        puuid: puuid,
      );

      if (prePlayer != null && prePlayer['MatchID'] != null) {
        final matchId = prePlayer['MatchID'].toString();
        final match = await _remoteDataSource.fetchPreGameMatch(
          region: region,
          shard: shard,
          matchId: matchId,
        );

        if (match != null) {
          return await _parsePreGameMatch(
            shard: shard,
            selfPuuid: puuid,
            matchId: matchId,
            matchData: match,
          );
        }
      }

      // Step 3: Not in match
      return const Result.success(
        LiveMatchData(phase: LiveMatchPhase.inLobby),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to inspect live match lobby: $e'),
      );
    }
  }

  Future<Result<LiveMatchData>> _parseCoreGameMatch({
    required String shard,
    required String selfPuuid,
    required String matchId,
    required Map<String, dynamic> matchData,
  }) async {
    final mapUrl = (matchData['MapID'] ?? '').toString();
    final modeUrl = (matchData['ModeID'] ?? '').toString();

    // Fetch metadata
    final mapsMeta = await _careerDataSource.fetchMapsMetadata();
    final agentsMeta = await _careerDataSource.fetchAgentsMetadata();
    final tiersMeta = await _careerDataSource.fetchCompetitiveTiersMetadata();

    final mapInfo = mapsMeta[mapUrl.toLowerCase()];
    final mapName = mapInfo?['displayName'] ?? mapUrl.split('/').last;
    final mapSplash = mapInfo?['splash'];
    final modeName = _cleanModeName(modeUrl);

    final rawPlayers = matchData['Players'] as List<dynamic>? ?? [];
    final List<String> puuids = [];
    for (final p in rawPlayers) {
      if (p is Map && p['Subject'] != null) {
        puuids.add(p['Subject'].toString());
      }
    }

    // Fetch player names & MMR
    final namesList = await _remoteDataSource.fetchPlayerNames(
      shard: shard,
      puuids: puuids,
    );
    final Map<String, Map<String, String>> namesMap = {};
    for (final n in namesList) {
      final sub = (n['Subject'] ?? '').toString();
      namesMap[sub] = {
        'gameName': (n['GameName'] ?? 'Player').toString(),
        'tagLine': (n['TagLine'] ?? '').toString(),
      };
    }

    final List<LivePlayerInfo> blueTeam = [];
    final List<LivePlayerInfo> redTeam = [];

    for (final p in rawPlayers) {
      if (p is Map) {
        final sub = (p['Subject'] ?? '').toString();
        final teamId = (p['TeamID'] ?? 'Blue').toString();
        final charId = (p['CharacterID'] ?? '').toString().toLowerCase();

        final nameInfo = namesMap[sub];
        final gameName = nameInfo?['gameName'] ?? 'Agent';
        final tagLine = nameInfo?['tagLine'] ?? '';

        final agentInfo = agentsMeta[charId];
        final agentName = agentInfo?['displayName'];
        final agentIcon = agentInfo?['displayIcon'];

        // Player MMR
        var rankName = 'Unranked';
        String? rankIcon;
        int currentRr = 0;
        var peakRank = 'Unranked';

        try {
          final mmrData = await _remoteDataSource.fetchPlayerMmr(
            shard: shard,
            puuid: sub,
          );
          if (mmrData != null) {
            final parsed = _extractRankFromMmr(mmrData, tiersMeta);
            rankName = parsed['rankName'] ?? 'Unranked';
            rankIcon = parsed['rankIcon'];
            currentRr = parsed['currentRr'] as int? ?? 0;
            peakRank = parsed['peakRank'] ?? 'Unranked';
          }
        } catch (_) {}

        final player = LivePlayerInfo(
          puuid: sub,
          gameName: gameName,
          tagLine: tagLine,
          teamId: teamId,
          agentName: agentName,
          agentIcon: agentIcon,
          currentRankTierName: rankName,
          rankIcon: rankIcon,
          currentRr: currentRr,
          peakRankTierName: peakRank,
          isSelf: sub == selfPuuid,
          isLocked: true,
        );

        if (teamId.toLowerCase() == 'blue') {
          blueTeam.add(player);
        } else {
          redTeam.add(player);
        }
      }
    }

    return Result.success(
      LiveMatchData(
        phase: LiveMatchPhase.coreGame,
        matchId: matchId,
        mapName: mapName,
        mapSplash: mapSplash,
        modeName: modeName,
        blueTeam: blueTeam,
        redTeam: redTeam,
      ),
    );
  }

  Future<Result<LiveMatchData>> _parsePreGameMatch({
    required String shard,
    required String selfPuuid,
    required String matchId,
    required Map<String, dynamic> matchData,
  }) async {
    final mapUrl = (matchData['MapID'] ?? '').toString();
    final modeUrl = (matchData['Mode'] ?? '').toString();

    final mapsMeta = await _careerDataSource.fetchMapsMetadata();
    final agentsMeta = await _careerDataSource.fetchAgentsMetadata();
    final tiersMeta = await _careerDataSource.fetchCompetitiveTiersMetadata();

    final mapInfo = mapsMeta[mapUrl.toLowerCase()];
    final mapName = mapInfo?['displayName'] ?? mapUrl.split('/').last;
    final mapSplash = mapInfo?['splash'];
    final modeName = _cleanModeName(modeUrl);

    final allyTeamRaw = matchData['AllyTeam'] as Map<String, dynamic>?;
    final rawPlayers = allyTeamRaw?['Players'] as List<dynamic>? ?? [];

    final List<String> puuids = [];
    for (final p in rawPlayers) {
      if (p is Map && p['Subject'] != null) {
        puuids.add(p['Subject'].toString());
      }
    }

    final namesList = await _remoteDataSource.fetchPlayerNames(
      shard: shard,
      puuids: puuids,
    );
    final Map<String, Map<String, String>> namesMap = {};
    for (final n in namesList) {
      final sub = (n['Subject'] ?? '').toString();
      namesMap[sub] = {
        'gameName': (n['GameName'] ?? 'Player').toString(),
        'tagLine': (n['TagLine'] ?? '').toString(),
      };
    }

    final List<LivePlayerInfo> allyTeam = [];

    for (final p in rawPlayers) {
      if (p is Map) {
        final sub = (p['Subject'] ?? '').toString();
        final charId = (p['CharacterID'] ?? '').toString().toLowerCase();
        final charState =
            (p['CharacterSelectionState'] ?? '').toString().toLowerCase();

        final nameInfo = namesMap[sub];
        final gameName = nameInfo?['gameName'] ?? 'Teammate';
        final tagLine = nameInfo?['tagLine'] ?? '';

        final agentInfo = agentsMeta[charId];
        final agentName = agentInfo?['displayName'];
        final agentIcon = agentInfo?['displayIcon'];

        var rankName = 'Unranked';
        String? rankIcon;
        int currentRr = 0;
        var peakRank = 'Unranked';

        try {
          final mmrData = await _remoteDataSource.fetchPlayerMmr(
            shard: shard,
            puuid: sub,
          );
          if (mmrData != null) {
            final parsed = _extractRankFromMmr(mmrData, tiersMeta);
            rankName = parsed['rankName'] ?? 'Unranked';
            rankIcon = parsed['rankIcon'];
            currentRr = parsed['currentRr'] as int? ?? 0;
            peakRank = parsed['peakRank'] ?? 'Unranked';
          }
        } catch (_) {}

        allyTeam.add(
          LivePlayerInfo(
            puuid: sub,
            gameName: gameName,
            tagLine: tagLine,
            teamId: 'Ally',
            agentName: agentName,
            agentIcon: agentIcon,
            currentRankTierName: rankName,
            rankIcon: rankIcon,
            currentRr: currentRr,
            peakRankTierName: peakRank,
            isSelf: sub == selfPuuid,
            isLocked: charState == 'locked',
          ),
        );
      }
    }

    return Result.success(
      LiveMatchData(
        phase: LiveMatchPhase.preGame,
        matchId: matchId,
        mapName: mapName,
        mapSplash: mapSplash,
        modeName: modeName,
        blueTeam: allyTeam,
        redTeam: const [],
      ),
    );
  }

  Map<String, dynamic> _extractRankFromMmr(
    Map<String, dynamic> mmrData,
    Map<int, Map<String, dynamic>> tiersMeta,
  ) {
    try {
      final queueSkills = mmrData['QueueSkills'] as Map<String, dynamic>?;
      final compSkill = queueSkills?['competitive'] as Map<String, dynamic>?;
      final currentTier = compSkill?['Tier'] as int? ?? 0;
      final currentRr = compSkill?['RankedRating'] as int? ?? 0;

      final tierInfo = tiersMeta[currentTier];
      final rankName = tierInfo?['tierName'] ?? 'Unranked';
      final rankIcon = tierInfo?['largeIcon'];

      // Peak Rank
      int peakTier = currentTier;
      final seasonal =
          compSkill?['SeasonalInfoBySeasonID'] as Map<String, dynamic>?;
      if (seasonal != null) {
        for (final entry in seasonal.values) {
          if (entry is Map) {
            final t = entry['CompetitiveTier'] as int? ?? 0;
            if (t > peakTier) peakTier = t;
          }
        }
      }

      final peakInfo = tiersMeta[peakTier];
      final peakRankName = peakInfo?['tierName'] ?? rankName;

      return {
        'rankName': rankName,
        'rankIcon': rankIcon,
        'currentRr': currentRr,
        'peakRank': peakRankName,
      };
    } catch (_) {
      return {
        'rankName': 'Unranked',
        'currentRr': 0,
        'peakRank': 'Unranked',
      };
    }
  }

  String _cleanModeName(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('competitive')) return 'Competitive';
    if (lower.contains('unrated')) return 'Unrated';
    if (lower.contains('swiftplay')) return 'Swiftplay';
    if (lower.contains('spikerush')) return 'Spike Rush';
    if (lower.contains('deathmatch')) return 'Deathmatch';
    if (lower.contains('hurm') || lower.contains('tdm')) return 'Team Deathmatch';
    return 'Match';
  }
}
