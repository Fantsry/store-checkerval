import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/map_kill_overlay_widget.dart';

/// A TRN-style "Kills by Round" matrix chart and interactive killfeed inspector.
///
/// Features:
/// - Horizontally scrollable round matrix with tinted columns (Green for ally win, Red for enemy win).
/// - Top: Ally kills stacked upward with teal/mint green borders (30px diameter).
/// - Center: Round number indicators with outcome styling (Win = Mint green, Loss = Coral red, Draw = Amber).
/// - Bottom: Enemy kills stacked downward with coral red borders (30px diameter).
/// - Top Right: Inward red arrows (▶◀) toggle for compact / expanded view.
/// - Focused Player Bar: Filter kills by specific player (highlighted with gold ring & glow; others dimmed).
///   Defaults to the user's player (isSelf) matching the TRN mobile app screenshot.
/// - Timeline Banner & Breakdown: "View the match timeline and events for Round X" with full killfeed,
///   first-blood indicators, assists, and win-condition badges.
/// - 2D Map Kill Overlay: View kill/death positions per round or entire match.
class KillsByRoundWidget extends StatefulWidget {
  final MatchSummary match;
  final bool initialScrollToEnd;

  const KillsByRoundWidget({
    super.key,
    required this.match,
    this.initialScrollToEnd = false,
  });

  @override
  State<KillsByRoundWidget> createState() => _KillsByRoundWidgetState();
}

class _KillsByRoundWidgetState extends State<KillsByRoundWidget> {
  late final ScrollController _scrollController;
  int _selectedRoundIndex = 0;
  String? _focusedPuuid; // null = "All Players"
  bool _isCompactView = false;
  bool _isTimelineExpanded = true;
  int _detailViewMode = 0; // 0: Timeline Events, 1: Kill Map Overview

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Default to focusing on the current user if present in match
    final selfPlayer =
        widget.match.allPlayers.where((p) => p.isSelf).firstOrNull;
    if (selfPlayer != null) {
      _focusedPuuid = selfPlayer.puuid;
    }

    if (widget.initialScrollToEnd && widget.match.rounds.length > 8) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isAllyKill(MatchRoundKill kill) {
    if (kill.isKillerSelf) return true;
    final userTeam = widget.match.teammates.isNotEmpty
        ? widget.match.teammates.first.teamId.toLowerCase()
        : '';
    if (kill.killerTeamId.isNotEmpty && userTeam.isNotEmpty) {
      return kill.killerTeamId.toLowerCase() == userTeam;
    }
    return widget.match.teammates.any(
      (t) => t.puuid.toLowerCase() == kill.killerPuuid.toLowerCase(),
    );
  }

  MatchPlayerSummary? get _focusedPlayer {
    if (_focusedPuuid == null) return null;
    final all = widget.match.allPlayers;
    try {
      return all.firstWhere(
        (p) => p.puuid.toLowerCase() == _focusedPuuid!.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void _showFocusedPlayerPicker() {
    final allPlayers = widget.match.allPlayers;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'SELECT FOCUSED PLAYER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // "All Players" option
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text(
                    'All Players (Show All Kills)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  trailing: _focusedPuuid == null
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF00E5FF), size: 20)
                      : null,
                  onTap: () {
                    setState(() => _focusedPuuid = null);
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1, color: Colors.white12),
                Expanded(
                  child: ListView.builder(
                    itemCount: allPlayers.length,
                    itemBuilder: (context, idx) {
                      final p = allPlayers[idx];
                      final isAlly = widget.match.teammates.any(
                        (t) => t.puuid.toLowerCase() == p.puuid.toLowerCase(),
                      );
                      final isSelected = _focusedPuuid != null &&
                          _focusedPuuid!.toLowerCase() == p.puuid.toLowerCase();
                      final teamColor = isAlly
                          ? const Color(0xFF2DD4BF)
                          : AppTheme.valorantRed;

                      return ListTile(
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.isSelf
                                  ? const Color(0xFFFFD700)
                                  : teamColor,
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: p.agentIconUrl != null &&
                                    p.agentIconUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: p.agentIconUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: AppTheme.textMuted,
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    size: 18, color: AppTheme.textMuted),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.isSelf
                                      ? const Color(0xFFFFD700)
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (p.isSelf) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'YOU',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${p.agentName}  •  ${p.kills}/${p.deaths}/${p.assists}  •  ${p.score} pts',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF00E5FF), size: 20)
                            : null,
                        onTap: () {
                          setState(() => _focusedPuuid = p.puuid);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.match.rounds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 32,
              color: AppTheme.textMuted,
            ),
            SizedBox(height: 10),
            Text(
              'No round kill events available for this match',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final rounds = widget.match.rounds;
    final safeSelectedIdx = _selectedRoundIndex.clamp(0, rounds.length - 1);
    final selectedRound = rounds[safeSelectedIdx];

    // Compute max kills per round for responsive heights
    int maxAllyKills = 0;
    int maxEnemyKills = 0;
    for (final r in rounds) {
      int ally = 0;
      int enemy = 0;
      for (final k in r.kills) {
        if (_isAllyKill(k)) {
          ally++;
        } else {
          enemy++;
        }
      }
      if (ally > maxAllyKills) maxAllyKills = ally;
      if (enemy > maxEnemyKills) maxEnemyKills = enemy;
    }

    // Set bounds for avatar stack height (min 3 slots, max 6 slots)
    final topSlots = maxAllyKills.clamp(3, 6);
    final bottomSlots = maxEnemyKills.clamp(3, 6);
    const circleSize = 30.0;
    const spacing = 3.0;
    final topSectionHeight = (topSlots * (circleSize + spacing)) + 4;
    final bottomSectionHeight = (bottomSlots * (circleSize + spacing)) + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Bar matching TRN reference
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Kills by Round',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${widget.match.scoreWon} - ${widget.match.scoreLost} (${rounds.length} Rnds)',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Red inward-arrows icon button (▶◀) matching TRN screenshot
                  InkWell(
                    onTap: () {
                      setState(() => _isCompactView = !_isCompactView);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.valorantRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.valorantRed.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_right_rounded,
                            size: 16,
                            color: AppTheme.valorantRed,
                          ),
                          Icon(
                            Icons.arrow_left_rounded,
                            size: 16,
                            color: AppTheme.valorantRed,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Horizontal Scrollable Round Matrix Chart
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1217),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(rounds.length, (idx) {
                final round = rounds[idx];
                final isSelected = idx == safeSelectedIdx;

                final allyKills = <MatchRoundKill>[];
                final enemyKills = <MatchRoundKill>[];
                for (final k in round.kills) {
                  if (_isAllyKill(k)) {
                    allyKills.add(k);
                  } else {
                    enemyKills.add(k);
                  }
                }

                final roundWon = round.won;
                // Tint colors matching screenshot:
                // When ally won (rounds 1 & 2): Top column has dark teal/green tint
                // When enemy won (rounds 3-7): Bottom column has dark red tint
                final Color topColBg = roundWon == true
                    ? const Color(0xFF0D2921)
                    : const Color(0xFF13171D);
                final Color bottomColBg = roundWon == false
                    ? const Color(0xFF281116)
                    : const Color(0xFF13171D);

                // Round Number Box colors
                final Color roundBoxBg;
                final Color roundNumColor;
                if (roundWon == true) {
                  roundBoxBg = const Color(0xFF163E32);
                  roundNumColor = const Color(0xFF34D399); // Mint green
                } else if (roundWon == false) {
                  roundBoxBg = const Color(0xFF381418);
                  roundNumColor = const Color(0xFFF87171); // Coral red
                } else {
                  roundBoxBg = const Color(0xFF382E00);
                  roundNumColor = Colors.amber;
                }

                return InkWell(
                  onTap: () {
                    setState(() => _selectedRoundIndex = idx);
                  },
                  child: Container(
                    width: 42,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Top Section: Ally Kills (stacked bottom-to-top)
                        if (!_isCompactView)
                          Container(
                            height: topSectionHeight,
                            width: 42,
                            padding: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: topColBg,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: allyKills.map((kill) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: spacing),
                                  child: _KillAvatarCircle(
                                    kill: kill,
                                    isAlly: true,
                                    focusedPuuid: _focusedPuuid,
                                    size: circleSize,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // 2. Center: Round Number Strip Box
                        Container(
                          width: 42,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: roundBoxBg,
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF00E5FF),
                                    width: 2.0,
                                  )
                                : null,
                          ),
                          child: Text(
                            '${round.roundNum + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: isSelected
                                  ? Colors.white
                                  : roundNumColor,
                            ),
                          ),
                        ),

                        // 3. Bottom Section: Enemy Kills (stacked top-to-bottom)
                        if (!_isCompactView)
                          Container(
                            height: bottomSectionHeight,
                            width: 42,
                            padding: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: bottomColBg,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(6),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: enemyKills.map((kill) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(top: spacing),
                                  child: _KillAvatarCircle(
                                    kill: kill,
                                    isAlly: false,
                                    focusedPuuid: _focusedPuuid,
                                    size: circleSize,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // Compact view indicator (kill counts if compact)
                        if (_isCompactView)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: [
                                Text(
                                  '${allyKills.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF34D399),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${enemyKills.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF87171),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Focused Player Capsule Selector (TRN mobile style)
        InkWell(
          onTap: _showFocusedPlayerPicker,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14171E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _focusedPuuid != null
                    ? const Color(0xFFFFD700).withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Focused avatar / icon
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _focusedPlayer != null
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF2DD4BF),
                      width: 1.5,
                    ),
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: ClipOval(
                    child: _focusedPlayer?.agentIconUrl != null &&
                            _focusedPlayer!.agentIconUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _focusedPlayer!.agentIconUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                          )
                        : Icon(
                            _focusedPlayer == null
                                ? Icons.groups_rounded
                                : Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FOCUSED PLAYER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _focusedPlayer?.displayName ??
                            'All Players (Tap to Filter)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _focusedPlayer != null
                              ? const Color(0xFFFFD700)
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_focusedPuuid != null)
                  InkWell(
                    onTap: () => setState(() => _focusedPuuid = null),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: AppTheme.textMuted),
                    ),
                  )
                else
                  const Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // "View the match timeline and events for..." Bar matching TRN screenshot
        InkWell(
          onTap: () {
            setState(() => _isTimelineExpanded = !_isTimelineExpanded);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppTheme.valorantRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Match timeline & events for Round ${safeSelectedIdx + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  _isTimelineExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),

        // Selected Round Detail Card & Killfeed Timeline
        if (_isTimelineExpanded) ...[
          if (widget.match.hasMinimapData) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DetailSubTab(
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'ROUND TIMELINE',
                    isSelected: _detailViewMode == 0,
                    onTap: () => setState(() => _detailViewMode = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DetailSubTab(
                    icon: Icons.radar_rounded,
                    label: 'KILL MAP OVERVIEW',
                    isSelected: _detailViewMode == 1,
                    onTap: () => setState(() => _detailViewMode = 1),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (_detailViewMode == 0 || !widget.match.hasMinimapData)
            _SelectedRoundCard(
              round: selectedRound,
              roundIndex: safeSelectedIdx,
              isAllyKill: _isAllyKill,
              focusedPuuid: _focusedPuuid,
              onViewMap: widget.match.hasMinimapData
                  ? () => setState(() => _detailViewMode = 1)
                  : null,
            )
          else
            MapKillOverlayWidget(
              match: widget.match,
              selectedRoundIndex: safeSelectedIdx,
            ),
        ],
      ],
    );
  }
}

class _DetailSubTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DetailSubTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.valorantRed.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.valorantRed.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An individual agent circle avatar in the round kill matrix.
class _KillAvatarCircle extends StatelessWidget {
  final MatchRoundKill kill;
  final bool isAlly;
  final String? focusedPuuid;
  final double size;

  const _KillAvatarCircle({
    required this.kill,
    required this.isAlly,
    required this.focusedPuuid,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusedPuuid != null &&
        kill.killerPuuid.toLowerCase() == focusedPuuid!.toLowerCase();
    final isDimmed = focusedPuuid != null && !isFocused;

    final Color ringColor;
    final double ringWidth;
    if (isFocused || kill.isKillerSelf) {
      ringColor = const Color(0xFFFFD700);
      ringWidth = 2.0;
    } else if (isAlly) {
      ringColor = const Color(0xFF2DD4BF); // Crisp teal/green border
      ringWidth = 1.5;
    } else {
      ringColor = const Color(0xFFEF4444); // Crisp red border
      ringWidth = 1.5;
    }

    return Tooltip(
      message:
          '${kill.killerName} killed ${kill.victimName} (${kill.killerAgentName})',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDimmed ? 0.22 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.85),
            border: Border.all(color: ringColor, width: ringWidth),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: kill.killerAgentIconUrl != null &&
                    kill.killerAgentIconUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: kill.killerAgentIconUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 15,
                      color: AppTheme.textMuted,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 15,
                    color: AppTheme.textMuted,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Detail card showing the full killfeed breakdown of the selected round.
class _SelectedRoundCard extends StatelessWidget {
  final MatchRoundSummary round;
  final int roundIndex;
  final bool Function(MatchRoundKill) isAllyKill;
  final String? focusedPuuid;
  final VoidCallback? onViewMap;

  const _SelectedRoundCard({
    required this.round,
    required this.roundIndex,
    required this.isAllyKill,
    required this.focusedPuuid,
    this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final roundWon = round.won;
    final outcomeColor = roundWon == true
        ? const Color(0xFF2DD4BF)
        : (roundWon == false ? AppTheme.valorantRed : Colors.amber);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: outcomeColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Round Title Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: outcomeColor.withValues(alpha: 0.09),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: outcomeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ROUND ${round.roundNum + 1}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: outcomeColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (round.roundResult.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•  ${_formatRoundResult(round.roundResult)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onViewMap != null) ...[
                      InkWell(
                        onTap: onViewMap,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppTheme.valorantCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.valorantCyan.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.radar_rounded, size: 10, color: AppTheme.valorantCyan),
                              SizedBox(width: 3),
                              Text(
                                'Map',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.valorantCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: outcomeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roundWon == true
                            ? 'VICTORY'
                            : (roundWon == false ? 'DEFEAT' : 'DRAW'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: outcomeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Kills List
          if (round.kills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Text(
                round.roundResult.isNotEmpty
                    ? 'Round won by ${_formatRoundResult(round.roundResult)} with no kill events.'
                    : 'No kills recorded in this round (Objective win)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: round.kills.length,
              separatorBuilder: (_, __) => Divider(
                height: 6,
                color: Colors.white.withValues(alpha: 0.04),
              ),
              itemBuilder: (context, idx) {
                final kill = round.kills[idx];
                final isAlly = isAllyKill(kill);
                final isKillerFocused = focusedPuuid != null &&
                    kill.killerPuuid.toLowerCase() ==
                        focusedPuuid!.toLowerCase();
                final isVictimFocused = focusedPuuid != null &&
                    kill.victimPuuid.toLowerCase() ==
                        focusedPuuid!.toLowerCase();

                final killerColor =
                    isAlly ? const Color(0xFF2DD4BF) : AppTheme.valorantRed;
                final victimColor =
                    !isAlly ? const Color(0xFF2DD4BF) : AppTheme.valorantRed;

                final timeSec =
                    kill.roundTime > 0 ? (kill.roundTime ~/ 1000) : 0;
                final timeStr =
                    '${(timeSec ~/ 60).toString().padLeft(1, '0')}:${(timeSec % 60).toString().padLeft(2, '0')}';

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: isKillerFocused
                        ? const Color(0xFFFFD700).withValues(alpha: 0.08)
                        : (isVictimFocused
                            ? AppTheme.valorantRed.withValues(alpha: 0.06)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      // Timestamp & First Blood badge
                      SizedBox(
                        width: 34,
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 9,
                            color: idx == 0
                                ? const Color(0xFFFFD700)
                                : AppTheme.textMuted,
                            fontWeight:
                                idx == 0 ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),

                      // Killer Avatar & Name
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kill.isKillerSelf || isKillerFocused
                                      ? const Color(0xFFFFD700)
                                      : killerColor,
                                  width: kill.isKillerSelf || isKillerFocused
                                      ? 1.6
                                      : 1.0,
                                ),
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              child: ClipOval(
                                child: kill.killerAgentIconUrl != null &&
                                        kill.killerAgentIconUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: kill.killerAgentIconUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.person,
                                          size: 13,
                                          color: AppTheme.textMuted,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 13,
                                        color: AppTheme.textMuted,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          kill.killerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: kill.isKillerSelf ||
                                                    isKillerFocused
                                                ? const Color(0xFFFFD700)
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (idx == 0) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 3, vertical: 0.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700)
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: const Text(
                                            'FB',
                                            style: TextStyle(
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFFFD700),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (kill.assistantNames.isNotEmpty)
                                    Text(
                                      '+ ${kill.assistantNames.join(', ')}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action Icon
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: kill.isKillerSelf || isKillerFocused
                              ? const Color(0xFFFFD700)
                              : killerColor,
                        ),
                      ),

                      // Victim Avatar & Name
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                kill.victimName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: kill.isVictimSelf || isVictimFocused
                                      ? const Color(0xFFFFD700)
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kill.isVictimSelf || isVictimFocused
                                      ? const Color(0xFFFFD700)
                                      : victimColor,
                                  width: kill.isVictimSelf || isVictimFocused
                                      ? 1.6
                                      : 1.0,
                                ),
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              child: ClipOval(
                                child: kill.victimAgentIconUrl != null &&
                                        kill.victimAgentIconUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: kill.victimAgentIconUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.person,
                                          size: 13,
                                          color: AppTheme.textMuted,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 13,
                                        color: AppTheme.textMuted,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static String _formatRoundResult(String raw) {
    switch (raw.toLowerCase()) {
      case 'eliminated':
      case 'elimination':
        return 'Elimination';
      case 'defused':
        return 'Spike Defused';
      case 'detonated':
        return 'Spike Detonated';
      case 'round timer expired':
      case 'time expired':
        return 'Time Expired';
      default:
        return raw;
    }
  }
}
