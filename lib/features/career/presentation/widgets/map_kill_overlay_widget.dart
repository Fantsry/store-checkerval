import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';

/// Interactive 2D minimap overlay showing kill & death positions per round
/// or overview of the entire match.
///
/// Uses the Valorant API map `displayIcon` as the minimap image and the
/// coordinate transform fields (`xMultiplier`, `yMultiplier`, `xScalarToAdd`,
/// `yScalarToAdd`) to convert in-game world coordinates to normalized [0,1]
/// positions on the minimap.
///
/// Kill indicators:
///   - Teal ring + glow = Your kills — where the victim died
///   - Red ring + cross = Your deaths — where you died
///   - Muted circle     = Other player kills
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

  @override
  Widget build(BuildContext context) {
    if (!widget.match.hasMinimapData) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.09),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.map_outlined,
                size: 32,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kill map not available for this map/mode',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Minimap data is not provided for some game modes',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
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
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
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
                          color: AppTheme.valorantCyan,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showAllRounds
                              ? 'MAP OVERVIEW — ALL ROUNDS'
                              : 'KILL MAP — ROUND ${safeRoundIdx + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),

                    // Toggle: Round vs All Rounds
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
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

                // Legend & Filter Row
                Row(
                  children: [
                    _LegendDot(
                      color: const Color(0xFF00C4A8),
                      label: 'Your Kill ($yourKillsCount)',
                    ),
                    const SizedBox(width: 8),
                    _LegendDot(
                      color: AppTheme.valorantRed,
                      label: 'Your Death ($yourDeathsCount)',
                    ),
                    const Spacer(),
                    // Filter "My Kills Only"
                    InkWell(
                      onTap: () => setState(() => _onlySelfEvents = !_onlySelfEvents),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _onlySelfEvents
                              ? AppTheme.valorantCyan.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _onlySelfEvents
                                ? AppTheme.valorantCyan.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _onlySelfEvents ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                              size: 11,
                              color: _onlySelfEvents ? AppTheme.valorantCyan : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _onlySelfEvents ? 'Mine Only' : 'All Players',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: _onlySelfEvents ? AppTheme.valorantCyan : AppTheme.textMuted,
                              ),
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

          // 2D Minimap Canvas
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
                    return Stack(
                      children: [
                        // Map Image
                        CachedNetworkImage(
                          imageUrl: match.mapMinimapUrl!,
                          width: size.width,
                          height: size.height,
                          fit: BoxFit.contain,
                          color: Colors.white.withValues(alpha: 0.8),
                          colorBlendMode: BlendMode.modulate,
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceDark,
                            child: const Center(
                              child: Icon(
                                Icons.map_outlined,
                                color: AppTheme.textMuted,
                                size: 40,
                              ),
                            ),
                          ),
                        ),

                        // Subdued contrast overlay
                        Container(
                          color: Colors.black.withValues(alpha: 0.22),
                        ),

                        // Direction vectors (if a kill is selected or for all your kills)
                        CustomPaint(
                          size: size,
                          painter: _KillVectorPainter(
                            match: match,
                            kills: _selectedKill != null
                                ? [_selectedKill!]
                                : displayKills.where((k) => k.isKillerSelf && k.killerLocationX != null).toList(),
                          ),
                        ),

                        // Kill position dots
                        ...displayKills.map(
                          (kill) => _buildKillMarker(kill, size),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // Selected Kill Detail Callout Banner
          if (_selectedKill != null)
            _buildSelectedKillBanner(_selectedKill!),
        ],
      ),
    );
  }

  Widget _buildKillMarker(MatchRoundKill kill, Size mapSize) {
    // Formula for converting Valorant in-game world coordinates to [0, 1] minimap coordinates:
    // minimapX = (worldY * mapXMultiplier) + mapXScalarToAdd
    // minimapY = (worldX * mapYMultiplier) + mapYScalarToAdd
    final victimX = kill.victimLocationX ?? 0;
    final victimY = kill.victimLocationY ?? 0;

    final normX = ((victimY * widget.match.mapXMultiplier) + widget.match.mapXScalarToAdd).clamp(0.0, 1.0);
    final normY = ((victimX * widget.match.mapYMultiplier) + widget.match.mapYScalarToAdd).clamp(0.0, 1.0);

    final left = normX * mapSize.width;
    final top = normY * mapSize.height;

    final isYourKill = kill.isKillerSelf;
    final isYourDeath = kill.isVictimSelf;
    final isSelected = _selectedKill == kill;

    Color dotColor;
    double dotSize;
    if (isSelected) {
      dotColor = const Color(0xFFFFD700);
      dotSize = 18;
    } else if (isYourKill) {
      dotColor = const Color(0xFF00C4A8);
      dotSize = 14;
    } else if (isYourDeath) {
      dotColor = AppTheme.valorantRed;
      dotSize = 14;
    } else {
      dotColor = Colors.white.withValues(alpha: 0.5);
      dotSize = 8;
    }

    return Positioned(
      left: left - dotSize / 2,
      top: top - dotSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedKill = _selectedKill == kill ? null : kill;
          });
        },
        child: _KillDotIndicator(
          color: dotColor,
          size: dotSize,
          isYourKill: isYourKill,
          isYourDeath: isYourDeath,
          isSelected: isSelected,
          agentIconUrl: isYourKill
              ? kill.victimAgentIconUrl
              : (isYourDeath ? kill.killerAgentIconUrl : null),
        ),
      ),
    );
  }

  Widget _buildSelectedKillBanner(MatchRoundKill kill) {
    final isYourKill = kill.isKillerSelf;
    final isYourDeath = kill.isVictimSelf;
    final timeSec = kill.roundTime > 0 ? (kill.roundTime ~/ 1000) : 0;
    final timeStr = '${(timeSec ~/ 60).toString().padLeft(1, '0')}:${(timeSec % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(
          top: BorderSide(
            color: (isYourKill
                    ? const Color(0xFF00C4A8)
                    : (isYourDeath ? AppTheme.valorantRed : Colors.white))
                .withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Killer icon + name
          if (kill.killerAgentIconUrl != null && kill.killerAgentIconUrl!.isNotEmpty)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: kill.killerAgentIconUrl!,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              kill.killerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isYourKill ? const Color(0xFF00C4A8) : AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.valorantCyan),
          const SizedBox(width: 6),
          // Victim icon + name
          if (kill.victimAgentIconUrl != null && kill.victimAgentIconUrl!.isNotEmpty)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: kill.victimAgentIconUrl!,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              kill.victimName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isYourDeath ? AppTheme.valorantRed : AppTheme.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          Text(
            timeStr,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => setState(() => _selectedKill = null),
            child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.radar_rounded, size: 28, color: AppTheme.textMuted),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.valorantRed.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _KillDotIndicator extends StatelessWidget {
  final Color color;
  final double size;
  final bool isYourKill;
  final bool isYourDeath;
  final bool isSelected;
  final String? agentIconUrl;

  const _KillDotIndicator({
    required this.color,
    required this.size,
    required this.isYourKill,
    required this.isYourDeath,
    required this.isSelected,
    this.agentIconUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.8),
        border: Border.all(
          color: isSelected ? Colors.white : color,
          width: (isYourKill || isYourDeath || isSelected) ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isYourKill || isYourDeath || isSelected)
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
      child: isYourDeath
          ? const Center(
              child: Icon(
                Icons.close_rounded,
                size: 8,
                color: Colors.white,
              ),
            )
          : (agentIconUrl != null && agentIconUrl!.isNotEmpty && size >= 14
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: agentIconUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                )
              : null),
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
          width: 7,
          height: 7,
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
          style: const TextStyle(
            fontSize: 9.5,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Custom painter to draw directional lines from killer to victim
class _KillVectorPainter extends CustomPainter {
  final MatchSummary match;
  final List<MatchRoundKill> kills;

  _KillVectorPainter({
    required this.match,
    required this.kills,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final kill in kills) {
      if (kill.killerLocationX == null ||
          kill.killerLocationY == null ||
          kill.victimLocationX == null ||
          kill.victimLocationY == null) {
        continue;
      }

      final killerNormX = ((kill.killerLocationY! * match.mapXMultiplier) + match.mapXScalarToAdd).clamp(0.0, 1.0);
      final killerNormY = ((kill.killerLocationX! * match.mapYMultiplier) + match.mapYScalarToAdd).clamp(0.0, 1.0);

      final victimNormX = ((kill.victimLocationY! * match.mapXMultiplier) + match.mapXScalarToAdd).clamp(0.0, 1.0);
      final victimNormY = ((kill.victimLocationX! * match.mapYMultiplier) + match.mapYScalarToAdd).clamp(0.0, 1.0);

      final start = Offset(killerNormX * size.width, killerNormY * size.height);
      final end = Offset(victimNormX * size.width, victimNormY * size.height);

      final paint = Paint()
        ..color = (kill.isKillerSelf
                ? const Color(0xFF00C4A8)
                : AppTheme.valorantRed)
            .withValues(alpha: 0.45)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KillVectorPainter oldDelegate) {
    return oldDelegate.kills != kills;
  }
}
