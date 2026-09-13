import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';

/// Tracker.gg-style performance overview card showing:
/// - Recent Form: last 5 match W/L indicator pills
/// - Win/Loss Streak
/// - Top 3 Agents (icon + win rate + K/D)
/// - Top 3 Maps (name + win rate bar + games played)
class PerformanceStatsCard extends StatelessWidget {
  final CareerOverview overview;

  const PerformanceStatsCard({
    super.key,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    if (overview.matches.isEmpty) return const SizedBox.shrink();

    final matches = overview.matches;
    final recentForm = _buildRecentForm(matches);
    final streak = _calculateStreak(matches);
    final topAgents = _calculateTopAgents(matches);
    final topMaps = _calculateTopMaps(matches);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceDark,
            AppTheme.cardDark.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Row(
            children: [
              Icon(Icons.insights_rounded, size: 14, color: AppTheme.valorantCyan),
              SizedBox(width: 6),
              Text(
                'PERFORMANCE INSIGHTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recent Form + Streak Row
          Row(
            children: [
              // Recent Form Indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECENT FORM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: recentForm.map((result) {
                        Color color;
                        if (result == null) {
                          color = Colors.amber.shade600;
                        } else if (result) {
                          color = const Color(0xFF00C4A8);
                        } else {
                          color = AppTheme.valorantRed;
                        }
                        return Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: color.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              result == null
                                  ? 'D'
                                  : (result ? 'W' : 'L'),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
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

              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (streak > 0
                          ? const Color(0xFF00C4A8)
                          : (streak < 0 ? AppTheme.valorantRed : AppTheme.textMuted))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (streak > 0
                            ? const Color(0xFF00C4A8)
                            : (streak < 0
                                ? AppTheme.valorantRed
                                : AppTheme.textMuted))
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      streak > 0
                          ? Icons.trending_up_rounded
                          : (streak < 0
                              ? Icons.trending_down_rounded
                              : Icons.remove_rounded),
                      size: 14,
                      color: streak > 0
                          ? const Color(0xFF00C4A8)
                          : (streak < 0
                              ? AppTheme.valorantRed
                              : AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      streak > 0
                          ? '${streak.abs()} Win Streak'
                          : (streak < 0
                              ? '${streak.abs()} Loss Streak'
                              : 'No Streak'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: streak > 0
                            ? const Color(0xFF00C4A8)
                            : (streak < 0
                                ? AppTheme.valorantRed
                                : AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),

          // Top Agents
          if (topAgents.isNotEmpty) ...[
            const Text(
              'TOP AGENTS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...topAgents.take(3).map((agent) => _AgentStatRow(agent: agent)),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 12),
          ],

          // Top Maps
          if (topMaps.isNotEmpty) ...[
            const Text(
              'TOP MAPS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...topMaps.take(3).map((map) => _MapStatRow(mapStat: map)),
          ],
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
    int count = 0;

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
      mapMap.putIfAbsent(
        key,
        () => _MapStatBuilder(mapName: m.mapName),
      );
      mapMap[key]!.addMatch(m);
    }

    final maps = mapMap.values.map((b) => b.build()).toList();
    maps.sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));
    return maps;
  }
}

// ─── Data Classes ─────────────────────────────────────────────

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

// ─── Sub-Widgets ──────────────────────────────────────────────

class _AgentStatRow extends StatelessWidget {
  final _AgentStat agent;

  const _AgentStatRow({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Agent Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: ClipOval(
              child: agent.agentIconUrl != null && agent.agentIconUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: agent.agentIconUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + Games
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.agentName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${agent.gamesPlayed} games',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Win Rate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (agent.winRate >= 50
                      ? const Color(0xFF00C4A8)
                      : AppTheme.valorantRed)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${agent.winRate.toStringAsFixed(0)}% WR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: agent.winRate >= 50
                    ? const Color(0xFF00C4A8)
                    : AppTheme.valorantRed,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // K/D
          Text(
            '${agent.avgKd.toStringAsFixed(2)} KD',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: agent.avgKd >= 1.0
                  ? const Color(0xFF00C4A8)
                  : AppTheme.textSecondary,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Map Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.map_rounded,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + Games
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mapStat.mapName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${mapStat.gamesPlayed} games • ${mapStat.wins}W ${mapStat.gamesPlayed - mapStat.wins}L',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Win Rate Bar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: mapStat.winRate / 100,
                      minHeight: 6,
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        mapStat.winRate >= 50
                            ? const Color(0xFF00C4A8)
                            : AppTheme.valorantRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${mapStat.winRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: mapStat.winRate >= 50
                        ? const Color(0xFF00C4A8)
                        : AppTheme.valorantRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
