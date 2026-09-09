import 'dart:convert';
import 'package:dio/dio.dart';
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
        } else {
          return Result.failure(
            ServerFailure(
              message: 'Active match ($matchId) detected, but match details could not be retrieved from Riot servers.',
            ),
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
        } else {
          return Result.failure(
            ServerFailure(
              message: 'Agent select lobby ($matchId) detected, but lobby details could not be retrieved from Riot servers.',
            ),
          );
        }
      }

      // Step 3: Not in match
      return const Result.success(
        LiveMatchData(phase: LiveMatchPhase.inLobby),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 ||
          (e.response?.statusCode == 400 &&
              (e.response?.data?.toString().contains('BAD_CLAIMS') ?? false))) {
        return const Result.failure(
          AuthFailure(message: 'Riot session expired or invalid. Please sign in again.'),
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Result.failure(
          NetworkFailure(message: 'Connection timed out while connecting to Valorant GLZ servers.'),
        );
      }
      return Result.failure(
        ServerFailure(
          message: 'Failed to contact Valorant servers (${e.response?.statusCode ?? 'Network'}): ${e.message}',
        ),
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

    final rawPlayers = matchData['Players'] as List<dynamic>? ?? [];
    final List<String> puuids = [];
    for (final p in rawPlayers) {
      if (p is Map && p['Subject'] != null) {
        puuids.add(p['Subject'].toString());
      }
    }

    // Parallelize metadata, names, and player MMR lookups
    final results = await Future.wait([
      _careerDataSource.fetchMapsMetadata(),
      _careerDataSource.fetchAgentsMetadata(),
      _careerDataSource.fetchCompetitiveTiersMetadata(),
      _remoteDataSource.fetchPlayerNames(shard: shard, puuids: puuids),
      Future.wait(
        puuids.map((sub) async {
          try {
            final mmrData = await _remoteDataSource.fetchPlayerMmr(
              shard: shard,
              puuid: sub,
            );
            return MapEntry(sub, mmrData);
          } catch (_) {
            return MapEntry(sub, null);
          }
        }),
      ),
    ]);

    final mapsMeta = results[0] as Map<String, Map<String, dynamic>>;
    final agentsMeta = results[1] as Map<String, Map<String, dynamic>>;
    final tiersMeta = results[2] as Map<int, Map<String, dynamic>>;
    final namesList = results[3] as List<Map<String, dynamic>>;
    final mmrEntries =
        results[4] as List<MapEntry<String, Map<String, dynamic>?>>;
    final mmrMap = Map.fromEntries(mmrEntries);

    final mapInfo = mapsMeta[mapUrl.toLowerCase()];
    final mapName = mapInfo?['displayName'] ?? mapUrl.split('/').last;
    final mapSplash = mapInfo?['splash'];
    final modeName = _cleanModeName(modeUrl);

    final Map<String, Map<String, String>> namesMap = {};
    for (final n in namesList) {
      final sub = (n['Subject'] ?? '').toString();
      namesMap[sub] = {
        'gameName': (n['GameName'] ?? 'Player').toString(),
        'tagLine': (n['TagLine'] ?? '').toString(),
      };
    }

    // Find the user's team ID so allies and enemies are assigned correctly
    String myTeamId = 'Blue';
    for (final p in rawPlayers) {
      if (p is Map && (p['Subject'] ?? '').toString() == selfPuuid) {
        myTeamId = (p['TeamID'] ?? 'Blue').toString();
        break;
      }
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

        final mmrData = mmrMap[sub];
        if (mmrData != null) {
          final parsed = _extractRankFromMmr(mmrData, tiersMeta);
          rankName = parsed['rankName'] ?? 'Unranked';
          rankIcon = parsed['rankIcon'];
          currentRr = parsed['currentRr'] as int? ?? 0;
          peakRank = parsed['peakRank'] ?? 'Unranked';
        }

        final isSelf = sub == selfPuuid;
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
          isSelf: isSelf,
          isLocked: true,
        );

        // Put user's team into blueTeam (Allies) and opponent team into redTeam (Enemies)
        if (teamId.toLowerCase() == myTeamId.toLowerCase()) {
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

    final allyTeamRaw = matchData['AllyTeam'] as Map<String, dynamic>?;
    final rawPlayers = allyTeamRaw?['Players'] as List<dynamic>? ?? [];

    final List<String> puuids = [];
    for (final p in rawPlayers) {
      if (p is Map && p['Subject'] != null) {
        puuids.add(p['Subject'].toString());
      }
    }

    // Parallelize metadata, names, and player MMR lookups
    final results = await Future.wait([
      _careerDataSource.fetchMapsMetadata(),
      _careerDataSource.fetchAgentsMetadata(),
      _careerDataSource.fetchCompetitiveTiersMetadata(),
      _remoteDataSource.fetchPlayerNames(shard: shard, puuids: puuids),
      Future.wait(
        puuids.map((sub) async {
          try {
            final mmrData = await _remoteDataSource.fetchPlayerMmr(
              shard: shard,
              puuid: sub,
            );
            return MapEntry(sub, mmrData);
          } catch (_) {
            return MapEntry(sub, null);
          }
        }),
      ),
    ]);

    final mapsMeta = results[0] as Map<String, Map<String, dynamic>>;
    final agentsMeta = results[1] as Map<String, Map<String, dynamic>>;
    final tiersMeta = results[2] as Map<int, Map<String, dynamic>>;
    final namesList = results[3] as List<Map<String, dynamic>>;
    final mmrEntries =
        results[4] as List<MapEntry<String, Map<String, dynamic>?>>;
    final mmrMap = Map.fromEntries(mmrEntries);

    final mapInfo = mapsMeta[mapUrl.toLowerCase()];
    final mapName = mapInfo?['displayName'] ?? mapUrl.split('/').last;
    final mapSplash = mapInfo?['splash'];
    final modeName = _cleanModeName(modeUrl);

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

        final mmrData = mmrMap[sub];
        if (mmrData != null) {
          final parsed = _extractRankFromMmr(mmrData, tiersMeta);
          rankName = parsed['rankName'] ?? 'Unranked';
          rankIcon = parsed['rankIcon'];
          currentRr = parsed['currentRr'] as int? ?? 0;
          peakRank = parsed['peakRank'] ?? 'Unranked';
        }

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
      var currentTier = compSkill?['Tier'] as int? ?? 0;
      final currentRr = compSkill?['RankedRating'] as int? ?? 0;

      // Fallback if currentTier is 0: check recent seasonal tier
      final seasonal =
          compSkill?['SeasonalInfoBySeasonID'] as Map<String, dynamic>?;
      if (currentTier == 0 && seasonal != null && seasonal.isNotEmpty) {
        for (final entry in seasonal.values) {
          if (entry is Map) {
            final t = entry['CompetitiveTier'] as int? ?? 0;
            if (t > 0) {
              currentTier = t;
              break;
            }
          }
        }
      }

      final tierInfo = tiersMeta[currentTier];
      final rankName = tierInfo?['tierName'] ?? 'Unranked';
      final rankIcon = tierInfo?['largeIcon'];

      // Peak Rank
      int peakTier = currentTier;
      if (seasonal != null) {
        for (final entry in seasonal.values) {
          if (entry is Map) {
            final t = entry['CompetitiveTier'] as int? ?? 0;
            if (t > peakTier) peakTier = t;
            final badgeRank =
                entry['SeasonalBadgeInfo']?['Rank'] as int? ?? 0;
            if (badgeRank > peakTier) peakTier = badgeRank;
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
