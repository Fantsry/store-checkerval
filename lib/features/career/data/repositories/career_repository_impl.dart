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
            // Silently refresh in background
            _fetchFreshCareerOverview(shard: shard, puuid: puuid).ignore();
            return Result.success(overview);
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

      // Map competitive updates by MatchID
      final compUpdateByMatchId = <String, Map<String, dynamic>>{};
      for (final update in compUpdates) {
        final mId = (update['MatchID'] ?? '').toString();
        if (mId.isNotEmpty) {
          compUpdateByMatchId[mId] = update;
        }
      }

      // Fetch match details for the recent matches in history
      final matchFutures = rawHistory.take(10).map((h) async {
        final matchId = (h['MatchID'] ?? '').toString();
        if (matchId.isEmpty) return null;
        try {
          return await _remoteDataSource.fetchMatchDetails(
            shard: shard,
            matchId: matchId,
          );
        } catch (_) {
          return null;
        }
      });

      final matchDetailsList = await Future.wait(matchFutures);

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
          final seasonalInfo = compQueue['SeasonalInfoBySeasonID'] as Map?;
          if (seasonalInfo != null && seasonalInfo.isNotEmpty) {
            for (final entry in seasonalInfo.entries) {
              final seasonData = entry.value as Map?;
              if (seasonData != null) {
                final rank = (seasonData['Rank'] as num?)?.toInt() ?? 0;
                if (rank > (peakTier ?? 0)) {
                  peakTier = rank;
                }
              }
            }

            // Find current season or latest competitive update
            final latestCompUpdate = mmrData['LatestCompetitiveUpdate'] as Map?;
            if (latestCompUpdate != null) {
              currentTier = (latestCompUpdate['TierAfterUpdate'] as num?)?.toInt() ?? 0;
              currentRR = (latestCompUpdate['RankRatingAfterUpdate'] as num?)?.toInt() ?? 0;
            }
          }
        }
      }

      // If MMR rank wasn't found, try the latest competitive match
      if (currentTier == 0 && compUpdates.isNotEmpty) {
        final firstComp = compUpdates.first;
        currentTier = (firstComp['TierAfterUpdate'] as num?)?.toInt() ?? 0;
        currentRR = (firstComp['RankRatingAfterUpdate'] as num?)?.toInt() ?? 0;
      }

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
      final roundsPlayed = (playerStats['roundsPlayed'] as num?)?.toInt() ?? 0;
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

      if (scoreWon == scoreLost && scoreWon > 0) {
        isDraw = true;
        won = null;
      }

      // Calculate headshots / bodyshots / legshots / damage from roundResults
      int totalHs = 0;
      int totalBs = 0;
      int totalLs = 0;
      int totalDmg = 0;

      final roundResults = (matchData['roundResults'] as List?) ?? [];
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
      final compUpdate = compUpdates[matchId];
      if (compUpdate != null) {
        rrEarned = (compUpdate['RankRatingEarned'] as num?)?.toInt();
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

      final matchData = await _remoteDataSource.fetchMatchDetails(
        shard: shard,
        matchId: matchId,
      );

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
