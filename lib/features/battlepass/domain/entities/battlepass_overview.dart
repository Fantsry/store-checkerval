import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/mission_item.dart';

class BattlepassRewardItem extends Equatable {
  final int tier;
  final String displayName;
  final String? displayIcon;
  final String rewardType;
  final bool isFree;

  const BattlepassRewardItem({
    required this.tier,
    required this.displayName,
    this.displayIcon,
    this.rewardType = 'Item',
    this.isFree = false,
  });

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'displayName': displayName,
        'displayIcon': displayIcon,
        'rewardType': rewardType,
        'isFree': isFree,
      };

  factory BattlepassRewardItem.fromJson(Map<String, dynamic> json) =>
      BattlepassRewardItem(
        tier: json['tier'] as int? ?? 1,
        displayName: json['displayName'] as String? ?? '',
        displayIcon: json['displayIcon'] as String?,
        rewardType: json['rewardType'] as String? ?? 'Item',
        isFree: json['isFree'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        tier,
        displayName,
        displayIcon,
        rewardType,
        isFree,
      ];
}

class BattlepassOverview extends Equatable {
  final String battlepassName;
  final int currentTier;
  final int maxTier;
  final int currentTierXp;
  final int tierXpRequired;
  final int totalXpEarned;
  final List<MissionItem> dailyMissions;
  final List<MissionItem> weeklyMissions;
  final List<BattlepassRewardItem> nextRewards;

  const BattlepassOverview({
    this.battlepassName = 'Current Act Battlepass',
    this.currentTier = 1,
    this.maxTier = 55,
    this.currentTierXp = 0,
    this.tierXpRequired = 10000,
    this.totalXpEarned = 0,
    this.dailyMissions = const [],
    this.weeklyMissions = const [],
    this.nextRewards = const [],
  });

  double get tierProgressFraction {
    if (tierXpRequired <= 0) return 1.0;
    return (currentTierXp / tierXpRequired).clamp(0.0, 1.0);
  }

  double get overallProgressFraction {
    if (maxTier <= 0) return 0.0;
    return (currentTier / maxTier).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'battlepassName': battlepassName,
        'currentTier': currentTier,
        'maxTier': maxTier,
        'currentTierXp': currentTierXp,
        'tierXpRequired': tierXpRequired,
        'totalXpEarned': totalXpEarned,
        'dailyMissions': dailyMissions.map((m) => m.toJson()).toList(),
        'weeklyMissions': weeklyMissions.map((m) => m.toJson()).toList(),
        'nextRewards': nextRewards.map((r) => r.toJson()).toList(),
      };

  factory BattlepassOverview.fromJson(Map<String, dynamic> json) {
    final dailyRaw = json['dailyMissions'] as List<dynamic>? ?? [];
    final weeklyRaw = json['weeklyMissions'] as List<dynamic>? ?? [];
    final rewardsRaw = json['nextRewards'] as List<dynamic>? ?? [];

    return BattlepassOverview(
      battlepassName: json['battlepassName'] as String? ?? 'Current Act Battlepass',
      currentTier: json['currentTier'] as int? ?? 1,
      maxTier: json['maxTier'] as int? ?? 55,
      currentTierXp: json['currentTierXp'] as int? ?? 0,
      tierXpRequired: json['tierXpRequired'] as int? ?? 10000,
      totalXpEarned: json['totalXpEarned'] as int? ?? 0,
      dailyMissions:
          dailyRaw.map((m) => MissionItem.fromJson(m as Map<String, dynamic>)).toList(),
      weeklyMissions:
          weeklyRaw.map((m) => MissionItem.fromJson(m as Map<String, dynamic>)).toList(),
      nextRewards: rewardsRaw
          .map((r) => BattlepassRewardItem.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        battlepassName,
        currentTier,
        maxTier,
        currentTierXp,
        tierXpRequired,
        totalXpEarned,
        dailyMissions,
        weeklyMissions,
        nextRewards,
      ];
}
