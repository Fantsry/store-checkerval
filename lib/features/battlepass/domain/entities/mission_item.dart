import 'package:equatable/equatable.dart';

enum MissionType {
  daily,
  weekly,
  other,
}

class MissionItem extends Equatable {
  final String uuid;
  final String title;
  final MissionType type;
  final int currentProgress;
  final int progressToComplete;
  final int xpReward;
  final bool isCompleted;

  const MissionItem({
    required this.uuid,
    required this.title,
    required this.type,
    required this.currentProgress,
    required this.progressToComplete,
    required this.xpReward,
    required this.isCompleted,
  });

  double get progressFraction {
    if (progressToComplete <= 0) return isCompleted ? 1.0 : 0.0;
    final frac = currentProgress / progressToComplete;
    return frac.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'title': title,
        'type': type.name,
        'currentProgress': currentProgress,
        'progressToComplete': progressToComplete,
        'xpReward': xpReward,
        'isCompleted': isCompleted,
      };

  factory MissionItem.fromJson(Map<String, dynamic> json) => MissionItem(
        uuid: json['uuid'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: MissionType.values.firstWhere(
          (t) => t.name == (json['type'] as String? ?? 'other'),
          orElse: () => MissionType.other,
        ),
        currentProgress: json['currentProgress'] as int? ?? 0,
        progressToComplete: json['progressToComplete'] as int? ?? 1,
        xpReward: json['xpReward'] as int? ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        uuid,
        title,
        type,
        currentProgress,
        progressToComplete,
        xpReward,
        isCompleted,
      ];
}
