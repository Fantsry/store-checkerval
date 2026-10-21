import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';

class PerformanceStatsCard extends StatelessWidget {
  final CareerOverview overview;

  const PerformanceStatsCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    if (overview.matches.isEmpty) return const SizedBox.shrink();

    final matches = overview.matches;
    final recentForm = _buildRecentForm(matches);
    final streak = _calculateStreak(matches);
    final topAgents = _calculateTopAgents(matches);
    final topMaps = _calculateTopMaps(matches);

    return DataPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECENT FORM',
                      style: AppTextStyles.statLabel(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: recentForm.map((result) {
                        final color = result == null
                            ? AppColors.drawAmber
                            : (result ? AppColors.winGreen : AppColors.lossRed);
                        return Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: color.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              result == null ? 'D' : (result ? 'W' : 'L'),
                              style: AppTextStyles.mono(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              _buildStreakBadge(streak),
            ],
          ),
          if (topAgents.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            Text(
              'TOP AGENTS',
              style: AppTextStyles.statLabel(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...topAgents.take(3).map((agent) => _AgentStatRow(agent: agent)),
          ],
          if (topMaps.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            Text(
              'TOP MAPS',
              style: AppTextStyles.statLabel(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...topMaps.take(3).map((map) => _MapStatRow(mapStat: map)),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakBadge(int streak) {
    final color = streak > 0
        ? AppColors.winGreen
        : (streak < 0 ? AppColors.lossRed : AppColors.textMuted);
    final icon = streak > 0
        ? Icons.trending_up_rounded
        : (streak < 0 ? Icons.trending_down_rounded : Icons.remove_rounded);
    final label = streak > 0
        ? '${streak.abs()} WIN'
        : (streak < 0 ? '${streak.abs()} LOSS' : 'NO STREAK');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.statLabel(color: color)),
        ],
      ),
    );
  }

  List<bool?> _buildRecentForm(List<MatchSummary> matches) {
    return matches.take(5).map((m) {
      if (m.isDraw) return null;
      return m.won;
    }).toList();
  }

  int _calculateStreak(List<MatchSummary> matches) {
    if (matches.isEmpty) return 0;

    final first = matches.first;
    if (first.isDraw) return 0;

    final isWinStreak = first.won == true;
    var count = 0;

    for (final m in matches) {
      if (m.isDraw) break;
      if ((m.won == true) == isWinStreak) {
        count++;
      } else {
        break;
      }
    }

    return isWinStreak ? count : -count;
  }

  List<_AgentStat> _calculateTopAgents(List<MatchSummary> matches) {
    final agentMap = <String, _AgentStatBuilder>{};

    for (final m in matches) {
      final key = m.agentId.toLowerCase();
      agentMap.putIfAbsent(
        key,
        () => _AgentStatBuilder(
          agentName: m.agentName,
          agentIconUrl: m.agentIconUrl,
        ),
      );
      agentMap[key]!.addMatch(m);
    }

    final agents = agentMap.values.map((b) => b.build()).toList();
    agents.sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));
    return agents;
  }

  List<_MapStat> _calculateTopMaps(List<MatchSummary> matches) {
    final mapMap = <String, _MapStatBuilder>{};

    for (final m in matches) {
      if (m.isDeathmatch) continue;
      final key = m.mapName.toLowerCase();
      mapMap.putIfAbsent(key, () => _MapStatBuilder(mapName: m.mapName));
      mapMap[key]!.addMatch(m);
    }

    final maps = mapMap.values.map((b) => b.build()).toList();
    maps.sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));
    return maps;
  }
}

class _AgentStat {
  final String agentName;
  final String? agentIconUrl;
  final int gamesPlayed;
  final int wins;
  final double winRate;
  final double avgKd;

  const _AgentStat({
    required this.agentName,
    this.agentIconUrl,
    required this.gamesPlayed,
    required this.wins,
    required this.winRate,
    required this.avgKd,
  });
}

class _AgentStatBuilder {
  final String agentName;
  final String? agentIconUrl;
  int games = 0;
  int wins = 0;
  int totalKills = 0;
  int totalDeaths = 0;

  _AgentStatBuilder({required this.agentName, this.agentIconUrl});

  void addMatch(MatchSummary m) {
    games++;
    if (m.won == true) wins++;
    totalKills += m.kills;
    totalDeaths += m.deaths;
  }

  _AgentStat build() => _AgentStat(
    agentName: agentName,
    agentIconUrl: agentIconUrl,
    gamesPlayed: games,
    wins: wins,
    winRate: games > 0 ? (wins / games) * 100 : 0,
    avgKd: totalDeaths > 0 ? totalKills / totalDeaths : totalKills.toDouble(),
  );
}

class _MapStat {
  final String mapName;
  final int gamesPlayed;
  final int wins;
  final double winRate;

  const _MapStat({
    required this.mapName,
    required this.gamesPlayed,
    required this.wins,
    required this.winRate,
  });
}

class _MapStatBuilder {
  final String mapName;
  int games = 0;
  int wins = 0;

  _MapStatBuilder({required this.mapName});

  void addMatch(MatchSummary m) {
    games++;
    if (m.won == true) wins++;
  }

  _MapStat build() => _MapStat(
    mapName: mapName,
    gamesPlayed: games,
    wins: wins,
    winRate: games > 0 ? (wins / games) * 100 : 0,
  );
}

class _AgentStatRow extends StatelessWidget {
  final _AgentStat agent;

  const _AgentStatRow({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.roundedSm,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.roundedSm,
              child:
                  agent.agentIconUrl != null && agent.agentIconUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: agent.agentIconUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.agentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${agent.gamesPlayed} games',
                  style: AppTextStyles.statLabel(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${agent.winRate.toStringAsFixed(0)}% WR',
            style: AppTextStyles.statValue(
              color: agent.winRate >= 50
                  ? AppColors.winGreen
                  : AppColors.lossRed,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${agent.avgKd.toStringAsFixed(2)} KD',
            style: AppTextStyles.statValue(
              color: agent.avgKd >= 1
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStatRow extends StatelessWidget {
  final _MapStat mapStat;

  const _MapStatRow({required this.mapStat});

  @override
  Widget build(BuildContext context) {
    final color = mapStat.winRate >= 50
        ? AppColors.winGreen
        : AppColors.lossRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mapStat.mapName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(
                    color: AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${mapStat.gamesPlayed} games / '
                  '${mapStat.wins}W ${mapStat.gamesPlayed - mapStat.wins}L',
                  style: AppTextStyles.statLabel(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: mapStat.winRate / 100,
                minHeight: 3,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 32,
            child: Text(
              '${mapStat.winRate.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.statValue(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
