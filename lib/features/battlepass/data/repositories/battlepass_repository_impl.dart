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
            return Result.success(BattlepassOverview.fromJson(cached));
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
      ]);

      final contractsData = futures[0] as Map<String, dynamic>?;
      final missionsMetadata =
          futures[1] as Map<String, Map<String, dynamic>>;
      final contractsMetadata =
          futures[2] as List<Map<String, dynamic>>;

      final List<MissionItem> dailyMissions = [];
      final List<MissionItem> weeklyMissions = [];

      // Parse Missions
      if (contractsData != null && contractsData['Missions'] is List) {
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
                    : MissionType.other;

            final item = MissionItem(
              uuid: id,
              title: title,
              type: type,
              currentProgress: progress,
              progressToComplete: progressToComplete,
              xpReward: xpGrant,
              isCompleted: isComplete,
            );

            if (type == MissionType.daily) {
              dailyMissions.add(item);
            } else if (type == MissionType.weekly) {
              weeklyMissions.add(item);
            } else {
              // Categorize into daily or weekly based on XP size if type was generic
              if (xpGrant >= 8000) {
                weeklyMissions.add(item);
              } else {
                dailyMissions.add(item);
              }
            }
          }
        }
      }

      // Parse Battlepass Contract
      String bpName = 'Act Battlepass';
      int currentTier = 1;
      int maxTier = 55;
      int currentTierXp = 0;
      int tierXpRequired = 10000;
      int totalXp = 0;
      final List<BattlepassRewardItem> rewards = [];

      // Find Season Battlepass Contract from metadata
      Map<String, dynamic>? bpContractMeta;
      for (final c in contractsMetadata) {
        final content = c['content'] as Map<String, dynamic>?;
        final rel = (content?['relationType'] ?? '').toString().toLowerCase();
        final name = (c['displayName'] ?? '').toString().toLowerCase();
        if (rel == 'season' || name.contains('battlepass') || name.contains('ep ')) {
          bpContractMeta = c;
          bpName = c['displayName'] ?? 'Act Battlepass';
          break;
        }
      }

      if (bpContractMeta != null &&
          contractsData != null &&
          contractsData['Contracts'] is List) {
        final bpUuid =
            (bpContractMeta['uuid'] ?? '').toString().toLowerCase();
        final playerContracts =
            contractsData['Contracts'] as List<dynamic>;

        for (final pc in playerContracts) {
          if (pc is Map) {
            final pcDefId = (pc['ContractDefinitionID'] ?? '')
                .toString()
                .toLowerCase();
            if (pcDefId == bpUuid) {
              currentTier = (pc['ProgressionLevelReached'] as int? ?? 0);
              final prog = pc['ContractProgression'] as Map<String, dynamic>?;
              totalXp = (prog?['TotalProgressionEarned'] as int? ?? 0);
              break;
            }
          }
        }

        // Parse upcoming tier rewards from chapters
        try {
          final content =
              bpContractMeta['content'] as Map<String, dynamic>?;
          final chapters = content?['chapters'] as List<dynamic>? ?? [];
          int tierCounter = 0;

          for (final ch in chapters) {
            if (ch is Map) {
              final levels = ch['levels'] as List<dynamic>? ?? [];
              for (final lvl in levels) {
                tierCounter++;
                if (lvl is Map) {
                  final reward = lvl['reward'] as Map<String, dynamic>?;
                  if (reward != null &&
                      tierCounter >= currentTier &&
                      rewards.length < 5) {
                    rewards.add(
                      BattlepassRewardItem(
                        tier: tierCounter,
                        displayName: (reward['displayName'] ?? 'Reward Tier $tierCounter').toString(),
                        displayIcon: reward['displayIcon']?.toString(),
                        rewardType: (reward['type'] ?? 'Reward').toString(),
                        isFree: lvl['isFree'] as bool? ?? false,
                      ),
                    );
                  }
                  if (tierCounter == currentTier + 1) {
                    tierXpRequired = lvl['xp'] as int? ?? 10000;
                  }
                }
              }
            }
          }
          maxTier = tierCounter > 0 ? tierCounter : 55;
        } catch (_) {}
      }

      // Calculate current tier remainder XP
      currentTierXp = (totalXp % (tierXpRequired > 0 ? tierXpRequired : 10000));

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
          return Result.success(BattlepassOverview.fromJson(cached));
        } catch (_) {}
      }

      return Result.failure(
        ServerFailure(message: 'Failed to load Battlepass & Missions: $e'),
      );
    }
  }
}
