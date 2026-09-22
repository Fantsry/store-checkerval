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

  String? _extractMatchId(Map<String, dynamic>? data) {
    if (data == null) return null;
    final id = data['MatchID'] ??
        data['matchId'] ??
        data['MatchId'] ??
        data['matchID'];
    final str = id?.toString().trim();
    return (str != null && str.isNotEmpty) ? str : null;
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

      // ── Step 1: Check CoreGame (Live in-match) ──
      // Prioritize live in-game detection so stale agent select lobbies are ignored
      final corePlayer = await _remoteDataSource.fetchCoreGamePlayer(
        region: region,
        shard: shard,
        puuid: puuid,
      );
      final coreMatchId = _extractMatchId(corePlayer);

      // Priority 1: Player is actively in CoreGame (live match)
      if (coreMatchId != null) {
        final match = await _remoteDataSource.fetchCoreGameMatch(
          region: region,
          shard: shard,
          matchId: coreMatchId,
        );

        if (match != null) {
          return await _parseCoreGameMatch(
            shard: shard,
            selfPuuid: puuid,
            matchId: coreMatchId,
            matchData: match,
          );
        } else {
          return Result.failure(
            ServerFailure(
              message:
                  'Active match ($coreMatchId) detected, but match details could not be retrieved from Riot servers.',
            ),
          );
        }
      }

      // ── Step 2: Check PreGame (Agent Select or Transitioning) ──
      final prePlayer = await _remoteDataSource.fetchPreGamePlayer(
        region: region,
        shard: shard,
        puuid: puuid,
      );
      final preMatchId = _extractMatchId(prePlayer);

      // Priority 2: PreGame match (Agent Select) or Transitioning to CoreGame
      if (preMatchId != null) {
        final preMatch = await _remoteDataSource.fetchPreGameMatch(
          region: region,
          shard: shard,
          matchId: preMatchId,
        );

        if (preMatch != null) {
          return await _parsePreGameMatch(
            shard: shard,
            selfPuuid: puuid,
            matchId: preMatchId,
            matchData: preMatch,
          );
        }

        // ── PreGame match returned 404! ──────────────────────────────
        // This indicates Agent Select has concluded and the lobby is transitioning
        // into CoreGame (loading screen / spawning into match).

        // Step A: In certain modes/customs, MatchID remains the same for CoreGame
        final directCoreMatch = await _remoteDataSource.fetchCoreGameMatch(
          region: region,
          shard: shard,
          matchId: preMatchId,
        );
        if (directCoreMatch != null) {
          return await _parseCoreGameMatch(
            shard: shard,
            selfPuuid: puuid,
            matchId: preMatchId,
            matchData: directCoreMatch,
          );
        }

        // Step B: Dedicated game server can take 1–3s to register CoreGame on GLZ.
        // Perform quick retries of fetchCoreGamePlayer.
        for (var i = 0; i < 2; i++) {
          await Future.delayed(Duration(milliseconds: 1000 + (i * 500)));
          final retryCore = await _remoteDataSource.fetchCoreGamePlayer(
            region: region,
            shard: shard,
            puuid: puuid,
          );
          final retryMatchId = _extractMatchId(retryCore);
          if (retryMatchId != null) {
            final match = await _remoteDataSource.fetchCoreGameMatch(
              region: region,
              shard: shard,
              matchId: retryMatchId,
            );
            if (match != null) {
              return await _parseCoreGameMatch(
                shard: shard,
                selfPuuid: puuid,
                matchId: retryMatchId,
                matchData: match,
              );
            }
          }
        }

        // Step C: If still in loading screen, return transitioning phase instead of crashing
        return Result.success(
          LiveMatchData(
            phase: LiveMatchPhase.transitioning,
            matchId: preMatchId,
          ),
        );
      }

      // Priority 3: Neither CoreGame nor PreGame active -> In Lobby
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

    final rawPlayers = matchData['Players'] is List
        ? (matchData['Players'] as List)
        : const [];
    final List<String> puuids = [];
    for (final p in rawPlayers) {
      if (p is Map && p['Subject'] != null) {
        puuids.add(p['Subject'].toString());
      }
    }

    // Parallelize metadata, names, and player MMR + Competitive lookups
    // Fetch 15 competitive updates for extended stats
    final results = await Future.wait([
      _careerDataSource
          .fetchMapsMetadata()
          .catchError((_) => <String, Map<String, dynamic>>{}),
      _careerDataSource
          .fetchAgentsMetadata()
          .catchError((_) => <String, Map<String, dynamic>>{}),
      _careerDataSource
          .fetchCompetitiveTiersMetadata()
          .catchError((_) => <int, Map<String, dynamic>>{}),
      _remoteDataSource
          .fetchPlayerNames(shard: shard, puuids: puuids)
          .catchError((_) => <Map<String, dynamic>>[]),
      Future.wait(
        puuids.map((sub) async {
          Map<String, dynamic>? mmrData;
          List<Map<String, dynamic>> compUpdates = const [];
          try {
            mmrData = await _remoteDataSource.fetchPlayerMmr(
              shard: shard,
              puuid: sub,
            );
          } catch (_) {}
          try {
            compUpdates = await _careerDataSource.fetchCompetitiveUpdates(
              shard: shard,
              puuid: sub,
              startIndex: 0,
              endIndex: 15,
            );
          } catch (_) {}
          return MapEntry(sub, _PlayerStats(mmr: mmrData, updates: compUpdates));
        }),
      ),
    ]);

    final mapsMeta = results[0] as Map<String, Map<String, dynamic>>;
    final agentsMeta = results[1] as Map<String, Map<String, dynamic>>;
    final tiersMeta = results[2] as Map<int, Map<String, dynamic>>;
    final namesList = results[3] as List<Map<String, dynamic>>;
    final statsEntries =
        results[4] as List<MapEntry<String, _PlayerStats>>;
    final statsMap = Map.fromEntries(statsEntries);

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

        // Player MMR & Competitive Updates
        var rankName = 'Unranked';
        String? rankIcon;
        int currentRr = 0;
        var peakRank = 'Unranked';
        String? peakRankIcon;

        final playerStats = statsMap[sub];
        final mmrData = playerStats?.mmr;
        final compUpdates = playerStats?.updates ?? const [];

        if (mmrData != null || compUpdates.isNotEmpty) {
          final parsed = _extractRankFromMmr(
            mmrData ?? const {},
            tiersMeta,
            competitiveUpdates: compUpdates,
          );
          rankName = parsed['rankName'] ?? 'Unranked';
          rankIcon = parsed['rankIcon'];
          currentRr = parsed['currentRr'] as int? ?? 0;
          peakRank = parsed['peakRank'] ?? 'Unranked';
          peakRankIcon = parsed['peakRankIcon'];
        }

        final wl = _calculateRecentWinLoss(compUpdates);
        final extendedStats = _calculateExtendedStats(compUpdates, mmrData);

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
          peakRankIcon: peakRankIcon,
          isSelf: isSelf,
          isLocked: true,
          recentWins: wl.wins,
          recentLosses: wl.losses,
          recentMatchOutcomes: wl.outcomes,
          // Extended stats
          averageCombatScore: extendedStats.acs,
          kdRatio: extendedStats.kd,
          kastPercentage: extendedStats.kast,
          kda: extendedStats.kda,
          averageDamageRound: extendedStats.adr,
          headshotPercentage: extendedStats.hs,
          winPercentage: wl.wins + wl.losses > 0
              ? (wl.wins / (wl.wins + wl.losses)) * 100
              : null,
          lastNMatchCount: compUpdates.isNotEmpty ? compUpdates.length : null,
          lastNActScore: extendedStats.actScore,
          currentRankEpisodeAct: extendedStats.currentEpisodeAct,
          peakRankEpisodeAct: extendedStats.peakEpisodeAct,
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
        playerSide: 'Attack', // placeholder — API doesn't expose side directly
        blueScore: 0,
        redScore: 0,
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

    final allyTeamRaw = matchData['AllyTeam'] is Map
        ? Map<String, dynamic>.from(matchData['AllyTeam'] as Map)
        : null;
    final rawPlayers = allyTeamRaw?['Players'] is List
        ? (allyTeamRaw!['Players'] as List)
        : const [];

    final List<String> puuids = [];
    for (final p in rawPlayers) {
      if (p is Map && p['Subject'] != null) {
        puuids.add(p['Subject'].toString());
      }
    }

    // Parallelize metadata, names, and player MMR + Competitive lookups
    final results = await Future.wait([
      _careerDataSource
          .fetchMapsMetadata()
          .catchError((_) => <String, Map<String, dynamic>>{}),
      _careerDataSource
          .fetchAgentsMetadata()
          .catchError((_) => <String, Map<String, dynamic>>{}),
      _careerDataSource
          .fetchCompetitiveTiersMetadata()
          .catchError((_) => <int, Map<String, dynamic>>{}),
      _remoteDataSource
          .fetchPlayerNames(shard: shard, puuids: puuids)
          .catchError((_) => <Map<String, dynamic>>[]),
      Future.wait(
        puuids.map((sub) async {
          Map<String, dynamic>? mmrData;
          List<Map<String, dynamic>> compUpdates = const [];
          try {
            mmrData = await _remoteDataSource.fetchPlayerMmr(
              shard: shard,
              puuid: sub,
            );
          } catch (_) {}
          try {
            compUpdates = await _careerDataSource.fetchCompetitiveUpdates(
              shard: shard,
              puuid: sub,
              startIndex: 0,
              endIndex: 15,
            );
          } catch (_) {}
          return MapEntry(sub, _PlayerStats(mmr: mmrData, updates: compUpdates));
        }),
      ),
    ]);

    final mapsMeta = results[0] as Map<String, Map<String, dynamic>>;
    final agentsMeta = results[1] as Map<String, Map<String, dynamic>>;
    final tiersMeta = results[2] as Map<int, Map<String, dynamic>>;
    final namesList = results[3] as List<Map<String, dynamic>>;
    final statsEntries =
        results[4] as List<MapEntry<String, _PlayerStats>>;
    final statsMap = Map.fromEntries(statsEntries);

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
        String? peakRankIcon;

        final playerStats = statsMap[sub];
        final mmrData = playerStats?.mmr;
        final compUpdates = playerStats?.updates ?? const [];

        if (mmrData != null || compUpdates.isNotEmpty) {
          final parsed = _extractRankFromMmr(
            mmrData ?? const {},
            tiersMeta,
            competitiveUpdates: compUpdates,
          );
          rankName = parsed['rankName'] ?? 'Unranked';
          rankIcon = parsed['rankIcon'];
          currentRr = parsed['currentRr'] as int? ?? 0;
          peakRank = parsed['peakRank'] ?? 'Unranked';
          peakRankIcon = parsed['peakRankIcon'];
        }

        final wl = _calculateRecentWinLoss(compUpdates);
        final extendedStats = _calculateExtendedStats(compUpdates, mmrData);

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
            peakRankIcon: peakRankIcon,
            isSelf: sub == selfPuuid,
            isLocked: charState == 'locked',
            recentWins: wl.wins,
            recentLosses: wl.losses,
            recentMatchOutcomes: wl.outcomes,
            // Extended stats
            averageCombatScore: extendedStats.acs,
            kdRatio: extendedStats.kd,
            kastPercentage: extendedStats.kast,
            kda: extendedStats.kda,
            averageDamageRound: extendedStats.adr,
            headshotPercentage: extendedStats.hs,
            winPercentage: wl.wins + wl.losses > 0
                ? (wl.wins / (wl.wins + wl.losses)) * 100
                : null,
            lastNMatchCount: compUpdates.isNotEmpty ? compUpdates.length : null,
            lastNActScore: extendedStats.actScore,
            currentRankEpisodeAct: extendedStats.currentEpisodeAct,
            peakRankEpisodeAct: extendedStats.peakEpisodeAct,
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
        playerSide: 'Attack',
        blueScore: 0,
        redScore: 0,
      ),
    );
  }

  Map<String, dynamic> _extractRankFromMmr(
    Map<String, dynamic> mmrData,
    Map<int, Map<String, dynamic>> tiersMeta, {
    List<Map<String, dynamic>>? competitiveUpdates,
  }) {
    try {
      final queueSkills = mmrData['QueueSkills'] is Map
          ? Map<String, dynamic>.from(mmrData['QueueSkills'] as Map)
          : null;
      final compSkill = queueSkills?['competitive'] is Map
          ? Map<String, dynamic>.from(queueSkills!['competitive'] as Map)
          : null;
      var currentTier = compSkill?['Tier'] as int? ?? 0;
      var currentRr = compSkill?['RankedRating'] as int? ?? 0;

      // Fallback 1: LatestCompetitiveUpdate from mmrData
      final latestUpdate = mmrData['LatestCompetitiveUpdate'] is Map
          ? Map<String, dynamic>.from(mmrData['LatestCompetitiveUpdate'] as Map)
          : null;
      if (latestUpdate != null) {
        final tierAfter =
            (latestUpdate['TierAfterUpdate'] as num?)?.toInt() ?? 0;
        final rrAfter =
            (latestUpdate['RankedRatingAfterUpdate'] as num?)?.toInt() ??
                (latestUpdate['RankRatingAfterUpdate'] as num?)?.toInt() ??
                0;
        if (tierAfter > 0 && currentTier == 0) {
          currentTier = tierAfter;
          currentRr = rrAfter;
        } else if (currentRr == 0 && rrAfter > 0) {
          currentRr = rrAfter;
        }
      }

      // Fallback 2: First match from competitiveUpdates
      if (currentTier == 0 &&
          competitiveUpdates != null &&
          competitiveUpdates.isNotEmpty) {
        final firstComp = competitiveUpdates.first;
        final tierAfter = (firstComp['TierAfterUpdate'] as num?)?.toInt() ?? 0;
        final rrAfter =
            (firstComp['RankedRatingAfterUpdate'] as num?)?.toInt() ??
                (firstComp['RankRatingAfterUpdate'] as num?)?.toInt() ??
                0;
        if (tierAfter > 0) {
          currentTier = tierAfter;
          currentRr = rrAfter;
        }
      }

      // Fallback 3: check recent seasonal tier
      final seasonal = compSkill?['SeasonalInfoBySeasonID'] is Map
          ? Map<String, dynamic>.from(compSkill!['SeasonalInfoBySeasonID'] as Map)
          : null;
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
      var rankIcon = tierInfo?['largeIcon'] ?? tierInfo?['smallIcon'];
      if (rankIcon != null && rankIcon.toString().trim().isEmpty) {
        rankIcon = null;
      }

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

      if (competitiveUpdates != null) {
        for (final update in competitiveUpdates) {
          final tAfter = (update['TierAfterUpdate'] as num?)?.toInt() ?? 0;
          if (tAfter > peakTier) peakTier = tAfter;
        }
      }

      final peakInfo = tiersMeta[peakTier];
      final peakRankName = peakInfo?['tierName'] ?? rankName;
      var peakRankIcon = peakInfo?['largeIcon'] ?? peakInfo?['smallIcon'];
      if (peakRankIcon != null && peakRankIcon.toString().trim().isEmpty) {
        peakRankIcon = null;
      }

      return {
        'rankName': rankName,
        'rankIcon': rankIcon,
        'currentRr': currentRr,
        'peakRank': peakRankName,
        'peakRankIcon': peakRankIcon,
      };
    } catch (_) {
      return {
        'rankName': 'Unranked',
        'rankIcon': null,
        'currentRr': 0,
        'peakRank': 'Unranked',
        'peakRankIcon': null,
      };
    }
  }

  ({int wins, int losses, List<bool> outcomes}) _calculateRecentWinLoss(
    List<Map<String, dynamic>> updates,
  ) {
    int wins = 0;
    int losses = 0;
    final List<bool> outcomes = [];

    for (final update in updates.take(10)) {
      final tierAfter = (update['TierAfterUpdate'] as num?)?.toInt() ?? 0;
      final tierBefore = (update['TierBeforeUpdate'] as num?)?.toInt() ?? 0;
      final rrEarned = (update['RankedRatingEarned'] as num?)?.toInt() ??
          (update['RankRatingEarned'] as num?)?.toInt() ??
          (((update['RankedRatingAfterUpdate'] as num?)?.toInt() ?? 0) -
              ((update['RankedRatingBeforeUpdate'] as num?)?.toInt() ?? 0));

      if (tierAfter > tierBefore) {
        wins++;
        outcomes.add(true);
      } else if (tierAfter < tierBefore) {
        losses++;
        outcomes.add(false);
      } else if (rrEarned > 0) {
        wins++;
        outcomes.add(true);
      } else if (rrEarned < 0) {
        losses++;
        outcomes.add(false);
      }
    }

    return (wins: wins, losses: losses, outcomes: outcomes);
  }

  /// Calculate extended stats for Ascend Companion player card.
  /// Data derivable from competitive updates: WIN%, K/D proxy.
  /// ACS, ADR, HS%, KAST, KDA are not available from competitive updates
  /// alone, so they remain null unless we can extract them.
  _ExtendedStats _calculateExtendedStats(
    List<Map<String, dynamic>> compUpdates,
    Map<String, dynamic>? mmrData,
  ) {
    // Try to extract episode/act info from MMR data
    String? currentEpisodeAct;
    String? peakEpisodeAct;
    int? actScore;

    if (mmrData != null) {
      final queueSkills = mmrData['QueueSkills'] is Map
          ? Map<String, dynamic>.from(mmrData['QueueSkills'] as Map)
          : null;
      final compSkill = queueSkills?['competitive'] is Map
          ? Map<String, dynamic>.from(queueSkills!['competitive'] as Map)
          : null;

      // Extract current season episode/act
      final seasonal = compSkill?['SeasonalInfoBySeasonID'] is Map
          ? Map<String, dynamic>.from(compSkill!['SeasonalInfoBySeasonID'] as Map)
          : null;

      if (seasonal != null && seasonal.isNotEmpty) {
        // Sort seasons to find the most recent with data
        final entries = seasonal.entries.toList();
        // Season IDs are UUIDs but we can just pick the last entry as "current"
        for (final entry in entries.reversed) {
          if (entry.value is Map) {
            final seasonData = Map<String, dynamic>.from(entry.value as Map);
            final tier = seasonData['CompetitiveTier'] as int? ?? 0;
            final wins = seasonData['NumberOfWins'] as int? ?? 0;
            final winsWithPlacements = seasonData['NumberOfWinsWithPlacements'] as int? ?? 0;
            final rankedRating = seasonData['RankedRating'] as int? ?? 0;

            if (tier > 0 || wins > 0 || winsWithPlacements > 0) {
              // Try to extract Act Rank (RankedRating from seasonal info)
              actScore = rankedRating > 0 ? rankedRating : null;

              // Episode/Act label from season ID pattern
              final seasonId = entry.key;
              currentEpisodeAct = _seasonIdToLabel(seasonId);
              break;
            }
          }
        }

        // Find peak season
        int peakTier = 0;
        String? peakSeasonId;
        for (final entry in entries) {
          if (entry.value is Map) {
            final seasonData = Map<String, dynamic>.from(entry.value as Map);
            final tier = seasonData['CompetitiveTier'] as int? ?? 0;
            final badgeRank = (seasonData['SeasonalBadgeInfo'] is Map)
                ? ((seasonData['SeasonalBadgeInfo'] as Map)['Rank'] as int? ?? 0)
                : 0;
            final bestTier = tier > badgeRank ? tier : badgeRank;
            if (bestTier > peakTier) {
              peakTier = bestTier;
              peakSeasonId = entry.key;
            }
          }
        }
        if (peakSeasonId != null) {
          peakEpisodeAct = _seasonIdToLabel(peakSeasonId);
        }
      }
    }

    // Stats that can't be computed from competitive updates alone remain null
    return _ExtendedStats(
      acs: null,
      kd: null,
      kast: null,
      kda: null,
      adr: null,
      hs: null,
      actScore: actScore,
      currentEpisodeAct: currentEpisodeAct,
      peakEpisodeAct: peakEpisodeAct,
    );
  }

  /// Convert Riot season UUID to human-readable Episode/Act label.
  /// This is a best-effort mapping based on known season patterns.
  String? _seasonIdToLabel(String seasonId) {
    // Known Riot Season ID mappings (shortened for readability)
    // These are stable UUIDs that Riot doesn't change
    final knownSeasons = <String, String>{
      // Episode 1
      '0df5adb9-4dcb-6899-1306-3e9860661dd3': 'E1A1',
      '3f61c772-4560-cd3f-5d3f-a7ab5abda6b3': 'E1A2',
      '2a27e5d2-4d30-c9e2-b15a-93b8909a442c': 'E1A3',
      // Episode 2
      'a16955a5-4ad0-f761-5e47-2b9c06c5e275': 'E2A1',
      '97b6e739-44cc-ffa7-49ad-398ba502ceb0': 'E2A2',
      'ab57ef51-4e59-da91-cc8d-51a5a2b9b8ff': 'E2A3',
      // Episode 3
      '52e9b2cb-4ce0-a74f-e269-3dbe0d2b4ab1': 'E3A1',
      '71c81c67-4fae-ceb1-844c-aab2bb8710fa': 'E3A2',
      'a3bfb853-43b2-7238-a4f1-ad90e9e46bcc': 'E3A3',
      // Episode 4
      '4cb622e1-4244-6b69-a9f2-40b4b43f32d6': 'E4A1',
      'a5f25e17-45a0-3d8c-5e7b-5db8c3068ebc': 'E4A2',
      '59b7a0b2-4b31-ab3f-80ea-3daaa7c5a0f2': 'E4A3',
      // Episode 5
      'fe44ab0b-4eed-8fc5-b2bd-17b7c06e4880': 'E5A1',
      'cc86ae46-49a4-76a4-b78f-179a32d0a81e': 'E5A2',
      '3e4bb74c-4a30-1c25-8d1b-5d46fea39a51': 'E5A3',
      // Episode 6+
      '67e373c7-48f7-b422-641b-079ace30b427': 'E6A1',
      'aca29595-40e4-01f5-3f35-b1b3d304c96e': 'E6A2',
      'f2b40f2e-4983-21f1-fa7b-87a6d2e97277': 'E6A3',
      // Episode 7
      '1c4e0700-45eb-5f80-8e88-b3b4fdacb0e0': 'E7A1',
      '5c89c37f-4d2f-5d5d-bfef-d19dce90ea0c': 'E7A2',
      '5e15e6fe-44d4-a1b0-8053-36bbbe5adc69': 'E7A3',
      // Episode 8
      'e8927d6c-46ab-54a3-99cd-9b557c11e8ca': 'E8A1',
      '80523e12-4ff1-56c9-a5bf-1eb7f99f282d': 'E8A2',
      'b7451e55-4b4f-dc42-7c66-4b83b1a75fbb': 'E8A3',
      // Episode 9
      'f1c85909-4b2f-5a01-cc28-7eab3d7e75b7': 'E9A1',
    };

    return knownSeasons[seasonId];
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

class _PlayerStats {
  final Map<String, dynamic>? mmr;
  final List<Map<String, dynamic>> updates;

  const _PlayerStats({
    this.mmr,
    this.updates = const [],
  });
}

class _ExtendedStats {
  final double? acs;
  final double? kd;
  final double? kast;
  final double? kda;
  final double? adr;
  final double? hs;
  final int? actScore;
  final String? currentEpisodeAct;
  final String? peakEpisodeAct;

  const _ExtendedStats({
    this.acs,
    this.kd,
    this.kast,
    this.kda,
    this.adr,
    this.hs,
    this.actScore,
    this.currentEpisodeAct,
    this.peakEpisodeAct,
  });
}
