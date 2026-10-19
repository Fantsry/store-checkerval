import 'dart:convert';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';
import 'package:valorant_store_tracker/features/live_match/data/datasources/live_match_remote_datasource.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:valorant_store_tracker/features/social/data/datasources/riot_chat_remote_datasource.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  final LiveMatchRemoteDataSource _liveDataSource;
  final CareerRemoteDataSource _careerDataSource;
  final ProfileRemoteDataSource _profileDataSource;
  final CareerRepository _careerRepository;
  final SecureStorageService _storage;
  final LocalStoreService _localStore;
  final RiotChatRemoteDataSource _chatDataSource;

  SocialRepositoryImpl({
    required LiveMatchRemoteDataSource liveDataSource,
    required CareerRemoteDataSource careerDataSource,
    required ProfileRemoteDataSource profileDataSource,
    required CareerRepository careerRepository,
    required SecureStorageService storage,
    required LocalStoreService localStore,
    RiotChatRemoteDataSource? chatDataSource,
  })  : _liveDataSource = liveDataSource,
        _careerDataSource = careerDataSource,
        _profileDataSource = profileDataSource,
        _careerRepository = careerRepository,
        _storage = storage,
        _localStore = localStore,
        _chatDataSource = chatDataSource ?? RiotChatRemoteDataSource();

  static String _extractMatchId(Map<String, dynamic>? data) {
    if (data == null) return '';
    final id = data['MatchID'] ??
        data['matchId'] ??
        data['MatchId'] ??
        data['matchID'];
    return id?.toString().trim() ?? '';
  }

  static String _cleanModeName(String modeUrl) {
    final lower = modeUrl.toLowerCase();
    if (lower.contains('competitive')) return 'Competitive';
    if (lower.contains('swiftplay')) return 'Swiftplay';
    if (lower.contains('spikerush')) return 'Spike Rush';
    if (lower.contains('deathmatch')) return 'Deathmatch';
    if (lower.contains('hurm') || lower.contains('teamdeathmatch')) {
      return 'Team Deathmatch';
    }
    if (lower.contains('ggteam') || lower.contains('escalation')) {
      return 'Escalation';
    }
    if (lower.contains('onefa') || lower.contains('replication')) {
      return 'Replication';
    }
    if (lower.contains('snowball')) return 'Snowball Fight';
    if (lower.contains('custom')) return 'Custom Game';
    if (lower.contains('unrated')) return 'Unrated';
    return 'Standard';
  }

  @override
  Future<Result<List<FriendEntity>>> getFriends({bool forceRefresh = false}) async {
    try {
      final selfPuuid = await _storage.getPuuid();
      final rawList = await _localStore.getSavedFriendsJson();
      final List<FriendEntity> friends = [];

      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final friend = FriendEntity.fromJson(map);
          // Purge mock/dummy seed friends automatically
          if (friend.puuid.startsWith('mock-') || friend.puuid.startsWith('player-')) {
            await _localStore.deleteSavedFriend(friend.puuid);
            continue;
          }
          friends.add(friend);
        } catch (_) {}
      }

      // If friends list is empty and user is logged in, attempt syncing real friends
      if (friends.isEmpty && selfPuuid != null && selfPuuid.isNotEmpty) {
        final syncResult = await syncRiotFriends(clearMocks: true);
        if (syncResult.isSuccess &&
            syncResult.valueOrNull != null &&
            syncResult.valueOrNull!.isNotEmpty) {
          return Result.success(syncResult.valueOrNull!);
        }
        return const Result.success([]);
      }

      if (forceRefresh) {
        return await refreshLivePresence();
      }

      return Result.success(friends);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal memuat daftar teman: $e'));
    }
  }

  @override
  Future<Result<List<FriendEntity>>> refreshLivePresence() async {
    try {
      final shard = await _storage.getShard() ?? 'ap';
      final region = await _storage.getRegion() ?? shard;

      final rawList = await _localStore.getSavedFriendsJson();
      final List<FriendEntity> friends = [];

      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          friends.add(FriendEntity.fromJson(map));
        } catch (_) {}
      }

      if (friends.isEmpty) {
        return const Result.success([]);
      }

      // Pre-fetch metadata in parallel
      final metaResults = await Future.wait([
        _careerDataSource.fetchMapsMetadata().catchError((_) => <String, Map<String, dynamic>>{}),
        _careerDataSource.fetchAgentsMetadata().catchError((_) => <String, Map<String, dynamic>>{}),
        _careerDataSource.fetchCompetitiveTiersMetadata().catchError((_) => <int, Map<String, dynamic>>{}),
      ]);

      final mapsMeta = metaResults[0] as Map<String, Map<String, dynamic>>;
      final agentsMeta = metaResults[1] as Map<String, Map<String, dynamic>>;
      final tiersMeta = metaResults[2] as Map<int, Map<String, dynamic>>;

      // Refresh each friend in parallel (capped concurrency if needed)
      final updatedFriends = await Future.wait(
        friends.map((friend) => _refreshSingleFriend(
              friend: friend,
              shard: shard,
              region: region,
              mapsMeta: mapsMeta,
              agentsMeta: agentsMeta,
              tiersMeta: tiersMeta,
            )),
      );

      // Persist updated list
      for (final f in updatedFriends) {
        await _localStore.saveFriendJson(f.puuid, jsonEncode(f.toJson()));
      }

      return Result.success(updatedFriends);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal memperbarui status live: $e'));
    }
  }

  Future<FriendEntity> _refreshSingleFriend({
    required FriendEntity friend,
    required String shard,
    required String region,
    required Map<String, Map<String, dynamic>> mapsMeta,
    required Map<String, Map<String, dynamic>> agentsMeta,
    required Map<int, Map<String, dynamic>> tiersMeta,
  }) async {
    // Purge any legacy mock friend on refresh
    if (friend.puuid.startsWith('mock-') || friend.puuid.startsWith('player-')) {
      await _localStore.deleteSavedFriend(friend.puuid);
      return friend;
    }

    try {
      // 1. Check CoreGame (Live in-match)
      final corePlayer = await _liveDataSource.fetchCoreGamePlayer(
        region: region,
        shard: shard,
        puuid: friend.puuid,
      );
      final coreMatchId = _extractMatchId(corePlayer);

      if (coreMatchId.isNotEmpty) {
        final match = await _liveDataSource.fetchCoreGameMatch(
          region: region,
          shard: shard,
          matchId: coreMatchId,
        );

        if (match != null) {
          final mapUrl = (match['MapID'] ?? '').toString().toLowerCase();
          final modeUrl = (match['ModeID'] ?? '').toString();
          final mapInfo = mapsMeta[mapUrl];
          final mapName = mapInfo?['displayName'] ?? 'Valorant Map';
          final mapSplash = mapInfo?['splash'];
          final modeName = _cleanModeName(modeUrl);

          // Find agent played by friend
          String? agentName;
          String? agentIcon;
          final rawPlayers = match['Players'] is List ? (match['Players'] as List) : const [];
          for (final p in rawPlayers) {
            if (p is Map && (p['Subject'] ?? '').toString() == friend.puuid) {
              final charId = (p['CharacterID'] ?? '').toString().toLowerCase();
              final agentInfo = agentsMeta[charId];
              agentName = agentInfo?['displayName'];
              agentIcon = agentInfo?['displayIcon'];
              break;
            }
          }

          // Parse start time / duration
          DateTime? startTime;
          final rawStartTime = match['GameStartTime'] ?? match['gameStartTime'];
          if (rawStartTime != null) {
            if (rawStartTime is num) {
              startTime = DateTime.fromMillisecondsSinceEpoch(rawStartTime.toInt());
            } else {
              startTime = DateTime.tryParse(rawStartTime.toString());
            }
          }

          return friend.copyWith(
            status: FriendLiveStatus.inGame,
            liveActivity: FriendLiveActivity(
              matchId: coreMatchId,
              mapName: mapName,
              mapSplash: mapSplash,
              modeName: modeName,
              agentName: agentName ?? friend.liveActivity?.agentName,
              agentIcon: agentIcon ?? friend.liveActivity?.agentIcon,
              scoreAlly: friend.liveActivity?.scoreAlly,
              scoreEnemy: friend.liveActivity?.scoreEnemy,
              roundHistory: friend.liveActivity?.roundHistory ?? const [],
              lastRoundOutcome: friend.liveActivity?.lastRoundOutcome,
              lastRoundUpdateTime: friend.liveActivity?.lastRoundUpdateTime,
              gameStartTime: startTime ?? DateTime.now(),
              partySize: rawPlayers.length,
              maxPartySize: 10,
              partyState: 'IN_GAME',
            ),
            lastUpdated: DateTime.now(),
          );
        }
      }

      // 2. Check PreGame (Agent Select)
      final prePlayer = await _liveDataSource.fetchPreGamePlayer(
        region: region,
        shard: shard,
        puuid: friend.puuid,
      );
      final preMatchId = _extractMatchId(prePlayer);

      if (preMatchId.isNotEmpty) {
        final preMatch = await _liveDataSource.fetchPreGameMatch(
          region: region,
          shard: shard,
          matchId: preMatchId,
        );

        if (preMatch != null) {
          final mapUrl = (preMatch['MapID'] ?? '').toString().toLowerCase();
          final modeUrl = (preMatch['ModeID'] ?? '').toString();
          final mapInfo = mapsMeta[mapUrl];
          final mapName = mapInfo?['displayName'] ?? 'Valorant Map';
          final mapSplash = mapInfo?['splash'];
          final modeName = _cleanModeName(modeUrl);

          return friend.copyWith(
            status: FriendLiveStatus.inAgentSelect,
            liveActivity: FriendLiveActivity(
              matchId: preMatchId,
              mapName: mapName,
              mapSplash: mapSplash,
              modeName: modeName,
              agentName: 'Selecting Agent...',
              gameStartTime: DateTime.now(),
              partyState: 'AGENT_SELECT',
            ),
            lastUpdated: DateTime.now(),
          );
        }
      }

      // 3. Neither CoreGame nor PreGame -> In Lobby or Offline
      return friend.copyWith(
        status: FriendLiveStatus.inLobby,
        liveActivity: const FriendLiveActivity(
          partyState: 'OPEN',
          partySize: 1,
          maxPartySize: 5,
        ),
        lastUpdated: DateTime.now(),
      );
    } catch (_) {
      return friend.copyWith(
        status: FriendLiveStatus.offline,
        lastUpdated: DateTime.now(),
      );
    }
  }

  @override
  Future<Result<FriendEntity>> addFriend({
    required String puuid,
    String? gameName,
    String? tagLine,
  }) async {
    try {
      final cleanPuuid = puuid.trim();
      if (cleanPuuid.isEmpty) {
        return const Result.failure(ServerFailure(message: 'PUUID tidak boleh kosong'));
      }

      final shard = await _storage.getShard() ?? 'ap';

      var resolvedName = gameName ?? '';
      var resolvedTag = tagLine ?? '';

      // Fetch name via Name-Service if incomplete
      if (resolvedName.isEmpty) {
        final names = await _liveDataSource.fetchPlayerNames(shard: shard, puuids: [cleanPuuid]);
        if (names.isNotEmpty) {
          resolvedName = names.first['GameName']?.toString() ?? '';
          resolvedTag = names.first['TagLine']?.toString() ?? resolvedTag;
        }
      }

      if (resolvedName.isEmpty) {
        resolvedName = cleanPuuid.length > 8 ? cleanPuuid.substring(0, 8) : 'Agent';
      }

      // Fetch Player Identity & Equipped Card
      final identityRes = await _profileDataSource.fetchPlayerIdentity(
        shard: shard,
        puuid: cleanPuuid,
      );
      final identityMap = identityRes['identity'] as Map<String, dynamic>? ?? {};

      final cardUuid = (identityMap['PlayerCardID'] ??
              identityMap['playerCardId'] ??
              identityMap['cardId'])
          ?.toString();

      var accountLevel = 1;
      final levelRaw = identityMap['AccountLevel'] ?? identityMap['accountLevel'];
      if (levelRaw is num) accountLevel = levelRaw.toInt();

      // Fetch Card Details from Valorant-API
      Map<String, dynamic>? cardData;
      if (cardUuid != null && cardUuid.isNotEmpty && cardUuid != '00000000-0000-0000-0000-000000000000') {
        cardData = await _profileDataSource.fetchPlayerCardDetails(cardUuid);
      }

      // Fetch MMR / Rank
      final mmr = await _liveDataSource.fetchPlayerMmr(shard: shard, puuid: cleanPuuid);
      final tiersMeta = await _careerDataSource
          .fetchCompetitiveTiersMetadata()
          .catchError((_) => <int, Map<String, dynamic>>{});

      int? rankTier;
      String? rankName;
      String? rankIcon;
      int rr = 0;

      if (mmr != null && mmr['QueueSkills'] is Map) {
        final qs = Map<String, dynamic>.from(mmr['QueueSkills'] as Map);
        final comp = qs['competitive'] as Map?;
        if (comp != null) {
          rankTier = (comp['Tier'] as num?)?.toInt();
          rr = (comp['RankedRating'] as num?)?.toInt() ?? 0;
          if (rankTier != null && tiersMeta.containsKey(rankTier)) {
            rankName = tiersMeta[rankTier]?['tierName'];
            rankIcon = tiersMeta[rankTier]?['largeIcon'] ?? tiersMeta[rankTier]?['smallIcon'];
          }
        }
      }

      final friend = FriendEntity(
        puuid: cleanPuuid,
        gameName: resolvedName,
        tagLine: resolvedTag,
        accountLevel: accountLevel,
        cardUuid: cardUuid,
        cardName: cardData?['displayName']?.toString(),
        cardWideArt: cardData?['wideArt']?.toString(),
        cardSmallArt: cardData?['smallArt']?.toString(),
        cardLargeArt: cardData?['largeArt']?.toString(),
        rankTier: rankTier,
        rankName: rankName ?? 'Unranked',
        rankIcon: rankIcon,
        rankedRating: rr,
        status: FriendLiveStatus.inLobby,
        lastUpdated: DateTime.now(),
      );

      await _localStore.saveFriendJson(cleanPuuid, jsonEncode(friend.toJson()));

      return Result.success(friend);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal menambahkan teman: $e'));
    }
  }

  @override
  Future<Result<FriendEntity>> addFriendByRiotId(String riotId) async {
    try {
      final trimmed = riotId.trim();
      final parts = trimmed.split('#');
      final name = parts[0].trim();
      final tag = parts.length > 1 ? parts[1].trim() : '';

      if (name.isEmpty) {
        return const Result.failure(ServerFailure(message: 'Riot ID tidak valid'));
      }

      // Search recent matches for this player's PUUID
      final careerResult = await _careerRepository.getCareerOverview();
      if (careerResult.isSuccess && careerResult.valueOrNull != null) {
        final matches = careerResult.valueOrNull!.matches;
        for (final m in matches) {
          for (final p in m.allPlayers) {
            final pName = p.gameName.toLowerCase().trim();
            final pTag = p.tagLine.toLowerCase().trim();
            if (pName == name.toLowerCase() && (tag.isEmpty || pTag == tag.toLowerCase())) {
              return await addFriend(
                puuid: p.puuid,
                gameName: p.gameName,
                tagLine: p.tagLine,
              );
            }
          }
        }
      }

      // Search Riot remote chat roster if user is authenticated
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final roster = await _chatDataSource.fetchRemoteRoster(accessToken: accessToken);
          for (final item in roster) {
            final rName = item.name.toLowerCase().trim();
            final rTag = (item.tag ?? '').toLowerCase().trim();
            if (rName == name.toLowerCase() && (tag.isEmpty || rTag == tag.toLowerCase())) {
              return await addFriend(
                puuid: item.puuid,
                gameName: item.name,
                tagLine: item.tag,
              );
            }
          }
        } catch (_) {}
      }

      return Result.failure(
        ServerFailure(
          message:
              'Pemain "$trimmed" tidak ditemukan di riwayat pertandingan atau daftar teman Riot Anda. Pastikan Riot ID sudah benar (format: Name#Tag).',
        ),
      );
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal menambahkan teman: $e'));
    }
  }

  @override
  Future<Result<void>> removeFriend(String puuid) async {
    try {
      await _localStore.deleteSavedFriend(puuid);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal menghapus teman: $e'));
    }
  }

  @override
  Future<Result<FriendEntity>> toggleFavorite(String puuid) async {
    try {
      final rawList = await _localStore.getSavedFriendsJson();
      for (final raw in rawList) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if (map['puuid'] == puuid) {
          final friend = FriendEntity.fromJson(map);
          final updated = friend.copyWith(isFavorite: !friend.isFavorite);
          await _localStore.saveFriendJson(puuid, jsonEncode(updated.toJson()));
          return Result.success(updated);
        }
      }
      return const Result.failure(ServerFailure(message: 'Teman tidak ditemukan'));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal mengubah status favorit: $e'));
    }
  }

  @override
  Future<Result<List<FriendEntity>>> importRecentTeammates() async {
    try {
      final selfPuuid = await _storage.getPuuid() ?? '';
      final shard = await _storage.getShard() ?? 'ap';

      final careerResult = await _careerRepository.getCareerOverview();
      if (!careerResult.isSuccess || careerResult.valueOrNull == null) {
        return const Result.success([]);
      }

      final matches = careerResult.valueOrNull!.matches;
      final existingFriends = await _localStore.getSavedFriendsJson();
      final existingPuuids = <String>{};
      for (final raw in existingFriends) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          existingPuuids.add(map['puuid']?.toString() ?? '');
        } catch (_) {}
      }

      final Map<String, MatchPlayerSummary> teammatesMap = {};
      for (final m in matches) {
        for (final t in m.teammates) {
          if (t.puuid.isNotEmpty && t.puuid != selfPuuid && !t.isSelf && !existingPuuids.contains(t.puuid)) {
            teammatesMap[t.puuid] = t;
          }
        }
      }

      if (teammatesMap.isEmpty) {
        return const Result.success([]);
      }

      final List<FriendEntity> newFriends = [];
      for (final entry in teammatesMap.entries.take(8)) {
        final t = entry.value;

        // Fetch card identity
        Map<String, dynamic>? cardData;
        try {
          final identityRes = await _profileDataSource.fetchPlayerIdentity(shard: shard, puuid: t.puuid);
          final idMap = identityRes['identity'] as Map<String, dynamic>? ?? {};
          final cardUuid = (idMap['PlayerCardID'] ?? idMap['playerCardId'])?.toString();
          if (cardUuid != null && cardUuid.isNotEmpty) {
            cardData = await _profileDataSource.fetchPlayerCardDetails(cardUuid);
          }
        } catch (_) {}

        final friend = FriendEntity(
          puuid: t.puuid,
          gameName: t.gameName.isNotEmpty ? t.gameName : 'Teammate',
          tagLine: t.tagLine,
          accountLevel: 1,
          cardUuid: cardData?['uuid']?.toString(),
          cardName: cardData?['displayName']?.toString() ?? 'Player Card',
          cardWideArt: cardData?['wideArt']?.toString() ?? 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/wideart.png',
          cardSmallArt: cardData?['smallArt']?.toString() ?? 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/smallart.png',
          cardLargeArt: cardData?['largeArt']?.toString(),
          rankTier: t.competitiveTier,
          rankName: t.rankName ?? 'Unranked',
          rankIcon: t.rankIconUrl,
          rankedRating: 25,
          status: FriendLiveStatus.inLobby,
          lastUpdated: DateTime.now(),
        );

        await _localStore.saveFriendJson(friend.puuid, jsonEncode(friend.toJson()));
        newFriends.add(friend);
      }

      return Result.success(newFriends);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal mengimpor rekan tim: $e'));
    }
  }

  @override
  Future<List<MatchPlayerSummary>> getRecentAvailableTeammates() async {
    try {
      final selfPuuid = await _storage.getPuuid() ?? '';
      final careerResult = await _careerRepository.getCareerOverview();
      if (!careerResult.isSuccess || careerResult.valueOrNull == null) {
        return const [];
      }

      final existingFriends = await _localStore.getSavedFriendsJson();
      final existingPuuids = <String>{};
      for (final raw in existingFriends) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          existingPuuids.add(map['puuid']?.toString() ?? '');
        } catch (_) {}
      }

      final Map<String, MatchPlayerSummary> teammates = {};
      for (final m in careerResult.valueOrNull!.matches) {
        for (final t in m.teammates) {
          if (t.puuid.isNotEmpty && t.puuid != selfPuuid && !t.isSelf && !existingPuuids.contains(t.puuid)) {
            teammates[t.puuid] = t;
          }
        }
      }

      return teammates.values.toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Result<FriendEntity>> updateFriendRound({
    required String puuid,
    required bool isAllyWon,
  }) async {
    try {
      final rawList = await _localStore.getSavedFriendsJson();
      final List<FriendEntity> friends = [];
      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          friends.add(FriendEntity.fromJson(map));
        } catch (_) {}
      }

      final idx = friends.indexWhere((f) => f.puuid == puuid);
      if (idx == -1) {
        return const Result.failure(ServerFailure(message: 'Teman tidak ditemukan'));
      }

      final friend = friends[idx];
      final currentActivity = friend.liveActivity ?? const FriendLiveActivity();
      final currentAllyScore = currentActivity.scoreAlly ?? 0;
      final currentEnemyScore = currentActivity.scoreEnemy ?? 0;

      final newAllyScore = isAllyWon ? currentAllyScore + 1 : currentAllyScore;
      final newEnemyScore = isAllyWon ? currentEnemyScore : currentEnemyScore + 1;
      final newHistory = List<bool>.from(currentActivity.roundHistory)..add(isAllyWon);

      final updatedActivity = currentActivity.copyWith(
        scoreAlly: newAllyScore,
        scoreEnemy: newEnemyScore,
        roundHistory: newHistory,
        lastRoundOutcome: isAllyWon ? 'ALLY_WON' : 'ENEMY_WON',
        lastRoundUpdateTime: DateTime.now(),
      );

      final updatedFriend = friend.copyWith(
        status: FriendLiveStatus.inGame,
        liveActivity: updatedActivity,
        lastUpdated: DateTime.now(),
      );

      await _localStore.saveFriendJson(
        updatedFriend.puuid,
        jsonEncode(updatedFriend.toJson()),
      );

      return Result.success(updatedFriend);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal memperbarui round: $e'));
    }
  }

  @override
  Future<Result<List<FriendEntity>>> syncRiotFriends({bool clearMocks = true}) async {
    try {
      final accessToken = await _storage.getAccessToken();
      final selfPuuid = await _storage.getPuuid() ?? '';
      final shard = await _storage.getShard() ?? 'ap';

      if (clearMocks) {
        await clearMockFriends();
      }

      final List<FriendEntity> realFriends = [];

      // ─── Method 1: Riot XMPP Remote Chat Service (Real Friends Roster) ───────
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final roster = await _chatDataSource.fetchRemoteRoster(accessToken: accessToken);
          if (roster.isNotEmpty) {
            final List<String> puuidsToResolve = [];
            final Map<String, RiotFriendRosterItem> rosterMap = {};

            for (final item in roster) {
              if (item.puuid.isNotEmpty && item.puuid != selfPuuid) {
                rosterMap[item.puuid] = item;
                puuidsToResolve.add(item.puuid);
              }
            }

            // Pre-fetch player names via Riot GLZ Name-Service
            Map<String, Map<String, String>> resolvedNames = {};
            try {
              final namesList = await _liveDataSource.fetchPlayerNames(
                shard: shard,
                puuids: puuidsToResolve,
              );
              for (final n in namesList) {
                final sub = (n['Subject'] ?? '').toString();
                resolvedNames[sub] = {
                  'gameName': (n['GameName'] ?? '').toString(),
                  'tagLine': (n['TagLine'] ?? '').toString(),
                };
              }
            } catch (_) {}

            final tiersMeta = await _careerDataSource
                .fetchCompetitiveTiersMetadata()
                .catchError((_) => <int, Map<String, dynamic>>{});

            for (final puuid in puuidsToResolve) {
              final rosterItem = rosterMap[puuid];
              final nameInfo = resolvedNames[puuid];

              var gameName = nameInfo?['gameName'] ?? '';
              var tagLine = nameInfo?['tagLine'] ?? '';

              if (gameName.isEmpty) {
                gameName = rosterItem?.name ?? '';
                tagLine = rosterItem?.tag ?? '';
              }
              if (gameName.isEmpty) {
                gameName = puuid.length > 8 ? puuid.substring(0, 8) : 'Friend';
              }

              // Fetch Equipped Card Banner & Account Level
              Map<String, dynamic>? cardData;
              int accountLevel = 1;
              String? cardUuid;
              try {
                final idRes = await _profileDataSource.fetchPlayerIdentity(shard: shard, puuid: puuid);
                final idMap = idRes['identity'] as Map<String, dynamic>? ?? {};
                cardUuid = (idMap['PlayerCardID'] ?? idMap['playerCardId'])?.toString();
                final lvl = idMap['AccountLevel'] ?? idMap['accountLevel'];
                if (lvl is num) accountLevel = lvl.toInt();
                if (cardUuid != null && cardUuid.isNotEmpty && cardUuid != '00000000-0000-0000-0000-000000000000') {
                  cardData = await _profileDataSource.fetchPlayerCardDetails(cardUuid);
                }
              } catch (_) {}

              // Fetch MMR & Rank
              int? rankTier;
              String? rankName;
              String? rankIcon;
              int rr = 0;
              try {
                final mmr = await _liveDataSource.fetchPlayerMmr(shard: shard, puuid: puuid);
                if (mmr != null && mmr['QueueSkills'] is Map) {
                  final qs = Map<String, dynamic>.from(mmr['QueueSkills'] as Map);
                  final comp = qs['competitive'] as Map?;
                  if (comp != null) {
                    rankTier = (comp['Tier'] as num?)?.toInt();
                    rr = (comp['RankedRating'] as num?)?.toInt() ?? 0;
                    if (rankTier != null && tiersMeta.containsKey(rankTier)) {
                      rankName = tiersMeta[rankTier]?['tierName'];
                      rankIcon = tiersMeta[rankTier]?['largeIcon'] ?? tiersMeta[rankTier]?['smallIcon'];
                    }
                  }
                }
              } catch (_) {}

              final friend = FriendEntity(
                puuid: puuid,
                gameName: gameName,
                tagLine: tagLine,
                accountLevel: accountLevel,
                cardUuid: cardUuid,
                cardName: cardData?['displayName']?.toString() ?? 'Player Card',
                cardWideArt: cardData?['wideArt']?.toString() ??
                    (cardUuid != null && cardUuid.isNotEmpty
                        ? 'https://media.valorant-api.com/playercards/$cardUuid/wideart.png'
                        : 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/wideart.png'),
                cardSmallArt: cardData?['smallArt']?.toString() ??
                    (cardUuid != null && cardUuid.isNotEmpty
                        ? 'https://media.valorant-api.com/playercards/$cardUuid/smallart.png'
                        : 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/smallart.png'),
                cardLargeArt: cardData?['largeArt']?.toString(),
                rankTier: rankTier,
                rankName: rankName ?? 'Unranked',
                rankIcon: rankIcon,
                rankedRating: rr,
                status: FriendLiveStatus.inLobby,
                lastUpdated: DateTime.now(),
              );

              await _localStore.saveFriendJson(puuid, jsonEncode(friend.toJson()));
              realFriends.add(friend);
            }
          }
        } catch (_) {}
      }

      // ─── Method 2: Match Teammates Fallback ────────────────────────────────
      if (realFriends.isEmpty) {
        final imported = await importRecentTeammates();
        if (imported.isSuccess && imported.valueOrNull != null && imported.valueOrNull!.isNotEmpty) {
          realFriends.addAll(imported.valueOrNull!);
        }
      }

      // ─── Method 3: Poll Live Match Presence for all Discovered Friends ────
      if (realFriends.isNotEmpty) {
        final refreshed = await refreshLivePresence();
        if (refreshed.isSuccess && refreshed.valueOrNull != null && refreshed.valueOrNull!.isNotEmpty) {
          return Result.success(refreshed.valueOrNull!);
        }
      }

      return Result.success(realFriends);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal menyinkronkan teman: $e'));
    }
  }

  @override
  Future<Result<void>> clearMockFriends() async {
    try {
      final rawList = await _localStore.getSavedFriendsJson();
      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final puuid = map['puuid']?.toString() ?? '';
          if (puuid.startsWith('mock-') || puuid.startsWith('player-')) {
            await _localStore.deleteSavedFriend(puuid);
          }
        } catch (_) {}
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal membersihkan data dummy: $e'));
    }
  }

  @override
  Future<Result<List<FriendEntity>>> loadDemoSquad() async {
    try {
      await clearMockFriends();
      // Import real teammates from match history instead of fake mock players
      final importResult = await importRecentTeammates();
      if (importResult.isSuccess && importResult.valueOrNull != null && importResult.valueOrNull!.isNotEmpty) {
        return importResult;
      }
      return await getFriends(forceRefresh: true);
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Gagal memuat rekan tim: $e'));
    }
  }
}
