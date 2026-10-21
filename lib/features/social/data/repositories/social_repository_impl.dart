import 'dart:convert';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/core/utils/competitive_rank_helper.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';
import 'package:valorant_store_tracker/features/live_match/data/datasources/live_match_remote_datasource.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:valorant_store_tracker/features/social/data/datasources/riot_chat_remote_datasource.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/chat_message.dart';
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
  }) : _liveDataSource = liveDataSource,
       _careerDataSource = careerDataSource,
       _profileDataSource = profileDataSource,
       _careerRepository = careerRepository,
       _storage = storage,
       _localStore = localStore,
       _chatDataSource = chatDataSource ?? RiotChatRemoteDataSource();

  Future<String?> _fetchActiveSeasonId() async {
    try {
      final seasons = await _careerDataSource.fetchSeasonsMetadata();
      return CompetitiveRankHelper.resolveActiveAct(seasons)?.id;
    } catch (_) {
      return null;
    }
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

  static String _cleanMapName(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('duality')) return 'Bind';
    if (lower.contains('bonsai')) return 'Split';
    if (lower.contains('ascent')) return 'Ascent';
    if (lower.contains('triad')) return 'Haven';
    if (lower.contains('foxtrot')) return 'Breeze';
    if (lower.contains('canyon')) return 'Fracture';
    if (lower.contains('pitt')) return 'Pearl';
    if (lower.contains('jam')) return 'Lotus';
    if (lower.contains('jules')) return 'Sunset';
    if (lower.contains('corrode') || lower.contains('infinity')) {
      return 'Corrode';
    }
    if (lower.contains('hurm')) return 'Team Deathmatch';
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : 'Valorant';
  }

  @override
  Future<Result<List<FriendEntity>>> getFriends({
    bool forceRefresh = false,
  }) async {
    try {
      final selfPuuid = await _storage.getPuuid();
      final rawList = await _localStore.getSavedFriendsJson();
      final List<FriendEntity> friends = [];

      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final friend = FriendEntity.fromJson(map);
          // Purge mock/dummy seed friends automatically
          if (friend.puuid.startsWith('mock-') ||
              friend.puuid.startsWith('player-')) {
            await _localStore.deleteSavedFriend(friend.puuid);
            continue;
          }
          friends.add(friend);
        } catch (_) {}
      }

      // If user is authenticated, sync real friends from Riot XMPP
      if (selfPuuid != null && selfPuuid.isNotEmpty) {
        if (friends.isEmpty || forceRefresh) {
          final syncResult = await syncRiotFriends(clearMocks: true);
          if (syncResult.isSuccess && syncResult.valueOrNull != null) {
            return syncResult;
          }
        }
      }

      return Result.success(friends);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Gagal memuat daftar teman: $e'),
      );
    }
  }

  @override
  Future<Result<List<FriendEntity>>> refreshLivePresence() async {
    try {
      final accessToken = await _storage.getAccessToken();
      final selfPuuid = await _storage.getPuuid();

      // If user is logged in, perform live XMPP sync to refresh real-time presence
      if (selfPuuid != null &&
          selfPuuid.isNotEmpty &&
          accessToken != null &&
          accessToken.isNotEmpty) {
        final syncResult = await syncRiotFriends(clearMocks: false);
        if (syncResult.isSuccess && syncResult.valueOrNull != null) {
          return syncResult;
        }
      }

      final rawList = await _localStore.getSavedFriendsJson();
      final List<FriendEntity> friends = [];
      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final friend = FriendEntity.fromJson(map);
          if (!friend.puuid.startsWith('mock-') &&
              !friend.puuid.startsWith('player-')) {
            friends.add(friend);
          }
        } catch (_) {}
      }

      return Result.success(friends);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Gagal memperbarui status live: $e'),
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
        return const Result.failure(
          ServerFailure(message: 'PUUID tidak boleh kosong'),
        );
      }

      final shard = await _storage.getShard() ?? 'ap';

      var resolvedName = gameName ?? '';
      var resolvedTag = tagLine ?? '';

      // Fetch name via Name-Service if incomplete
      if (resolvedName.isEmpty) {
        final names = await _liveDataSource.fetchPlayerNames(
          shard: shard,
          puuids: [cleanPuuid],
        );
        if (names.isNotEmpty) {
          resolvedName = names.first['GameName']?.toString() ?? '';
          resolvedTag = names.first['TagLine']?.toString() ?? resolvedTag;
        }
      }

      if (resolvedName.isEmpty) {
        resolvedName = cleanPuuid.length > 8
            ? cleanPuuid.substring(0, 8)
            : 'Agent';
      }

      // Fetch Player Identity & Equipped Card
      final identityRes = await _profileDataSource.fetchPlayerIdentity(
        shard: shard,
        puuid: cleanPuuid,
      );
      final identityMap =
          identityRes['identity'] as Map<String, dynamic>? ?? {};

      final cardUuid =
          (identityMap['PlayerCardID'] ??
                  identityMap['playerCardId'] ??
                  identityMap['cardId'])
              ?.toString();

      var accountLevel = 1;
      final levelRaw =
          identityMap['AccountLevel'] ?? identityMap['accountLevel'];
      if (levelRaw is num) accountLevel = levelRaw.toInt();

      // Fetch Card Details from Valorant-API
      Map<String, dynamic>? cardData;
      if (cardUuid != null &&
          cardUuid.isNotEmpty &&
          cardUuid != '00000000-0000-0000-0000-000000000000') {
        cardData = await _profileDataSource.fetchPlayerCardDetails(cardUuid);
      }

      // Fetch MMR / Rank
      final mmr = await _liveDataSource.fetchPlayerMmr(
        shard: shard,
        puuid: cleanPuuid,
      );
      final tiersMeta = await _careerDataSource
          .fetchCompetitiveTiersMetadata()
          .catchError((_) => <int, Map<String, dynamic>>{});

      final activeSeasonId = await _fetchActiveSeasonId();
      final ranked = CompetitiveRankHelper.resolveCurrentRank(
        mmr: mmr,
        activeSeasonId: activeSeasonId,
      );
      final int? rankTier = ranked.isRanked ? ranked.tier : null;
      final int rr = ranked.rating;
      String? rankName;
      String? rankIcon;
      if (rankTier != null && tiersMeta.containsKey(rankTier)) {
        rankName = tiersMeta[rankTier]?['tierName'];
        rankIcon =
            tiersMeta[rankTier]?['largeIcon'] ??
            tiersMeta[rankTier]?['smallIcon'];
      }
      if (ranked.isPlacement) rankName = 'Placement';

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
      return Result.failure(
        ServerFailure(message: 'Gagal menambahkan teman: $e'),
      );
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
        return const Result.failure(
          ServerFailure(message: 'Riot ID tidak valid'),
        );
      }

      // Search recent matches for this player's PUUID
      final careerResult = await _careerRepository.getCareerOverview();
      if (careerResult.isSuccess && careerResult.valueOrNull != null) {
        final matches = careerResult.valueOrNull!.matches;
        for (final m in matches) {
          for (final p in m.allPlayers) {
            final pName = p.gameName.toLowerCase().trim();
            final pTag = p.tagLine.toLowerCase().trim();
            if (pName == name.toLowerCase() &&
                (tag.isEmpty || pTag == tag.toLowerCase())) {
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
          final roster = await _chatDataSource.fetchRemoteRoster(
            accessToken: accessToken,
          );
          for (final item in roster) {
            final rName = item.name.toLowerCase().trim();
            final rTag = (item.tag ?? '').toLowerCase().trim();
            if (rName == name.toLowerCase() &&
                (tag.isEmpty || rTag == tag.toLowerCase())) {
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
      return Result.failure(
        ServerFailure(message: 'Gagal menambahkan teman: $e'),
      );
    }
  }

  @override
  Future<Result<void>> removeFriend(String puuid) async {
    try {
      await _localStore.deleteSavedFriend(puuid);
      await _localStore.clearChatMessages(puuid);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Gagal menghapus teman: $e'),
      );
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
      return const Result.failure(
        ServerFailure(message: 'Teman tidak ditemukan'),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Gagal mengubah status favorit: $e'),
      );
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
          if (t.puuid.isNotEmpty &&
              t.puuid != selfPuuid &&
              !t.isSelf &&
              !existingPuuids.contains(t.puuid)) {
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

        // Fetch card identity and account level
        Map<String, dynamic>? cardData;
        var accountLevel = 1;
        try {
          final identityRes = await _profileDataSource.fetchPlayerIdentity(
            shard: shard,
            puuid: t.puuid,
          );
          final idMap = identityRes['identity'] as Map<String, dynamic>? ?? {};
          final level = idMap['AccountLevel'] ?? idMap['accountLevel'];
          if (level is num) accountLevel = level.toInt();
          final cardUuid = (idMap['PlayerCardID'] ?? idMap['playerCardId'])
              ?.toString();
          if (cardUuid != null && cardUuid.isNotEmpty) {
            cardData = await _profileDataSource.fetchPlayerCardDetails(
              cardUuid,
            );
          }
        } catch (_) {}

        final friend = FriendEntity(
          puuid: t.puuid,
          gameName: t.gameName.isNotEmpty ? t.gameName : 'Teammate',
          tagLine: t.tagLine,
          accountLevel: accountLevel,
          cardUuid: cardData?['uuid']?.toString(),
          cardName: cardData?['displayName']?.toString() ?? 'Player Card',
          cardWideArt:
              cardData?['wideArt']?.toString() ??
              'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/wideart.png',
          cardSmallArt:
              cardData?['smallArt']?.toString() ??
              'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/smallart.png',
          cardLargeArt: cardData?['largeArt']?.toString(),
          rankTier: t.competitiveTier,
          rankName: t.rankName ?? 'Unranked',
          rankIcon: t.rankIconUrl,
          rankedRating: 0,
          status: FriendLiveStatus.offline,
          lastUpdated: DateTime.now(),
        );

        await _localStore.saveFriendJson(
          friend.puuid,
          jsonEncode(friend.toJson()),
        );
        newFriends.add(friend);
      }

      return Result.success(newFriends);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Gagal mengimpor rekan tim: $e'),
      );
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
          if (t.puuid.isNotEmpty &&
              t.puuid != selfPuuid &&
              !t.isSelf &&
              !existingPuuids.contains(t.puuid)) {
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
        return const Result.failure(
          ServerFailure(message: 'Teman tidak ditemukan'),
        );
      }

      final friend = friends[idx];
      final currentActivity = friend.liveActivity ?? const FriendLiveActivity();
      final currentAllyScore = currentActivity.scoreAlly ?? 0;
      final currentEnemyScore = currentActivity.scoreEnemy ?? 0;

      final newAllyScore = isAllyWon ? currentAllyScore + 1 : currentAllyScore;
      final newEnemyScore = isAllyWon
          ? currentEnemyScore
          : currentEnemyScore + 1;
      final newHistory = List<bool>.from(currentActivity.roundHistory)
        ..add(isAllyWon);

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
      return Result.failure(
        ServerFailure(message: 'Gagal memperbarui round: $e'),
      );
    }
  }

  @override
  Future<Result<List<FriendEntity>>> syncRiotFriends({
    bool clearMocks = true,
  }) async {
    try {
      final accessToken = await _storage.getAccessToken();
      final selfPuuid = await _storage.getPuuid() ?? '';
      final shard = await _storage.getShard() ?? 'ap';

      final entitlementToken = await _storage.getEntitlementsToken();

      if (clearMocks) {
        await clearMockFriends();
      }

      final List<FriendEntity> realFriends = [];

      // ─── Method 1: Riot XMPP Remote Chat Service (Real Friends & Presences) ───
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final socialData = await _chatDataSource.fetchRemoteSocialData(
            accessToken: accessToken,
            entitlementToken: entitlementToken,
          );
          for (final incoming in socialData.messages) {
            if (incoming.senderPuuid == selfPuuid) continue;
            try {
              await _localStore.saveChatMessage(
                incoming.senderPuuid,
                ChatMessageEntity(
                  id: incoming.id,
                  body: incoming.body,
                  timestamp: incoming.timestamp,
                  isMine: false,
                  status: ChatMessageStatus.sent,
                ),
              );
            } catch (_) {}
          }

          if (selfPuuid.isNotEmpty &&
              await _localStore.getLastNotifiedChatAt(selfPuuid) == null) {
            await _localStore.setLastNotifiedChatAt(selfPuuid, DateTime.now());
          }

          final roster = socialData.roster;
          if (roster.isNotEmpty) {
            final List<String> puuidsToResolve = [];
            final Map<String, RiotFriendRosterItem> rosterMap = {};

            for (final item in roster) {
              if (item.puuid.isNotEmpty && item.puuid != selfPuuid) {
                rosterMap[item.puuid] = item;
                puuidsToResolve.add(item.puuid);
              }
            }

            // A partial XMPP roster is not proof that a real friend was
            // removed, so only deliberately seeded mock entries are purged.
            if (clearMocks) {
              await clearMockFriends();
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

            final metaResults = await Future.wait([
              _careerDataSource.fetchMapsMetadata().catchError(
                (_) => <String, Map<String, dynamic>>{},
              ),
              _careerDataSource.fetchAgentsMetadata().catchError(
                (_) => <String, Map<String, dynamic>>{},
              ),
              _careerDataSource.fetchCompetitiveTiersMetadata().catchError(
                (_) => <int, Map<String, dynamic>>{},
              ),
            ]);
            final mapsMeta =
                metaResults[0] as Map<String, Map<String, dynamic>>;
            final tiersMeta = metaResults[2] as Map<int, Map<String, dynamic>>;
            final activeSeasonId = await _fetchActiveSeasonId();

            for (final puuid in puuidsToResolve) {
              final rosterItem = rosterMap[puuid];
              final nameInfo = resolvedNames[puuid];
              final presence = socialData.presences[puuid];

              var gameName = nameInfo?['gameName'] ?? '';
              var tagLine = nameInfo?['tagLine'] ?? '';

              if (gameName.isEmpty) {
                gameName = rosterItem?.name ?? '';
                tagLine = rosterItem?.tag ?? '';
              }
              if (gameName.isEmpty) {
                gameName = puuid.length > 8 ? puuid.substring(0, 8) : 'Friend';
              }

              // Determine status and live activity from real-time presence
              FriendLiveStatus status = FriendLiveStatus.offline;
              FriendLiveActivity? liveActivity;
              String clientActivity = 'Offline';
              bool isMobile = false;

              if (presence != null) {
                clientActivity = presence.clientActivity;
                isMobile = presence.isMobile;

                if (presence.isInGame) {
                  status = FriendLiveStatus.inGame;
                  final mapName =
                      mapsMeta[presence.matchMap
                          ?.toLowerCase()]?['displayName'] ??
                      _cleanMapName(presence.matchMap ?? '');
                  final modeName = _cleanModeName(presence.queueId ?? '');
                  liveActivity = FriendLiveActivity(
                    mapName: mapName,
                    modeName: modeName,
                    scoreAlly: presence.scoreAlly,
                    scoreEnemy: presence.scoreEnemy,
                    partySize: presence.partySize,
                    maxPartySize: presence.maxPartySize,
                    gameStartTime: DateTime.now(),
                  );
                } else if (presence.isInPreGame) {
                  status = FriendLiveStatus.inAgentSelect;
                } else if (presence.isAway) {
                  status = FriendLiveStatus.away;
                } else if (presence.isOnline) {
                  status = FriendLiveStatus.inLobby;
                } else {
                  status = FriendLiveStatus.offline;
                }
              }

              // Fetch Equipped Card Banner & Account Level
              Map<String, dynamic>? cardData;
              int accountLevel = presence?.accountLevel ?? 1;
              String? cardUuid = presence?.playerCardId;
              try {
                if (cardUuid == null || cardUuid.isEmpty) {
                  final idRes = await _profileDataSource.fetchPlayerIdentity(
                    shard: shard,
                    puuid: puuid,
                  );
                  final idMap =
                      idRes['identity'] as Map<String, dynamic>? ?? {};
                  cardUuid = (idMap['PlayerCardID'] ?? idMap['playerCardId'])
                      ?.toString();
                  final lvl = idMap['AccountLevel'] ?? idMap['accountLevel'];
                  if (lvl is num) accountLevel = lvl.toInt();
                }
                if (cardUuid != null &&
                    cardUuid.isNotEmpty &&
                    cardUuid != '00000000-0000-0000-0000-000000000000') {
                  cardData = await _profileDataSource.fetchPlayerCardDetails(
                    cardUuid,
                  );
                }
              } catch (_) {}

              // Rank & MMR. Presence only carries tier; the act-aware RR must
              // always come from the MMR endpoint so friends do not show 0 RR.
              int? rankTier = presence?.competitiveTier;
              String? rankName;
              String? rankIcon;
              int rr = 0;
              var isPlacement = false;
              try {
                final mmr = await _liveDataSource.fetchPlayerMmr(
                  shard: shard,
                  puuid: puuid,
                );
                final ranked = CompetitiveRankHelper.resolveCurrentRank(
                  mmr: mmr,
                  activeSeasonId: activeSeasonId,
                );
                if (ranked.hasCurrentActData) {
                  rankTier = ranked.isRanked ? ranked.tier : null;
                  rr = ranked.rating;
                  isPlacement = ranked.isPlacement;
                }
              } catch (_) {}

              if (rankTier != null &&
                  rankTier > 0 &&
                  tiersMeta.containsKey(rankTier)) {
                rankName = tiersMeta[rankTier]?['tierName'];
                rankIcon =
                    tiersMeta[rankTier]?['largeIcon'] ??
                    tiersMeta[rankTier]?['smallIcon'];
              }
              if (isPlacement) rankName = 'Placement';

              var lastChatMessage =
                  socialData.recentMessages[puuid]?.body;
              var lastChatTimestamp =
                  socialData.recentMessages[puuid]?.timestamp;
              try {
                final localHistory =
                    await _localStore.getChatMessages(puuid);
                if (localHistory.isNotEmpty) {
                  final latest = localHistory.last;
                  if (lastChatTimestamp == null ||
                      !latest.timestamp.isBefore(lastChatTimestamp)) {
                    lastChatMessage = latest.body;
                    lastChatTimestamp = latest.timestamp;
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
                cardWideArt:
                    cardData?['wideArt']?.toString() ??
                    (cardUuid != null && cardUuid.isNotEmpty
                        ? 'https://media.valorant-api.com/playercards/$cardUuid/wideart.png'
                        : 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/wideart.png'),
                cardSmallArt:
                    cardData?['smallArt']?.toString() ??
                    (cardUuid != null && cardUuid.isNotEmpty
                        ? 'https://media.valorant-api.com/playercards/$cardUuid/smallart.png'
                        : 'https://media.valorant-api.com/playercards/9fb348bc-41a0-91ad-8a3e-818035c4e561/smallart.png'),
                cardLargeArt: cardData?['largeArt']?.toString(),
                rankTier: rankTier,
                rankName: rankName ?? 'Unranked',
                rankIcon: rankIcon,
                rankedRating: rr,
                status: status,
                liveActivity: liveActivity,
                clientActivity: clientActivity,
                isMobile: isMobile,
                lastChatMessage: lastChatMessage,
                lastChatTimestamp: lastChatTimestamp,
                xmppJid: rosterItem?.jid,
                lastUpdated: DateTime.now(),
              );

              await _localStore.saveFriendJson(
                puuid,
                jsonEncode(friend.toJson()),
              );
              realFriends.add(friend);
            }
          }
        } catch (_) {}
      }

      // Return real friends synced from Riot XMPP
      if (realFriends.isNotEmpty) {
        return Result.success(realFriends);
      }

      // If XMPP returned no friends (e.g. offline/network failure), return cached real friends
      final rawList = await _localStore.getSavedFriendsJson();
      final List<FriendEntity> cached = [];
      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final friend = FriendEntity.fromJson(map);
          if (!friend.puuid.startsWith('mock-') &&
              !friend.puuid.startsWith('player-')) {
            cached.add(friend);
          }
        } catch (_) {}
      }

      return Result.success(cached);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Gagal menyinkronkan teman: $e'),
      );
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
      return Result.failure(
        ServerFailure(message: 'Gagal membersihkan data dummy: $e'),
      );
    }
  }

  @override
  Future<Result<List<ChatMessageEntity>>> getChatMessages(
    String puuid,
  ) async {
    try {
      final messages = await _localStore.getChatMessages(puuid);
      return Result.success(messages);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Gagal memuat riwayat chat: $e'),
      );
    }
  }

  @override
  Future<Result<ChatMessageEntity>> sendChatMessage({
    required String puuid,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const Result.failure(
        ServerFailure(message: 'Pesan tidak boleh kosong'),
      );
    }
    if (trimmed.length > 500) {
      return const Result.failure(
        ServerFailure(message: 'Pesan maksimal 500 karakter'),
      );
    }

    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return const Result.failure(
          AuthFailure(message: 'Sesi berakhir, silakan login ulang'),
        );
      }
      final entitlementToken = await _storage.getEntitlementsToken();

      FriendEntity? friend;
      final rawFriend = await _localStore.getSavedFriendJson(puuid);
      if (rawFriend != null && rawFriend.isNotEmpty) {
        try {
          friend = FriendEntity.fromJson(
            jsonDecode(rawFriend) as Map<String, dynamic>,
          );
        } catch (_) {}
      }

      final rosterJid = friend?.xmppJid?.trim() ?? '';
      final recipientJid =
          rosterJid.isNotEmpty ? rosterJid : '$puuid@pvp.net';

      final sendResult = await _chatDataSource.sendChatMessage(
        accessToken: accessToken,
        entitlementToken: entitlementToken,
        recipientJid: recipientJid,
        body: trimmed,
      );

      if (!sendResult.isSuccess) {
        return Result.failure(
          ServerFailure(
            message: sendResult.error ?? 'Gagal mengirim pesan',
          ),
        );
      }

      final timestamp = DateTime.now();
      final message = ChatMessageEntity(
        id: sendResult.messageId ??
            'local-${timestamp.microsecondsSinceEpoch}',
        body: trimmed,
        timestamp: timestamp,
        isMine: true,
        status: ChatMessageStatus.sent,
      );

      try {
        await _localStore.saveChatMessage(puuid, message);
        if (friend != null) {
          await _localStore.saveFriendJson(
            puuid,
            jsonEncode(
              friend.copyWith(
                lastChatMessage: trimmed,
                lastChatTimestamp: timestamp,
                lastUpdated: timestamp,
              ).toJson(),
            ),
          );
        }
      } catch (_) {}

      return Result.success(message);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Gagal mengirim pesan: $e'),
      );
    }
  }

  @override
  Future<Map<String, int>> getUnreadChatCounts() async {
    final counts = <String, int>{};
    final now = DateTime.now();
    final rawList = await _localStore.getSavedFriendsJson();

    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final puuid = map['puuid']?.toString() ?? '';
        if (puuid.isEmpty) continue;

        final history = await _localStore.getChatMessages(puuid);
        if (history.isEmpty) continue;

        final lastReadId = await _localStore.getLastReadChatMessageId(puuid);
        final lastReadIndex = lastReadId == null
            ? -1
            : history.indexWhere((message) => message.id == lastReadId);

        var unread = 0;
        for (var i = lastReadIndex + 1; i < history.length; i++) {
          final message = history[i];
          if (message.isMine) continue;
          if (lastReadId == null &&
              now.difference(message.timestamp) > const Duration(days: 7)) {
            continue;
          }
          unread++;
        }

        if (unread > 0) counts[puuid] = unread;
      } catch (_) {}
    }

    return counts;
  }

  @override
  Future<void> markChatRead(String puuid) async {
    final history = await _localStore.getChatMessages(puuid);
    if (history.isEmpty) return;
    await _localStore.markChatRead(puuid, history.last.id);
  }
}
