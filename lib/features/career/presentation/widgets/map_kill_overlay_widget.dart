import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';


/// Interactive 2D minimap overlay showing kill & death positions per round
/// or overview of the entire match.
///
/// Markers:
///   - Biru (Friendly / Team Kita): Color(0xFF00E5FF)
///   - Merah (Enemy / Musuh): Color(0xFFFF4655)
///   - Yang Mati (Victim): Ikon Agent dengan marker "X" jelas
///   - Penembak (Killer): Ikon Agent tanpa marker "X"
///   - Tanpa garis vektor membingungkan (clean spatial readability)
class MapKillOverlayWidget extends StatefulWidget {
  final MatchSummary match;
  final int selectedRoundIndex;
  final bool initialShowAllRounds;

  const MapKillOverlayWidget({
    super.key,
    required this.match,
    required this.selectedRoundIndex,
    this.initialShowAllRounds = false,
  });

  @override
  State<MapKillOverlayWidget> createState() => _MapKillOverlayWidgetState();
}

class _MapKillOverlayWidgetState extends State<MapKillOverlayWidget> {
  late bool _showAllRounds;
  bool _onlySelfEvents = false;
  MatchRoundKill? _selectedKill;

  // Blue for Friendly, Red for Enemy
  static const Color _colorFriendly = Color(0xFF00E5FF);
  static const Color _colorEnemy = Color(0xFFFF4655);

  @override
  void initState() {
    super.initState();
    _showAllRounds = widget.initialShowAllRounds;
  }

  @override
  void didUpdateWidget(covariant MapKillOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoundIndex != widget.selectedRoundIndex && !_showAllRounds) {
      _selectedKill = null;
    }
  }

  bool _isFriendlyKiller(MatchRoundKill kill) {
    if (kill.isKillerSelf) return true;
    if (widget.match.teammates.any((t) => t.puuid == kill.killerPuuid)) return true;
    if (widget.match.teammates.isNotEmpty &&
        kill.killerTeamId.isNotEmpty &&
        kill.killerTeamId == widget.match.teammates.first.teamId) {
      return true;
    }
    return false;
  }

  bool _isFriendlyVictim(MatchRoundKill kill) {
    if (kill.isVictimSelf) return true;
    if (widget.match.teammates.any((t) => t.puuid == kill.victimPuuid)) return true;
    if (widget.match.teammates.isNotEmpty &&
        kill.victimTeamId.isNotEmpty &&
        kill.victimTeamId == widget.match.teammates.first.teamId) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.match.hasMinimapData) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.map_outlined,
                size: 32,
                color: AppColors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Kill map not available for this map/mode',
                style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'Minimap data is not provided for some game modes',
                style: AppTextStyles.caption(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final match = widget.match;
    final rounds = match.rounds;
    final safeRoundIdx = widget.selectedRoundIndex.clamp(0, rounds.isNotEmpty ? rounds.length - 1 : 0);

    // Collect kills based on mode
    List<MatchRoundKill> allKills;
    if (_showAllRounds) {
      allKills = rounds
          .expand((r) => r.kills)
          .where((k) => k.victimLocationX != null && k.victimLocationY != null)
          .toList();
    } else {
      if (rounds.isEmpty || safeRoundIdx >= rounds.length) {
        return _buildEmptyState('No round data available');
      }
      allKills = rounds[safeRoundIdx].kills
          .where((k) => k.victimLocationX != null && k.victimLocationY != null)
          .toList();
    }

    // Apply filter
    final displayKills = _onlySelfEvents
        ? allKills.where((k) => k.isKillerSelf || k.isVictimSelf).toList()
        : allKills;

    final yourKillsCount = displayKills.where((k) => k.isKillerSelf).length;
    final yourDeathsCount = displayKills.where((k) => k.isVictimSelf).length;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          size: 15,
                          color: _colorFriendly,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showAllRounds
                              ? 'MAP OVERVIEW — ALL ROUNDS'
                              : 'KILL MAP — ROUND ${safeRoundIdx + 1}',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.textPrimary,
                          ).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),

                    // Toggle: Round vs All Rounds
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: AppRadius.roundedSm,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ModeToggleButton(
                            label: 'R${safeRoundIdx + 1}',
                            isSelected: !_showAllRounds,
                            onTap: () {
                              setState(() {
                                _showAllRounds = false;
                                _selectedKill = null;
                              });
                            },
                          ),
                          _ModeToggleButton(
                            label: 'All Rounds',
                            isSelected: _showAllRounds,
                            onTap: () {
                              setState(() {
                                _showAllRounds = true;
                                _selectedKill = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Legend Row
                Row(
                  children: [
                    _LegendDot(
                      color: _colorFriendly,
                      label: 'Your Kill ($yourKillsCount)',
                    ),
                    const SizedBox(width: 8),
                    _LegendDot(
                      color: _colorEnemy,
                      label: 'Your Death ($yourDeathsCount)',
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 13,
                          height: 13,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Mati (X)',
                          style: AppTextStyles.caption(
                            color: AppColors.textSecondary,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Filter Row: [Semuanya] vs [Aku Sendiri]
                Row(
                  children: [
                    Text(
                      'FILTER:',
                      style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: 'All',
                      isSelected: !_onlySelfEvents,
                      icon: Icons.groups_rounded,
                      onTap: () {
                        setState(() {
                          _onlySelfEvents = false;
                          _selectedKill = null;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    _FilterChipButton(
                      label: 'Me',
                      isSelected: _onlySelfEvents,
                      icon: Icons.person_rounded,
                      onTap: () {
                        setState(() {
                          _onlySelfEvents = true;
                          _selectedKill = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Step-by-step kill inspection scrubber
                _buildKillScrubber(displayKills),
              ],
            ),
          ),

          // 2D Minimap Canvas (Tanpa Garis, Icon Agent Merah & Biru dengan Marker X)
          if (displayKills.isEmpty)
            _buildEmptyState('No kill location data recorded')
          else
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(_selectedKill == null ? 14 : 0),
                bottomRight: Radius.circular(_selectedKill == null ? 14 : 0),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;

                    // Build list of all markers (killers & victims)
                    final markerWidgets = <Widget>[];

                    // Separate non-selected and selected markers to ensure selected renders on top
                    final unselectedMarkers = <Widget>[];
                    final selectedMarkers = <Widget>[];

                    final isAnyKillSelected = _selectedKill != null;

                    for (final kill in displayKills) {
                      final isSelected = _selectedKill == kill;
                      final markerOpacity = isAnyKillSelected
                          ? (isSelected ? 1.0 : 0.22)
                          : 1.0;

                      // 1. Killer Marker (if location is available)
                      if (kill.killerLocationX != null && kill.killerLocationY != null) {
                        final killerPos = _toMinimapOffset(
                          kill.killerLocationX!,
                          kill.killerLocationY!,
                          size,
                        );
                        final isFriendly = _isFriendlyKiller(kill);
                        final killerWidget = _buildAgentMarker(
                          offset: killerPos,
                          agentIconUrl: kill.killerAgentIconUrl,
                          agentName: kill.killerAgentName,
                          isFriendly: isFriendly,
                          isDead: false,
                          isSelf: kill.isKillerSelf,
                          isSelected: isSelected,
                          opacity: markerOpacity,
                          onTap: () {
                            setState(() {
                              _selectedKill = _selectedKill == kill ? null : kill;
                            });
                          },
                        );

                        if (isSelected) {
                          selectedMarkers.add(killerWidget);
                        } else {
                          unselectedMarkers.add(killerWidget);
                        }
                      }

                      // 2. Victim Marker (where player died, with prominent X)
                      if (kill.victimLocationX != null && kill.victimLocationY != null) {
                        final victimPos = _toMinimapOffset(
                          kill.victimLocationX!,
                          kill.victimLocationY!,
                          size,
                        );
                        final isFriendly = _isFriendlyVictim(kill);
                        final victimWidget = _buildAgentMarker(
                          offset: victimPos,
                          agentIconUrl: kill.victimAgentIconUrl,
                          agentName: kill.victimAgentName,
                          isFriendly: isFriendly,
                          isDead: true,
                          isSelf: kill.isVictimSelf,
                          isSelected: isSelected,
                          opacity: markerOpacity,
                          onTap: () {
                            setState(() {
                              _selectedKill = _selectedKill == kill ? null : kill;
                            });
                          },
                        );

                        if (isSelected) {
                          selectedMarkers.add(victimWidget);
                        } else {
                          unselectedMarkers.add(victimWidget);
                        }
                      }
                    }

                    markerWidgets.addAll(unselectedMarkers);
                    markerWidgets.addAll(selectedMarkers);

                    return Stack(
                      children: [
                        // Map Image
                        CachedNetworkImage(
                          imageUrl: match.mapMinimapUrl!,
                          width: size.width,
                          height: size.height,
                          fit: BoxFit.contain,
                          color: Colors.white.withValues(alpha: 0.85),
                          colorBlendMode: BlendMode.modulate,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(
                                Icons.map_outlined,
                                color: AppColors.textMuted,
                                size: 40,
                              ),
                            ),
                          ),
                        ),

                        // Subdued contrast overlay
                        Container(
                          color: Colors.black.withValues(alpha: 0.18),
                        ),

                        // Agent Icon Markers (Merah & Biru, X untuk yang mati, tanpa garis)
                        ...markerWidgets,
                      ],
                    );
                  },
                ),
              ),
            ),

          // Selected Kill Detail Callout Banner or Hint
          if (_selectedKill != null)
            _buildSelectedKillBanner(_selectedKill!, displayKills)
          else if (displayKills.isNotEmpty)
            _buildUnselectedPrompt(displayKills.length),
        ],
      ),
    );
  }

  Offset _toMinimapOffset(double worldX, double worldY, Size mapSize) {
    // Valorant coordinate transform to [0, 1] minimap space:
    // minimapX = (worldY * mapXMultiplier) + mapXScalarToAdd
    // minimapY = (worldX * mapYMultiplier) + mapYScalarToAdd
    final normX = ((worldY * widget.match.mapXMultiplier) + widget.match.mapXScalarToAdd).clamp(0.0, 1.0);
    final normY = ((worldX * widget.match.mapYMultiplier) + widget.match.mapYScalarToAdd).clamp(0.0, 1.0);
    return Offset(normX * mapSize.width, normY * mapSize.height);
  }

  Widget _buildAgentMarker({
    required Offset offset,
    required String? agentIconUrl,
    required String agentName,
    required bool isFriendly,
    required bool isDead,
    required bool isSelf,
    required bool isSelected,
    double opacity = 1.0,
    required VoidCallback onTap,
  }) {
    final ringColor = isFriendly ? _colorFriendly : _colorEnemy;
    final markerSize = isSelected ? 32.0 : 25.0;

    return Positioned(
      left: offset.dx - markerSize / 2,
      top: offset.dy - markerSize / 2,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : ringColor,
              width: isSelected ? 2.5 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? const Color(0xFFFFD700) : ringColor).withValues(
                  alpha: isSelected ? 0.8 : 0.45,
                ),
                blurRadius: isSelected ? 8 : 4,
                spreadRadius: isSelected ? 1.5 : 0.5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Agent Avatar Thumbnail
              Positioned.fill(
                child: ClipOval(
                  child: agentIconUrl != null && agentIconUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: agentIconUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _buildAgentFallback(agentName, ringColor),
                        )
                      : _buildAgentFallback(agentName, ringColor),
                ),
              ),

              // 2. Dead Marker X (Gelap + Tanda Silang X Tebal di atas Icon)
              if (isDead) ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: markerSize * 0.76,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // 3. Indicator "YOU" jika diri sendiri
              if (isSelf && !isDead) ...[
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD700),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildAgentFallback(String agentName, Color color) {
    final initial = agentName.isNotEmpty ? agentName[0].toUpperCase() : '?';
    return Container(
      color: AppColors.card,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildKillScrubber(List<MatchRoundKill> kills) {
    if (kills.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 4, bottom: 2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kills.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAllSelected = _selectedKill == null;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedKill = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isAllSelected
                      ? _colorFriendly.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: AppRadius.roundedPill,
                  border: Border.all(
                    color: isAllSelected ? _colorFriendly : AppColors.border,
                    width: isAllSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'ALL (${kills.length})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isAllSelected ? _colorFriendly : AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            );
          }

          final killIndex = index - 1;
          final kill = kills[killIndex];
          final isSelected = _selectedKill == kill;
          final isFriendlyKiller = _isFriendlyKiller(kill);
          final isFriendlyVictim = _isFriendlyVictim(kill);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedKill = kill;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFD700).withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: AppRadius.roundedPill,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFD700) : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${killIndex + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? const Color(0xFFFFD700) : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Killer avatar thumbnail
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFriendlyKiller ? _colorFriendly : _colorEnemy,
                        width: 1.2,
                      ),
                    ),
                    child: ClipOval(
                      child: kill.killerAgentIconUrl != null && kill.killerAgentIconUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: kill.killerAgentIconUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _buildAgentFallback(
                                kill.killerAgentName,
                                isFriendlyKiller ? _colorFriendly : _colorEnemy,
                              ),
                            )
                          : _buildAgentFallback(
                              kill.killerAgentName,
                              isFriendlyKiller ? _colorFriendly : _colorEnemy,
                            ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.bolt_rounded,
                    size: 11,
                    color: isSelected ? const Color(0xFFFFD700) : _colorFriendly,
                  ),
                  const SizedBox(width: 3),
                  // Victim avatar thumbnail with X
                  Stack(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFriendlyVictim ? _colorFriendly : _colorEnemy,
                            width: 1.2,
                          ),
                        ),
                        child: ClipOval(
                          child: kill.victimAgentIconUrl != null && kill.victimAgentIconUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: kill.victimAgentIconUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _buildAgentFallback(
                                    kill.victimAgentName,
                                    isFriendlyVictim ? _colorFriendly : _colorEnemy,
                                  ),
                                )
                              : _buildAgentFallback(
                                  kill.victimAgentName,
                                  isFriendlyVictim ? _colorFriendly : _colorEnemy,
                                ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedKillBanner(MatchRoundKill kill, List<MatchRoundKill> displayKills) {
    final isFriendlyKill = _isFriendlyKiller(kill);
    final isFriendlyVictim = _isFriendlyVictim(kill);
    final timeSec = kill.roundTime > 0 ? (kill.roundTime ~/ 1000) : 0;
    final timeStr = '${(timeSec ~/ 60).toString().padLeft(1, '0')}:${(timeSec % 60).toString().padLeft(2, '0')}';

    final currentIndex = displayKills.indexOf(kill);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex >= 0 && currentIndex < displayKills.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Step Prev Button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: hasPrev ? Colors.white : Colors.white24,
            ),
            onPressed: hasPrev
                ? () {
                    setState(() {
                      _selectedKill = displayKills[currentIndex - 1];
                    });
                  }
                : null,
          ),

          // Killer Info
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFriendlyKill ? _colorFriendly : _colorEnemy,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: kill.killerAgentIconUrl != null && kill.killerAgentIconUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: kill.killerAgentIconUrl!,
                            width: 22,
                            height: 22,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          )
                        : const SizedBox(width: 22, height: 22),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kill.killerName.isNotEmpty ? kill.killerName : kill.killerAgentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isFriendlyKill ? _colorFriendly : _colorEnemy,
                        ),
                      ),
                      Text(
                        kill.killerAgentName,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center VS / Time Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFFD700)),
              ],
            ),
          ),

          // Victim Info
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kill.victimName.isNotEmpty ? kill.victimName : kill.victimAgentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isFriendlyVictim ? _colorFriendly : _colorEnemy,
                        ),
                      ),
                      Text(
                        kill.victimAgentName,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFriendlyVictim ? _colorFriendly : _colorEnemy,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: kill.victimAgentIconUrl != null && kill.victimAgentIconUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: kill.victimAgentIconUrl!,
                                width: 22,
                                height: 22,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const SizedBox.shrink(),
                              )
                            : const SizedBox(width: 22, height: 22),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Step Next Button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: hasNext ? Colors.white : Colors.white24,
            ),
            onPressed: hasNext
                ? () {
                    setState(() {
                      _selectedKill = displayKills[currentIndex + 1];
                    });
                  }
                : null,
          ),

          // Close / Clear Selection
          InkWell(
            onTap: () => setState(() => _selectedKill = null),
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnselectedPrompt(int killCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            'Ketuk duel di atas untuk melihat duel satu per satu di map',
            style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.radar_rounded, size: 28, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.red.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: AppRadius.roundedSm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption(
            color: AppColors.textSecondary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedPill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: AppRadius.roundedPill,
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.cyan : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
