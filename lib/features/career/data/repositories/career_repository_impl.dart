import 'dart:convert';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';

class CareerRepositoryImpl implements CareerRepository {
  final CareerRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;
  final LocalStoreService _localStore;

  CareerRepositoryImpl({
    required CareerRemoteDataSource remoteDataSource,
    required SecureStorageService storage,
    required LocalStoreService localStore,
  })  : _remoteDataSource = remoteDataSource,
        _storage = storage,
        _localStore = localStore;

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
  Future<Result<CareerOverview>> getCareerOverview({
    bool forceRefresh = false,
  }) async {
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

      if (puuid == null || puuid.isEmpty) {
        return const Result.failure(
          AuthFailure(message: 'No active Riot session. Please sign in.'),
        );
      }

      // Check cache first if not forced
      if (!forceRefresh) {
        final cachedJson = await _localStore.getCachedCareerJson(puuid);
        if (cachedJson != null && cachedJson.isNotEmpty) {
          try {
            final map = jsonDecode(cachedJson) as Map<String, dynamic>;
            final overview = CareerOverview.fromJson(map);
            // If the cached overview has matches that played rounds but have no round details,
            // it's an obsolete cache from before round history was added. Discard and fetch fresh!
            final isStale = overview.matches
                .any((m) => m.rounds.isEmpty && m.roundsPlayed > 0);
            if (!isStale) {
              return Result.success(overview);
            }
          } catch (_) {}
        }
      }

      return await _fetchFreshCareerOverview(shard: shard, puuid: puuid);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to load career data: $e'),
      );
    }
  }

  Future<Result<CareerOverview>> _fetchFreshCareerOverview({
    required String shard,
    required String puuid,
  }) async {
    try {
      // Fetch core remote metadata and raw history concurrently
      final results = await Future.wait([
        _remoteDataSource.fetchMatchHistory(
          shard: shard,
          puuid: puuid,
          startIndex: 0,
          endIndex: 12,
        ),
        _remoteDataSource.fetchCompetitiveUpdates(
          shard: shard,
          puuid: puuid,
          startIndex: 0,
          endIndex: 15,
        ),
        _remoteDataSource.fetchPlayerMmr(shard: shard, puuid: puuid),
        _remoteDataSource.fetchMapsMetadata(),
        _remoteDataSource.fetchAgentsMetadata(),
        _remoteDataSource.fetchCompetitiveTiersMetadata(),
      ]);

      final rawHistory = results[0] as List<Map<String, dynamic>>;
      final compUpdates = results[1] as List<Map<String, dynamic>>;
      final mmrData = results[2] as Map<String, dynamic>?;
      final mapsMeta = results[3] as Map<String, Map<String, dynamic>>;
      final agentsMeta = results[4] as Map<String, Map<String, dynamic>>;
      final tiersMeta = results[5] as Map<int, Map<String, dynamic>>;

      // Map competitive updates by MatchID (both normal and lowercase for case-insensitivity)
      final compUpdateByMatchId = <String, Map<String, dynamic>>{};
      for (final update in compUpdates) {
        final mId = (update['MatchID'] ?? '').toString();
        if (mId.isNotEmpty) {
          compUpdateByMatchId[mId] = update;
          compUpdateByMatchId[mId.toLowerCase()] = update;
        }
      }

      // Fetch match details for the recent matches in history with persistent caching
      final matchFutures = rawHistory.take(10).map((h) async {
        final matchId = (h['MatchID'] ?? '').toString();
        if (matchId.isEmpty) return null;

        // 1. Check persistent match details cache first (0ms)
        try {
          final cachedStr = await _localStore.getCachedMatchDetails(matchId);
          if (cachedStr != null && cachedStr.isNotEmpty) {
            final decoded = jsonDecode(cachedStr);
            if (decoded is Map) {
              final cachedMap = Map<String, dynamic>.from(decoded);
              final cachedRounds = (cachedMap['roundResults'] as List?) ??
                  (cachedMap['RoundResults'] as List?);
              final queue = (cachedMap['matchInfo']?['queueID'] ??
                      cachedMap['matchInfo']?['queueId'] ??
                      '')
                  .toString()
                  .toLowerCase();
              // Only reuse cache if it has roundResults or if it's deathmatch (where rounds don't exist)
              if (queue == 'deathmatch' ||
                  (cachedRounds != null && cachedRounds.isNotEmpty)) {
                return cachedMap;
              }
            }
          }
        } catch (_) {}

        // 2. Fetch from remote and persist to cache
        try {
          final matchData = await _remoteDataSource.fetchMatchDetails(
            shard: shard,
            matchId: matchId,
          );
          if (matchData != null) {
            _localStore
                .saveCachedMatchDetails(matchId, jsonEncode(matchData))
                .ignore();
          }
          return matchData;
        } catch (_) {
          return null;
        }
      });

      final matchDetailsList = await Future.wait(matchFutures);

      // Collect all unique player PUUIDs to resolve Riot IDs in bulk via name-service
      final allPuuids = <String>{};
      for (final m in matchDetailsList) {
        if (m == null) continue;
        final players = (m['players'] as List?) ?? [];
        for (final p in players) {
          if (p is Map) {
            final pPuuid = (p['subject'] ?? p['puuid'] ?? '').toString().trim();
            if (pPuuid.isNotEmpty) allPuuids.add(pPuuid);
          }
        }
      }

      final Map<String, Map<String, String>> namesMap = {};
      if (allPuuids.isNotEmpty) {
        try {
          final namesList = await _remoteDataSource.fetchPlayerNames(
            shard: shard,
            puuids: allPuuids.toList(),
          );
          for (final n in namesList) {
            final sub = (n['Subject'] ?? '').toString().toLowerCase();
            namesMap[sub] = {
              'gameName': (n['GameName'] ?? '').toString(),
              'tagLine': (n['TagLine'] ?? '').toString(),
            };
          }
        } catch (_) {}
      }

      final matches = <MatchSummary>[];
      for (final matchData in matchDetailsList) {
        if (matchData == null) continue;
        final summary = _parseMatchSummary(
          matchData: matchData,
          currentPuuid: puuid,
          compUpdates: compUpdateByMatchId,
          mapsMeta: mapsMeta,
          agentsMeta: agentsMeta,
          tiersMeta: tiersMeta,
          namesMap: namesMap,
        );
        if (summary != null) {
          matches.add(summary);
        }
      }

      // Parse MMR rank information
      int currentTier = 0;
      int currentRR = 0;
      int? peakTier;

      if (mmrData != null) {
        final queueSkills = mmrData['QueueSkills'] as Map?;
        final compQueue = queueSkills?['competitive'] as Map?;
        if (compQueue != null) {
          // 1. Check direct Tier & RankedRating from compQueue
          final directTier = (compQueue['Tier'] as num?)?.toInt() ?? 0;
          final directRR = (compQueue['RankedRating'] as num?)?.toInt() ??
              (compQueue['RankRating'] as num?)?.toInt() ??
              0;
          if (directTier > 0) {
            currentTier = directTier;
            currentRR = directRR;
          }

          // 2. Peak rank & seasonal info
          final seasonalInfo = compQueue['SeasonalInfoBySeasonID'] as Map?;
          if (seasonalInfo != null && seasonalInfo.isNotEmpty) {
            for (final entry in seasonalInfo.entries) {
              final seasonData = entry.value as Map?;
              if (seasonData != null) {
                final rank = (seasonData['CompetitiveTier'] as num?)?.toInt() ??
                    (seasonData['Rank'] as num?)?.toInt() ??
                    0;
                final badgeRank =
                    (seasonData['SeasonalBadgeInfo']?['Rank'] as num?)?.toInt() ??
                        0;
                if (rank > (peakTier ?? 0)) peakTier = rank;
                if (badgeRank > (peakTier ?? 0)) peakTier = badgeRank;

                // Fallback currentTier/RR if not set
                if (currentTier == 0 && rank > 0) {
                  currentTier = rank;
                  currentRR = (seasonData['RankedRating'] as num?)?.toInt() ??
                      (seasonData['RankRating'] as num?)?.toInt() ??
                      0;
                }
              }
            }
          }
        }

        // 3. LatestCompetitiveUpdate in mmrData
        final latestCompUpdate = mmrData['LatestCompetitiveUpdate'] as Map?;
        if (latestCompUpdate != null) {
          final tierAfter =
              (latestCompUpdate['TierAfterUpdate'] as num?)?.toInt() ?? 0;
          final rrAfter =
              (latestCompUpdate['RankedRatingAfterUpdate'] as num?)?.toInt() ??
                  (latestCompUpdate['RankRatingAfterUpdate'] as num?)?.toInt() ??
                  0;
          if (tierAfter > 0) {
            currentTier = tierAfter;
            currentRR = rrAfter;
          } else if (currentRR == 0 && rrAfter > 0) {
            currentRR = rrAfter;
          }
        }
      }

      // 4. If MMR rank wasn't found or RR is 0, check competitive updates list
      if (compUpdates.isNotEmpty) {
        final firstComp = compUpdates.first;
        final tierAfter =
            (firstComp['TierAfterUpdate'] as num?)?.toInt() ?? 0;
        final rrAfter =
            (firstComp['RankedRatingAfterUpdate'] as num?)?.toInt() ??
                (firstComp['RankRatingAfterUpdate'] as num?)?.toInt() ??
                0;
        if (currentTier == 0 && tierAfter > 0) {
          currentTier = tierAfter;
          currentRR = rrAfter;
        } else if (currentRR == 0 && rrAfter > 0) {
          currentRR = rrAfter;
        }
      }

      // 5. If currentTier still 0, check matches
      if (currentTier == 0 && matches.isNotEmpty) {
        for (final m in matches) {
          if (m.competitiveTier != null && m.competitiveTier! > 0) {
            currentTier = m.competitiveTier!;
            break;
          }
        }
      }

      // Tier display names and icons
      final currentTierInfo = tiersMeta[currentTier];
      final currentTierName = currentTierInfo?['tierName'] ??
          (currentTier == 0 ? 'Unrated' : 'Rank $currentTier');
      final currentTierIcon = currentTierInfo?['largeIcon'] ?? currentTierInfo?['smallIcon'];

      final peakTierInfo = peakTier != null ? tiersMeta[peakTier] : null;
      final peakTierName = peakTierInfo?['tierName'];
      final peakTierIcon = peakTierInfo?['largeIcon'] ?? peakTierInfo?['smallIcon'];

      // Aggregations
      final totalMatches = matches.length;
      final totalWins = matches.where((m) => m.won == true).length;
      final totalLosses = matches.where((m) => m.won == false).length;
      final winRate = totalMatches > 0 ? (totalWins / totalMatches) * 100 : 0.0;

      int sumScore = 0;
      int sumKills = 0;
      int sumDeaths = 0;
      int sumHs = 0;
      int sumBs = 0;
      int sumLs = 0;

      for (final m in matches) {
        sumScore += m.averageCombatScore;
        sumKills += m.kills;
        sumDeaths += m.deaths;
        sumHs += m.headshots;
        sumBs += m.bodyshots;
        sumLs += m.legshots;
      }

      final avgCombatScore = totalMatches > 0 ? (sumScore / totalMatches).round() : 0;
      final avgKdRatio = sumDeaths > 0
          ? sumKills / sumDeaths
          : (sumKills > 0 ? sumKills.toDouble() : 0.0);
      final totalHits = sumHs + sumBs + sumLs;
      final avgHeadshotPct = totalHits > 0 ? (sumHs / totalHits) * 100 : 0.0;

      final careerOverview = CareerOverview(
        currentTier: currentTier,
        currentTierName: currentTierName,
        currentTierIcon: currentTierIcon,
        currentRankRating: currentRR,
        peakTier: peakTier,
        peakTierName: peakTierName,
        peakTierIcon: peakTierIcon,
        totalMatches: totalMatches,
        totalWins: totalWins,
        totalLosses: totalLosses,
        winRate: winRate,
        avgCombatScore: avgCombatScore,
        avgKdRatio: avgKdRatio,
        avgHeadshotPct: avgHeadshotPct,
        matches: matches,
      );

      // Cache to local storage
      await _localStore.saveCachedCareerJson(
        puuid,
        jsonEncode(careerOverview.toJson()),
      );

      return Result.success(careerOverview);
    } catch (e) {
      // If network fails, check if we have cached data to fall back on
      final cachedJson = await _localStore.getCachedCareerJson(puuid);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final map = jsonDecode(cachedJson) as Map<String, dynamic>;
          return Result.success(CareerOverview.fromJson(map));
        } catch (_) {}
      }

      return Result.failure(
        ServerFailure(message: 'Failed to retrieve match history: $e'),
      );
    }
  }

  MatchSummary? _parseMatchSummary({
    required Map<String, dynamic> matchData,
    required String currentPuuid,
    required Map<String, Map<String, dynamic>> compUpdates,
    required Map<String, Map<String, dynamic>> mapsMeta,
    required Map<String, Map<String, dynamic>> agentsMeta,
    required Map<int, Map<String, dynamic>> tiersMeta,
    Map<String, Map<String, String>> namesMap = const {},
  }) {
    try {
      final matchInfo = (matchData['matchInfo'] as Map?) ?? {};
      final matchId = (matchInfo['matchId'] ?? '').toString();
      final mapId = (matchInfo['mapId'] ?? '').toString();
      final gameMode = (matchInfo['gameMode'] ?? '').toString();
      final queueId = (matchInfo['queueID'] ?? matchInfo['queueId'] ?? '').toString();
      final gameLengthMillis = (matchInfo['gameLengthMillis'] as num?)?.toInt() ?? 0;
      final gameStartMillis = (matchInfo['gameStartMillis'] as num?)?.toInt() ?? 0;
      final gameStartTime = gameStartMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(gameStartMillis)
          : DateTime.now();

      // Find user player in players list
      final players = (matchData['players'] as List?) ?? [];
      Map? userPlayer;
      for (final p in players) {
        if (p is Map && (p['subject'] ?? p['puuid'] ?? '').toString().toLowerCase() == currentPuuid.toLowerCase()) {
          userPlayer = p;
          break;
        }
      }

      if (userPlayer == null) return null;

      final teamId = (userPlayer['teamId'] ?? '').toString();
      final agentId = (userPlayer['characterId'] ?? '').toString().toLowerCase();
      final playerStats = (userPlayer['stats'] as Map?) ?? {};
      final kills = (playerStats['kills'] as num?)?.toInt() ?? 0;
      final deaths = (playerStats['deaths'] as num?)?.toInt() ?? 0;
      final assists = (playerStats['assists'] as num?)?.toInt() ?? 0;
      final score = (playerStats['score'] as num?)?.toInt() ?? 0;
      var roundsPlayed = (playerStats['roundsPlayed'] as num?)?.toInt() ?? 0;
      int compTier = (userPlayer['competitiveTier'] as num?)?.toInt() ?? 0;

      // Find team results
      final teams = (matchData['teams'] as List?) ?? [];
      bool? won;
      bool isDraw = false;
      int scoreWon = 0;
      int scoreLost = 0;

      for (final t in teams) {
        if (t is Map) {
          final tId = (t['teamId'] ?? '').toString();
          final tWon = t['won'] == true;
          final roundsWon = (t['roundsWon'] as num?)?.toInt() ?? 0;

          if (tId.toLowerCase() == teamId.toLowerCase()) {
            won = tWon;
            scoreWon = roundsWon;
          } else {
            scoreLost = roundsWon;
          }
        }
      }

      if (roundsPlayed == 0 && (scoreWon > 0 || scoreLost > 0)) {
        roundsPlayed = scoreWon + scoreLost;
      }

      if (scoreWon == scoreLost && scoreWon > 0) {
        isDraw = true;
        won = null;
      }

      // Calculate headshots / bodyshots / legshots / damage from roundResults
      int totalHs = 0;
      int totalBs = 0;
      int totalLs = 0;
      int totalDmg = 0;

      final roundResults = (matchData['roundResults'] as List?) ??
          (matchData['RoundResults'] as List?) ??
          (matchData['round_results'] as List?) ??
          [];
      for (final r in roundResults) {
        if (r is Map) {
          final playerStatsList = (r['playerStats'] as List?) ?? [];
          for (final ps in playerStatsList) {
            if (ps is Map &&
                (ps['subject'] ?? ps['puuid'] ?? '').toString().toLowerCase() == currentPuuid.toLowerCase()) {
              final damageList = (ps['damage'] as List?) ?? [];
              for (final d in damageList) {
                if (d is Map) {
                  totalDmg += (d['damage'] as num?)?.toInt() ?? 0;
                  totalHs += (d['headshots'] as num?)?.toInt() ?? 0;
                  totalBs += (d['bodyshots'] as num?)?.toInt() ?? 0;
                  totalLs += (d['legshots'] as num?)?.toInt() ?? 0;
                }
              }
            }
          }
        }
      }

      // Check competitive update for RR change
      int? rrEarned;
      final compUpdate =
          compUpdates[matchId] ?? compUpdates[matchId.toLowerCase()];
      if (compUpdate != null) {
        rrEarned = (compUpdate['RankedRatingEarned'] as num?)?.toInt() ??
            (compUpdate['RankRatingEarned'] as num?)?.toInt();
        final tierAfter = (compUpdate['TierAfterUpdate'] as num?)?.toInt();
        if (tierAfter != null && tierAfter > 0) {
          compTier = tierAfter;
        }
      }

      // Map metadata
      final mapData = mapsMeta[mapId] ?? mapsMeta[mapId.toLowerCase()];
      final mapName = mapData?['displayName'] ?? _extractMapNameFromPath(mapId);
      final mapImageUrl = mapData?['splash'] ?? mapData?['listViewIcon'];

      // Agent metadata
      final agentData = agentsMeta[agentId];
      final agentName = agentData?['displayName'] ?? 'Agent';
      final agentIconUrl = agentData?['displayIcon'];

      // Rank metadata
      final tierData = tiersMeta[compTier];
      final rankName = tierData?['tierName'];
      final rankIconUrl = tierData?['largeIcon'] ?? tierData?['smallIcon'];

      final acs = roundsPlayed > 0 ? (score / roundsPlayed).round() : 0;

      // Parse teammates and enemies with ranks & stats
      final teammates = <MatchPlayerSummary>[];
      final enemies = <MatchPlayerSummary>[];
      final playerMetaMap = <String, MatchPlayerSummary>{};

      for (final p in players) {
        if (p is! Map) continue;
        final pPuuid = (p['subject'] ?? p['puuid'] ?? '').toString();
        final pTeamId = (p['teamId'] ?? '').toString();
        var pGameName = (p['gameName'] ?? '').toString();
        var pTagLine = (p['tagLine'] ?? '').toString();

        // If gameName is empty, look up in namesMap from name-service
        if (pGameName.isEmpty && namesMap.containsKey(pPuuid.toLowerCase())) {
          pGameName = namesMap[pPuuid.toLowerCase()]?['gameName'] ?? '';
          pTagLine = namesMap[pPuuid.toLowerCase()]?['tagLine'] ?? '';
        }

        final pAgentId = (p['characterId'] ?? '').toString().toLowerCase();
        final pCompTier = (p['competitiveTier'] as num?)?.toInt() ?? 0;
        final pStats = (p['stats'] as Map?) ?? {};
        final pKills = (p['stats'] != null
                ? (pStats['kills'] as num?)?.toInt()
                : (p['kills'] as num?)?.toInt()) ??
            0;
        final pDeaths = (p['stats'] != null
                ? (pStats['deaths'] as num?)?.toInt()
                : (p['deaths'] as num?)?.toInt()) ??
            0;
        final pAssists = (p['stats'] != null
                ? (pStats['assists'] as num?)?.toInt()
                : (p['assists'] as num?)?.toInt()) ??
            0;
        final pScore = (p['stats'] != null
                ? (pStats['score'] as num?)?.toInt()
                : (p['score'] as num?)?.toInt()) ??
            0;
        final pRoundsPlayed = (p['stats'] != null
                ? (pStats['roundsPlayed'] as num?)?.toInt()
                : (p['roundsPlayed'] as num?)?.toInt()) ??
            0;
        final pAcs = pRoundsPlayed > 0 ? (pScore / pRoundsPlayed).round() : 0;
        final pIsSelf = pPuuid.toLowerCase() == currentPuuid.toLowerCase();

        final pAgentData = agentsMeta[pAgentId];
        final pAgentName = pAgentData?['displayName'] ?? 'Agent';
        final pAgentIcon = pAgentData?['displayIcon'];

        final pTierData = tiersMeta[pCompTier];
        final pRankName = pTierData?['tierName'] ??
            (pCompTier > 0 ? 'Rank $pCompTier' : 'Unrated');
        final pRankIcon = pTierData?['largeIcon'] ?? pTierData?['smallIcon'];

        final playerSummary = MatchPlayerSummary(
          puuid: pPuuid,
          gameName: pGameName,
          tagLine: pTagLine,
          teamId: pTeamId,
          agentId: pAgentId,
          agentName: pAgentName,
          agentIconUrl: pAgentIcon,
          competitiveTier: pCompTier > 0 ? pCompTier : null,
          rankName: pRankName,
          rankIconUrl: pRankIcon,
          kills: pKills,
          deaths: pDeaths,
          assists: pAssists,
          score: pScore,
          roundsPlayed: pRoundsPlayed,
          averageCombatScore: pAcs,
          isSelf: pIsSelf,
        );

        playerMetaMap[pPuuid.toLowerCase()] = playerSummary;

        if (pTeamId.toLowerCase() == teamId.toLowerCase()) {
          teammates.add(playerSummary);
        } else {
          enemies.add(playerSummary);
        }
      }

      // Sort by score or ACS descending
      teammates.sort((a, b) => b.score.compareTo(a.score));
      enemies.sort((a, b) => b.score.compareTo(a.score));

      // Parse round history with kill events & agent info
      final rounds = <MatchRoundSummary>[];
      for (final r in roundResults) {
        if (r is! Map) continue;
        final roundNum = (r['roundNum'] as num?)?.toInt() ??
            (r['RoundNum'] as num?)?.toInt() ??
            (r['round_num'] as num?)?.toInt() ??
            0;
        final winningTeam = (r['winningTeam'] ??
                r['WinningTeam'] ??
                r['winning_team'] ??
                '')
            .toString();
        final roundResult = (r['roundResult'] ??
                r['RoundResult'] ??
                r['roundResultCode'] ??
                r['RoundResultCode'] ??
                r['round_result'] ??
                '')
            .toString();
        final bool? roundWon = winningTeam.isEmpty
            ? null
            : (winningTeam.toLowerCase() == teamId.toLowerCase());

        final playerStatsList = (r['playerStats'] as List?) ??
            (r['PlayerStats'] as List?) ??
            (r['player_stats'] as List?) ??
            [];
        final roundKills = <MatchRoundKill>[];

        // 1. Parse kills from playerStats
        for (final ps in playerStatsList) {
          if (ps is! Map) continue;
          final killsList = (ps['kills'] as List?) ??
              (ps['Kills'] as List?) ??
              [];
          for (final k in killsList) {
            if (k is! Map) continue;
            final killerPuuid = (k['killer'] ??
                    k['Killer'] ??
                    k['killerPuuid'] ??
                    k['KillerPuuid'] ??
                    ps['subject'] ??
                    ps['Subject'] ??
                    ps['puuid'] ??
                    ps['Puuid'] ??
                    '')
                .toString();
            final victimPuuid = (k['victim'] ??
                    k['Victim'] ??
                    k['victimPuuid'] ??
                    k['VictimPuuid'] ??
                    k['receiver'] ??
                    k['Receiver'] ??
                    '')
                .toString();
            final roundTime = (k['roundTime'] as num?)?.toInt() ??
                (k['RoundTime'] as num?)?.toInt() ??
                (k['gameTime'] as num?)?.toInt() ??
                (k['GameTime'] as num?)?.toInt() ??
                0;
            final finishingDmg = (k['finishingDamage'] as Map?) ??
                (k['FinishingDamage'] as Map?) ??
                {};
            final weaponId = (finishingDmg['damageItem'] ??
                    finishingDmg['DamageItem'] ??
                    finishingDmg['damageType'] ??
                    finishingDmg['DamageType'] ??
                    '')
                .toString();
            final rawAssistants = (k['assistants'] as List?) ??
                (k['Assistants'] as List?) ??
                [];
            final assistantPuuids = rawAssistants
                .map((a) {
                  if (a is Map) {
                    return (a['assistantPuuid'] ??
                            a['AssistantPuuid'] ??
                            a['subject'] ??
                            a['Subject'] ??
                            a['puuid'] ??
                            a['Puuid'] ??
                            '')
                        .toString();
                  }
                  return a.toString();
                })
                .where((a) => a.isNotEmpty)
                .toList();

            final killer = playerMetaMap[killerPuuid.toLowerCase()];
            final victim = playerMetaMap[victimPuuid.toLowerCase()];

            final assistantNames = assistantPuuids
                .map((a) => playerMetaMap[a.toLowerCase()]?.displayName ?? '')
                .where((n) => n.isNotEmpty)
                .toList();

            roundKills.add(MatchRoundKill(
              roundTime: roundTime,
              killerPuuid: killerPuuid,
              killerName: killer?.displayName ??
                  (killerPuuid.toLowerCase() == currentPuuid.toLowerCase()
                      ? 'YOU'
                      : 'Player'),
              killerAgentName: killer?.agentName ?? 'Agent',
              killerAgentIconUrl: killer?.agentIconUrl,
              killerTeamId: killer?.teamId ?? '',
              victimPuuid: victimPuuid,
              victimName: victim?.displayName ??
                  (victimPuuid.toLowerCase() == currentPuuid.toLowerCase()
                      ? 'YOU'
                      : 'Player'),
              victimAgentName: victim?.agentName ?? 'Agent',
              victimAgentIconUrl: victim?.agentIconUrl,
              victimTeamId: victim?.teamId ?? '',
              assistantPuuids: assistantPuuids,
              assistantNames: assistantNames,
              weaponId: weaponId.isNotEmpty ? weaponId : null,
              isKillerSelf:
                  killerPuuid.toLowerCase() == currentPuuid.toLowerCase(),
              isVictimSelf:
                  victimPuuid.toLowerCase() == currentPuuid.toLowerCase(),
            ));
          }
        }

        // 2. Also parse direct round-level kills if present (e.g. r['kills'])
        final directKillsList = (r['kills'] as List?) ??
            (r['Kills'] as List?) ??
            (r['killEvents'] as List?) ??
            (r['KillEvents'] as List?) ??
            (r['kill_events'] as List?) ??
            [];
        for (final k in directKillsList) {
          if (k is! Map) continue;
          final killerPuuid = (k['killer'] ??
                  k['Killer'] ??
                  k['killerPuuid'] ??
                  k['KillerPuuid'] ??
                  '')
              .toString();
          final victimPuuid = (k['victim'] ??
                  k['Victim'] ??
                  k['victimPuuid'] ??
                  k['VictimPuuid'] ??
                  '')
              .toString();
          final roundTime = (k['roundTime'] as num?)?.toInt() ??
              (k['RoundTime'] as num?)?.toInt() ??
              0;

          // Deduplicate if already parsed from playerStats
          final isDuplicate = roundKills.any((existing) =>
              existing.killerPuuid.toLowerCase() == killerPuuid.toLowerCase() &&
              existing.victimPuuid.toLowerCase() == victimPuuid.toLowerCase() &&
              existing.roundTime == roundTime);
          if (isDuplicate) continue;

          final finishingDmg = (k['finishingDamage'] as Map?) ??
              (k['FinishingDamage'] as Map?) ??
              {};
          final weaponId = (finishingDmg['damageItem'] ??
                  finishingDmg['DamageItem'] ??
                  '')
              .toString();
          final rawAssistants = (k['assistants'] as List?) ??
              (k['Assistants'] as List?) ??
              [];
          final assistantPuuids = rawAssistants
              .map((a) => a is Map
                  ? (a['assistantPuuid'] ?? a['subject'] ?? '').toString()
                  : a.toString())
              .where((a) => a.isNotEmpty)
              .toList();

          final killer = playerMetaMap[killerPuuid.toLowerCase()];
          final victim = playerMetaMap[victimPuuid.toLowerCase()];

          final assistantNames = assistantPuuids
              .map((a) => playerMetaMap[a.toLowerCase()]?.displayName ?? '')
              .where((n) => n.isNotEmpty)
              .toList();

          roundKills.add(MatchRoundKill(
            roundTime: roundTime,
            killerPuuid: killerPuuid,
            killerName: killer?.displayName ??
                (killerPuuid.toLowerCase() == currentPuuid.toLowerCase()
                    ? 'YOU'
                    : 'Player'),
            killerAgentName: killer?.agentName ?? 'Agent',
            killerAgentIconUrl: killer?.agentIconUrl,
            killerTeamId: killer?.teamId ?? '',
            victimPuuid: victimPuuid,
            victimName: victim?.displayName ??
                (victimPuuid.toLowerCase() == currentPuuid.toLowerCase()
                    ? 'YOU'
                    : 'Player'),
            victimAgentName: victim?.agentName ?? 'Agent',
            victimAgentIconUrl: victim?.agentIconUrl,
            victimTeamId: victim?.teamId ?? '',
            assistantPuuids: assistantPuuids,
            assistantNames: assistantNames,
            weaponId: weaponId.isNotEmpty ? weaponId : null,
            isKillerSelf:
                killerPuuid.toLowerCase() == currentPuuid.toLowerCase(),
            isVictimSelf:
                victimPuuid.toLowerCase() == currentPuuid.toLowerCase(),
          ));
        }

        // Sort kills chronologically
        roundKills.sort((a, b) => a.roundTime.compareTo(b.roundTime));

        rounds.add(MatchRoundSummary(
          roundNum: roundNum,
          winningTeam: winningTeam,
          won: roundWon,
          roundResult: roundResult,
          kills: roundKills,
        ));
      }

      // Sort rounds by roundNum ascending
      rounds.sort((a, b) => a.roundNum.compareTo(b.roundNum));

      if (rounds.isNotEmpty && rounds.length > roundsPlayed) {
        roundsPlayed = rounds.length;
      }

      return MatchSummary(
        matchId: matchId,
        mapId: mapId,
        mapName: mapName,
        mapImageUrl: mapImageUrl,
        gameMode: gameMode,
        queueId: queueId,
        gameStartTime: gameStartTime,
        gameLengthMillis: gameLengthMillis,
        won: won,
        isDraw: isDraw,
        scoreWon: scoreWon,
        scoreLost: scoreLost,
        agentId: agentId,
        agentName: agentName,
        agentIconUrl: agentIconUrl,
        kills: kills,
        deaths: deaths,
        assists: assists,
        score: score,
        roundsPlayed: roundsPlayed,
        averageCombatScore: acs,
        headshots: totalHs,
        bodyshots: totalBs,
        legshots: totalLs,
        damage: totalDmg,
        rankRatingEarned: rrEarned,
        competitiveTier: compTier > 0 ? compTier : null,
        rankName: rankName,
        rankIconUrl: rankIconUrl,
        teammates: teammates,
        enemies: enemies,
        rounds: rounds,
      );
    } catch (_) {
      return null;
    }
  }

  String _extractMapNameFromPath(String path) {
    if (path.isEmpty) return 'Unknown Map';
    final parts = path.split('/');
    if (parts.isNotEmpty && parts.last.isNotEmpty) {
      return parts.last;
    }
    return path;
  }

  @override
  Future<Result<MatchSummary>> getMatchDetail(String matchId) async {
    try {
      final puuid = await _storage.getPuuid();
      final shard = await _storage.getShard() ?? 'ap';
      if (puuid == null) {
        return const Result.failure(
          AuthFailure(message: 'User session not found.'),
        );
      }

      Map<String, dynamic>? matchData;
      try {
        final cachedStr = await _localStore.getCachedMatchDetails(matchId);
        if (cachedStr != null && cachedStr.isNotEmpty) {
          final decoded = jsonDecode(cachedStr);
          if (decoded is Map) {
            final cachedMap = Map<String, dynamic>.from(decoded);
            final cachedRounds = (cachedMap['roundResults'] as List?) ??
                (cachedMap['RoundResults'] as List?) ??
                (cachedMap['round_results'] as List?);
            final queue = (cachedMap['matchInfo']?['queueID'] ??
                    cachedMap['matchInfo']?['queueId'] ??
                    cachedMap['matchInfo']?['QueueID'] ??
                    '')
                .toString()
                .toLowerCase();
            if (queue == 'deathmatch' ||
                (cachedRounds != null && cachedRounds.isNotEmpty)) {
              matchData = cachedMap;
            }
          }
        }
      } catch (_) {}

      if (matchData == null) {
        matchData = await _remoteDataSource.fetchMatchDetails(
          shard: shard,
          matchId: matchId,
        );
        if (matchData != null) {
          _localStore
              .saveCachedMatchDetails(matchId, jsonEncode(matchData))
              .ignore();
        }
      }

      if (matchData == null) {
        return const Result.failure(
          ServerFailure(message: 'Could not retrieve match details.'),
        );
      }

      final mapsMeta = await _remoteDataSource.fetchMapsMetadata();
      final agentsMeta = await _remoteDataSource.fetchAgentsMetadata();
      final tiersMeta = await _remoteDataSource.fetchCompetitiveTiersMetadata();

      final summary = _parseMatchSummary(
        matchData: matchData,
        currentPuuid: puuid,
        compUpdates: {},
        mapsMeta: mapsMeta,
        agentsMeta: agentsMeta,
        tiersMeta: tiersMeta,
      );

      if (summary != null) {
        return Result.success(summary);
      } else {
        return const Result.failure(
          ServerFailure(message: 'Failed to parse match details.'),
        );
      }
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Error fetching match detail: $e'),
      );
    }
  }
}
