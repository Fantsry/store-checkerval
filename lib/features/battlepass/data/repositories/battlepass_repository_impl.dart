import 'dart:convert';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/battlepass/data/datasources/contracts_remote_datasource.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/battlepass_overview.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/mission_item.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/repositories/battlepass_repository.dart';

class BattlepassRepositoryImpl implements BattlepassRepository {
  final ContractsRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;
  final LocalStoreService _localStore;

  BattlepassRepositoryImpl({
    required ContractsRemoteDataSource remoteDataSource,
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
  Future<Result<BattlepassOverview>> getBattlepassOverview({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = _localStore.getMap('cached_battlepass_overview');
        if (cached != null && cached.isNotEmpty) {
          try {
            final overview = BattlepassOverview.fromJson(cached);
            if (overview.battlepassName != 'Act Battlepass' &&
                overview.battlepassName != 'CLOSED BETA REWARDS') {
              return Result.success(overview);
            }
          } catch (_) {}
        }
      }

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

      final futures = await Future.wait<dynamic>([
        _remoteDataSource.fetchContractsAndMissions(
          shard: shard,
          puuid: puuid,
        ),
        _remoteDataSource.fetchMissionsMetadata(),
        _remoteDataSource.fetchContractsMetadata(),
        _remoteDataSource.fetchSeasonsMetadata(),
      ]);

      final contractsData = futures[0] as Map<String, dynamic>?;
      final missionsMetadata =
          futures[1] as Map<String, Map<String, dynamic>>;
      final contractsMetadata =
          futures[2] as List<Map<String, dynamic>>;
      final seasonsMetadata =
          futures[3] as List<Map<String, dynamic>>;

      if (contractsData == null) {
        // Check for existing valid cache
        final cached = _localStore.getMap('cached_battlepass_overview');
        if (cached != null && cached.isNotEmpty) {
          try {
            final overview = BattlepassOverview.fromJson(cached);
            if (overview.battlepassName != 'Act Battlepass' &&
                overview.battlepassName != 'CLOSED BETA REWARDS') {
              return Result.success(overview);
            }
          } catch (_) {}
        }

        return const Result.failure(
          ServerFailure(
            message:
                'Failed to load Battlepass & Missions from Riot. Please sign in again or retry.',
          ),
        );
      }

      final List<MissionItem> dailyMissions = [];
      final List<MissionItem> weeklyMissions = [];

      // Parse Missions
      if (contractsData['Missions'] is List) {
        final rawMissions = contractsData['Missions'] as List<dynamic>;

        for (final m in rawMissions) {
          if (m is Map) {
            final id = (m['ID'] ?? '').toString().toLowerCase();
            final meta = missionsMetadata[id];
            final title = meta?['title'] ?? 'Complete Mission Objective';
            final metaType = (meta?['type'] ?? '').toString().toLowerCase();
            final xpGrant = meta?['xpGrant'] as int? ?? 1000;
            final progressToComplete =
                meta?['progressToComplete'] as int? ?? 1;

            int progress = 0;
            if (m['Objectives'] is Map) {
              final objs = m['Objectives'] as Map<dynamic, dynamic>;
              for (final val in objs.values) {
                if (val is num && val > progress) {
                  progress = val.toInt();
                }
              }
            }

            final isComplete =
                (m['Complete'] as bool? ?? false) || progress >= progressToComplete;

            final type = metaType.contains('daily')
                ? MissionType.daily
                : metaType.contains('weekly')
                    ? MissionType.weekly
                    : (xpGrant >= 8000 ? MissionType.weekly : MissionType.daily);

            final item = MissionItem(
              uuid: id,
              title: title,
              type: type,
              currentProgress: progress.clamp(0, progressToComplete),
              progressToComplete: progressToComplete,
              xpReward: xpGrant,
              isCompleted: isComplete,
            );

            if (type == MissionType.daily) {
              dailyMissions.add(item);
            } else {
              weeklyMissions.add(item);
            }
          }
        }
      }

      // Collect Season Battlepass Contracts from metadata
      Map<String, dynamic>? bpContractMeta;
      final activeSpecialContract =
          (contractsData['ActiveSpecialContract'] ?? '').toString().toLowerCase();

      final seasonContracts = <String, Map<String, dynamic>>{};
      final List<Map<String, dynamic>> orderedSeasonContracts = [];
      for (final c in contractsMetadata) {
        final content = c['content'] as Map<String, dynamic>?;
        final rel = (content?['relationType'] ?? '').toString().toLowerCase();
        final uuid = (c['uuid'] ?? '').toString().toLowerCase();
        if (rel == 'season') {
          seasonContracts[uuid] = c;
          orderedSeasonContracts.add(c);
        }
      }

      // 1. Try matching ActiveSpecialContract from Riot response
      if (activeSpecialContract.isNotEmpty &&
          seasonContracts.containsKey(activeSpecialContract)) {
        bpContractMeta = seasonContracts[activeSpecialContract];
      }

      // 2. Try matching from player's contracts in contractsData
      final playerContracts = (contractsData['Contracts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      if (bpContractMeta == null) {
        for (final pc in playerContracts.reversed) {
          final defId =
              (pc['ContractDefinitionID'] ?? '').toString().toLowerCase();
          if (seasonContracts.containsKey(defId)) {
            bpContractMeta = seasonContracts[defId];
            break;
          }
        }
      }

      // 3. Try matching current Act season by active UTC dates
      if (bpContractMeta == null && seasonsMetadata.isNotEmpty) {
        final now = DateTime.now().toUtc();
        String? activeSeasonUuid;
        for (final s in seasonsMetadata) {
          final type = (s['type'] ?? '').toString().toLowerCase();
          final startStr = s['startTime']?.toString();
          final endStr = s['endTime']?.toString();
          if (type.contains('act') && startStr != null && endStr != null) {
            final start = DateTime.tryParse(startStr);
            final end = DateTime.tryParse(endStr);
            if (start != null &&
                end != null &&
                now.isAfter(start) &&
                now.isBefore(end)) {
              activeSeasonUuid = (s['uuid'] ?? '').toString().toLowerCase();
              break;
            }
          }
        }

        if (activeSeasonUuid != null) {
          for (final sc in orderedSeasonContracts) {
            final content = sc['content'] as Map<String, dynamic>?;
            final relUuid =
                (content?['relationUuid'] ?? '').toString().toLowerCase();
            if (relUuid == activeSeasonUuid) {
              bpContractMeta = sc;
              break;
            }
          }
        }
      }

      // 4. Fallback: pick the latest Season contract chronologically
      if (bpContractMeta == null && orderedSeasonContracts.isNotEmpty) {
        bpContractMeta = orderedSeasonContracts.last;
      }

      final bpUuid = (bpContractMeta?['uuid'] ?? '').toString().toLowerCase();
      Map<String, dynamic>? playerBpContract;

      for (final pc in playerContracts) {
        final defId =
            (pc['ContractDefinitionID'] ?? '').toString().toLowerCase();
        if (defId == bpUuid) {
          playerBpContract = pc;
          break;
        }
      }

      final String bpName =
          bpContractMeta?['displayName'] ?? 'Act Battlepass';
      final int currentTier =
          (playerBpContract?['ProgressionLevelReached'] as int? ?? 0);
      final int currentTierXp =
          (playerBpContract?['ProgressionTowardsNextLevel'] as int? ?? 0);
      final prog =
          playerBpContract?['ContractProgression'] as Map<String, dynamic>?;
      final int totalXp = (prog?['TotalProgressionEarned'] as int? ?? 0);

      // Extract chapter levels & XP requirements
      final List<Map<String, dynamic>> allLevels = [];
      final content = bpContractMeta?['content'] as Map<String, dynamic>?;
      final chapters = (content?['chapters'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      for (final ch in chapters) {
        final levels = (ch['levels'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        allLevels.addAll(levels);
      }

      final int maxTier = allLevels.isNotEmpty ? allLevels.length : 55;

      // Determine XP required for upcoming tier
      int tierXpRequired = 10000;
      final targetTierIndex =
          currentTier < allLevels.length ? currentTier : allLevels.length - 1;
      if (targetTierIndex >= 0 && targetTierIndex < allLevels.length) {
        final xpReq = allLevels[targetTierIndex]['xp'] as int? ?? 0;
        if (xpReq > 0) {
          tierXpRequired = xpReq;
        } else if (targetTierIndex + 1 < allLevels.length) {
          tierXpRequired =
              allLevels[targetTierIndex + 1]['xp'] as int? ?? 2000;
        }
      }

      // Collect raw upcoming rewards (next 5 tiers)
      final List<Map<String, dynamic>> rawUpcomingRewards = [];
      int tierCounter = 0;
      for (final lvl in allLevels) {
        tierCounter++;
        if (tierCounter > currentTier && rawUpcomingRewards.length < 5) {
          final reward = lvl['reward'] as Map<String, dynamic>?;
          if (reward != null) {
            rawUpcomingRewards.add({
              'tier': tierCounter,
              'uuid': (reward['uuid'] ?? '').toString(),
              'type': (reward['type'] ?? 'Item').toString(),
              'isFree': lvl['isFree'] as bool? ?? false,
            });
          }
        }
      }

      // Enrich upcoming rewards with real display names and icons
      final rewardFutures = rawUpcomingRewards.map((rw) async {
        final uuid = rw['uuid'] as String;
        final type = rw['type'] as String;
        final tier = rw['tier'] as int;
        final isFree = rw['isFree'] as bool;

        String displayName = 'Tier $tier Reward';
        String? displayIcon;

        if (uuid.isNotEmpty) {
          final details = await _remoteDataSource.fetchRewardDetails(
            uuid: uuid,
            type: type,
          );
          if (details != null) {
            displayName = details['displayName'] ?? displayName;
            displayIcon = details['displayIcon'];
          }
        }

        return BattlepassRewardItem(
          tier: tier,
          displayName: displayName,
          displayIcon: displayIcon,
          rewardType: type,
          isFree: isFree,
        );
      }).toList();

      final List<BattlepassRewardItem> rewards =
          await Future.wait(rewardFutures);

      final overview = BattlepassOverview(
        battlepassName: bpName,
        currentTier: currentTier,
        maxTier: maxTier,
        currentTierXp: currentTierXp,
        tierXpRequired: tierXpRequired,
        totalXpEarned: totalXp,
        dailyMissions: dailyMissions,
        weeklyMissions: weeklyMissions,
        nextRewards: rewards,
      );

      await _localStore.setMap(
        'cached_battlepass_overview',
        overview.toJson(),
      );

      return Result.success(overview);
    } catch (e) {
      final cached = _localStore.getMap('cached_battlepass_overview');
      if (cached != null && cached.isNotEmpty) {
        try {
          final overview = BattlepassOverview.fromJson(cached);
          if (overview.battlepassName != 'Act Battlepass' &&
              overview.battlepassName != 'CLOSED BETA REWARDS') {
            return Result.success(overview);
          }
        } catch (_) {}
      }

      return Result.failure(
        ServerFailure(message: 'Failed to load Battlepass & Missions: $e'),
      );
    }
  }
}
