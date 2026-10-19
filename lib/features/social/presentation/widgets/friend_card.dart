import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';

class FriendCard extends StatefulWidget {
  final FriendEntity friend;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onRefreshTap;

  const FriendCard({
    super.key,
    required this.friend,
    this.onFavoriteTap,
    this.onDeleteTap,
    this.onRefreshTap,
  });

  @override
  State<FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<FriendCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _roundCelebrationController;
  late Animation<double> _roundScaleAnimation;
  late Animation<double> _roundGlowAnimation;

  String? _activeRoundOutcome; // 'ALLY_WON' or 'ENEMY_WON'
  Timer? _outcomeBannerTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _roundCelebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _roundScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _roundCelebrationController,
        curve: Curves.elasticOut,
      ),
    );

    _roundGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _roundCelebrationController,
        curve: Curves.easeOut,
      ),
    );

    if (widget.friend.isPlaying) {
      _pulseController.repeat(reverse: true);
    }

    // Check if friend has a recent round outcome (within 20s)
    final lastOutcome = widget.friend.liveActivity?.lastRoundOutcome;
    final lastTime = widget.friend.liveActivity?.lastRoundUpdateTime;
    if (lastOutcome != null && lastTime != null) {
      final diff = DateTime.now().difference(lastTime).inSeconds;
      if (diff < 15) {
        _activeRoundOutcome = lastOutcome;
        _roundCelebrationController.forward(from: 0.0);
        _outcomeBannerTimer = Timer(Duration(seconds: 15 - diff), () {
          if (mounted) {
            setState(() => _activeRoundOutcome = null);
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(FriendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.friend.isPlaying && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.friend.isPlaying && _pulseController.isAnimating) {
      _pulseController.stop();
    }

    // Detect score increments to trigger Valorant round win / loss animation
    final oldAct = oldWidget.friend.liveActivity;
    final newAct = widget.friend.liveActivity;
    if (newAct != null && oldAct != null) {
      final oldAlly = oldAct.scoreAlly ?? 0;
      final newAlly = newAct.scoreAlly ?? 0;
      final oldEnemy = oldAct.scoreEnemy ?? 0;
      final newEnemy = newAct.scoreEnemy ?? 0;

      if (newAlly > oldAlly) {
        _triggerRoundOutcome('ALLY_WON');
      } else if (newEnemy > oldEnemy) {
        _triggerRoundOutcome('ENEMY_WON');
      }
    }
  }

  void _triggerRoundOutcome(String outcome) {
    if (!mounted) return;
    setState(() {
      _activeRoundOutcome = outcome;
    });

    if (outcome == 'ALLY_WON') {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    _roundCelebrationController.forward(from: 0.0);

    _outcomeBannerTimer?.cancel();
    _outcomeBannerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _activeRoundOutcome = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _roundCelebrationController.dispose();
    _outcomeBannerTimer?.cancel();
    super.dispose();
  }

  void _copyRiotId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.friend.displayName));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Riot ID "${widget.friend.displayName}" disalin!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color get _statusColor {
    switch (widget.friend.status) {
      case FriendLiveStatus.inGame:
        return AppColors.red;
      case FriendLiveStatus.inAgentSelect:
        return AppColors.drawAmber;
      case FriendLiveStatus.inLobby:
        return AppColors.winGreen;
      case FriendLiveStatus.away:
        return const Color(0xFFEAB308);
      case FriendLiveStatus.offline:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final hasWideArt = friend.cardWideArt != null && friend.cardWideArt!.isNotEmpty;
    final hasSmallArt = friend.cardSmallArt != null && friend.cardSmallArt!.isNotEmpty;
    final isPlaying = friend.isPlaying;

    return AscendCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.lg,
      borderColor: isPlaying
          ? _statusColor.withValues(alpha: 0.6)
          : (friend.isFavorite
              ? AppColors.vpGold.withValues(alpha: 0.4)
              : AppColors.border),
      hasGlow: isPlaying,
      glowColor: _statusColor,
      child: ClipRRect(
        borderRadius: AppRadius.roundedLg,
        child: Stack(
          children: [
            // ─── 1. Player Card Wide Banner Background ───────────────
            if (hasWideArt)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: friend.cardWideArt!,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // ─── 2. Gradient Overlay for Readability ────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: hasWideArt ? const [0.0, 0.45, 0.8, 1.0] : null,
                    colors: hasWideArt
                        ? [
                            AppColors.background.withValues(alpha: 0.98),
                            AppColors.background.withValues(alpha: 0.85),
                            AppColors.background.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.35),
                          ]
                        : [
                            AppColors.card.withValues(alpha: 0.98),
                            AppColors.cardElevated.withValues(alpha: 0.95),
                          ],
                  ),
                ),
              ),
            ),

            // Subtle Status Top Tint
            if (isPlaying)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: _statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

            // ─── 3. Card Content ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar, Names, Title, Favorite & Actions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Player Card Avatar with Level Badge
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.roundedMd,
                              border: Border.all(
                                color: isPlaying ? _statusColor : AppColors.border,
                                width: 1.5,
                              ),
                              boxShadow: isPlaying
                                  ? [
                                      BoxShadow(
                                        color: _statusColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: hasSmallArt
                                  ? CachedNetworkImage(
                                      imageUrl: friend.cardSmallArt!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          _buildAvatarPlaceholder(),
                                    )
                                  : _buildAvatarPlaceholder(),
                            ),
                          ),
                          // Level badge pill
                          Positioned(
                            bottom: -7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${friend.accountLevel}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cyan,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Name, Tag & Card Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    friend.gameName.toUpperCase(),
                                    style: AppTextStyles.h4(
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (friend.tagLine.isNotEmpty)
                                  Text(
                                    ' #${friend.tagLine}',
                                    style: AppTextStyles.caption(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                            if (friend.cardName != null &&
                                friend.cardName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  friend.cardName!.toUpperCase(),
                                  style: AppTextStyles.badge(
                                    color: AppColors.cyan.withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Actions: Favorite & Menu
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              friend.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: friend.isFavorite
                                  ? AppColors.vpGold
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: friend.isFavorite
                                ? 'Hapus dari Favorit'
                                : 'Jadikan Favorit',
                            onPressed: widget.onFavoriteTap,
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            color: AppColors.cardElevated,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.roundedMd,
                              side: const BorderSide(color: AppColors.border),
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'copy') {
                                _copyRiotId(context);
                              } else if (value == 'favorite') {
                                widget.onFavoriteTap?.call();
                              } else if (value == 'delete') {
                                widget.onDeleteTap?.call();
                              } else if (value == 'win_round') {
                                context.read<SocialCubit>().simulateRoundWon(widget.friend.puuid);
                              } else if (value == 'lose_round') {
                                context.read<SocialCubit>().simulateRoundLost(widget.friend.puuid);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'copy',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_rounded,
                                        size: 16, color: AppColors.cyan),
                                    SizedBox(width: 8),
                                    Text('Salin Riot ID',
                                        style: TextStyle(
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'favorite',
                                child: Row(
                                  children: [
                                    Icon(
                                      friend.isFavorite
                                          ? Icons.star_border_rounded
                                          : Icons.star_rounded,
                                      size: 16,
                                      color: AppColors.vpGold,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      friend.isFavorite
                                          ? 'Hapus Favorit'
                                          : 'Bintang Favorit',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              if (isPlaying) ...[
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'win_round',
                                  child: Row(
                                    children: [
                                      Icon(Icons.emoji_events_rounded,
                                          size: 16, color: AppColors.winGreen),
                                      SizedBox(width: 8),
                                      Text('Simulasi Round Win (+Ally)',
                                          style: TextStyle(
                                              color: AppColors.winGreen)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'lose_round',
                                  child: Row(
                                    children: [
                                      Icon(Icons.close_rounded,
                                          size: 16, color: AppColors.red),
                                      SizedBox(width: 8),
                                      Text('Simulasi Enemy Win (+Musuh)',
                                          style: TextStyle(
                                              color: AppColors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_remove_rounded,
                                        size: 16, color: AppColors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus dari Squad',
                                        style: TextStyle(color: AppColors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ─── Live Activity HUD Banner ─────────────────────
                  _buildLiveStatusBanner(),

                  const SizedBox(height: AppSpacing.sm + 2),

                  // ─── Bottom Row: Rank & Quick Action ───────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rank Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (friend.rankIcon != null &&
                              friend.rankIcon!.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: friend.rankIcon!,
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) =>
                                  GemRankIcon(tierName: friend.rankName ?? 'Unranked', size: 26),
                            )
                          else
                            GemRankIcon(tierName: friend.rankName ?? 'Unranked', size: 26),
                          const SizedBox(width: AppSpacing.xs),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (friend.rankName ?? 'Unranked').toUpperCase(),
                                style: AppTextStyles.caption(
                                  color: AppColors.getRankColor(friend.rankName),
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (friend.rankedRating > 0)
                                Text(
                                  '${friend.rankedRating} RR',
                                  style: AppTextStyles.badge(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Quick Action: Live Spectate or Copy
                      if (isPlaying)
                        ElevatedButton.icon(
                          onPressed: () => context.push('/live-match'),
                          icon: const Icon(Icons.radar_rounded, size: 14),
                          label: const Text('SPECTATE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red.withValues(alpha: 0.2),
                            foregroundColor: AppColors.red,
                            elevation: 0,
                            side: const BorderSide(color: AppColors.red, width: 1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            textStyle: AppTextStyles.badge(color: AppColors.red)
                                .copyWith(fontWeight: FontWeight.w800),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.roundedSm,
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _copyRiotId(context),
                          borderRadius: AppRadius.roundedSm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'COPY ID',
                                  style: AppTextStyles.badge(
                                    color: AppColors.textMuted,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.textMuted,
        size: 26,
      ),
    );
  }

  Widget _buildLiveStatusBanner() {
    final status = widget.friend.status;
    final activity = widget.friend.liveActivity;

    switch (status) {
      case FriendLiveStatus.inGame:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Valorant Round Won / Lost Announcement Flash ────────
            if (_activeRoundOutcome != null) _buildRoundOutcomeBanner(),

            // ── Valorant Broadcast In-Game HUD Box ───────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.65),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: _activeRoundOutcome == 'ALLY_WON'
                      ? AppColors.winGreen.withValues(alpha: 0.7)
                      : (_activeRoundOutcome == 'ENEMY_WON'
                          ? AppColors.red.withValues(alpha: 0.7)
                          : AppColors.red.withValues(alpha: 0.35)),
                  width: _activeRoundOutcome != null ? 1.5 : 1,
                ),
                boxShadow: _activeRoundOutcome != null
                    ? [
                        BoxShadow(
                          color: (_activeRoundOutcome == 'ALLY_WON'
                                  ? AppColors.winGreen
                                  : AppColors.red)
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Meta Row: Live dot, Mode, Map, Duration, Match Point/Overtime
                  Row(
                    children: [
                      // Animated Pulse Dot
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 7 * _pulseAnimation.value,
                            height: 7 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.red,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.red.withValues(alpha: 0.6),
                                  blurRadius: 5 * _pulseAnimation.value,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Text(
                        (activity?.modeName ?? 'MATCH').toUpperCase(),
                        style: AppTextStyles.badge(color: AppColors.red).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (activity?.mapName != null) ...[
                        const SizedBox(width: 4),
                        Text('•', style: AppTextStyles.caption(color: AppColors.textMuted)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            activity!.mapName!.toUpperCase(),
                            style: AppTextStyles.caption(color: AppColors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (activity?.isMatchPoint == true)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.vpGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: AppColors.vpGold.withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            'MATCH POINT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppColors.vpGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else if (activity?.isOvertime == true)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.drawAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: AppColors.drawAmber.withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            'OVERTIME',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppColors.drawAmber,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (activity?.durationDisplay.isNotEmpty == true)
                        Text(
                          activity!.durationDisplay,
                          style: AppTextStyles.badge(color: AppColors.textSecondary),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Center Tactical Scoreboard HUD
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ALLY Side
                        Row(
                          children: [
                            if (activity?.agentIcon != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: activity!.agentIcon!,
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALLY',
                                  style: AppTextStyles.badge(color: AppColors.winGreen).copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                if (activity?.agentName != null)
                                  Text(
                                    activity!.agentName!,
                                    style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                                      fontSize: 9,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Score Numbers in Center with Pop Transition
                        Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) => ScaleTransition(
                                scale: anim,
                                child: child,
                              ),
                              child: Text(
                                '${activity?.scoreAlly ?? 0}',
                                key: ValueKey<int>(activity?.scoreAlly ?? 0),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.winGreen,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textMuted.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) => ScaleTransition(
                                scale: anim,
                                child: child,
                              ),
                              child: Text(
                                '${activity?.scoreEnemy ?? 0}',
                                key: ValueKey<int>(activity?.scoreEnemy ?? 0),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ENEMY Side
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'ENEMY',
                                  style: AppTextStyles.badge(color: AppColors.red).copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'R${activity?.currentRound ?? 1}',
                                  style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                              ),
                              child: const Icon(Icons.shield_outlined, size: 14, color: AppColors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Round Timeline Pips ─────────────────────────────
                  _buildRoundTimelinePips(activity),

                  const SizedBox(height: AppSpacing.sm),

                  // ── In-Game Simulation Bar ──────────────────────────
                  _buildRoundSimulationBar(),
                ],
              ),
            ),
          ],
        );

      case FriendLiveStatus.inAgentSelect:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.drawAmber.withValues(alpha: 0.12),
            borderRadius: AppRadius.roundedSm,
            border: Border.all(
              color: AppColors.drawAmber.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.drawAmber,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'AGENT SELECT • ${(activity?.mapName ?? 'MATCH').toUpperCase()}',
                  style: AppTextStyles.badge(color: AppColors.drawAmber).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                (activity?.modeName ?? 'PREGAME').toUpperCase(),
                style: AppTextStyles.badge(color: AppColors.textSecondary),
              ),
            ],
          ),
        );

      case FriendLiveStatus.inLobby:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.winGreen.withValues(alpha: 0.1),
            borderRadius: AppRadius.roundedSm,
            border: Border.all(
              color: AppColors.winGreen.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.winGreen,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'IN LOBBY • READY TO PLAY',
                  style: AppTextStyles.badge(color: AppColors.winGreen).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (activity?.partySize != null)
                Text(
                  'Party ${activity!.partySize}/${activity.maxPartySize ?? 5}',
                  style: AppTextStyles.badge(color: AppColors.textSecondary),
                ),
            ],
          ),
        );

      case FriendLiveStatus.away:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAB308).withValues(alpha: 0.1),
            borderRadius: AppRadius.roundedSm,
            border: Border.all(
              color: const Color(0xFFEAB308).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAB308),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.friend.clientActivity ?? 'AWAY',
                  style: AppTextStyles.badge(color: const Color(0xFFEAB308)).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.friend.isMobile)
                const Icon(
                  Icons.phone_android_rounded,
                  size: 14,
                  color: Color(0xFFEAB308),
                ),
            ],
          ),
        );

      case FriendLiveStatus.offline:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6),
            borderRadius: AppRadius.roundedSm,
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'OFFLINE',
                style: AppTextStyles.badge(color: AppColors.textMuted).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildRoundOutcomeBanner() {
    final isAlly = _activeRoundOutcome == 'ALLY_WON';
    final accentColor = isAlly ? AppColors.winGreen : AppColors.red;
    final title = isAlly ? 'ROUND WON' : 'ROUND LOST';
    final subtext = isAlly
        ? '+1 POINT ALLY • SPIKE DEFUSED / ELIMINATED'
        : '+1 POINT ENEMY • SPIKE DETONATED / ELIMINATED';
    final icon = isAlly ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return AnimatedBuilder(
      animation: _roundCelebrationController,
      builder: (context, child) {
        final scale = _roundScaleAnimation.value;
        final opacity = _roundCelebrationController.value.clamp(0.0, 1.0);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAlly
                      ? [
                          AppColors.winGreen.withValues(alpha: 0.28),
                          AppColors.background.withValues(alpha: 0.95),
                        ]
                      : [
                          AppColors.red.withValues(alpha: 0.32),
                          AppColors.background.withValues(alpha: 0.95),
                        ],
                ),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: accentColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: 0.35 + (_roundGlowAnimation.value * 0.25),
                    ),
                    blurRadius: 8 + (_roundGlowAnimation.value * 8),
                    spreadRadius: _roundGlowAnimation.value * 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                isAlly ? 'VICTORY' : 'DEFEAT',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtext,
                          style: AppTextStyles.badge(color: AppColors.textPrimary)
                              .copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: accentColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      widget.friend.liveActivity?.scoreDisplay ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoundTimelinePips(FriendLiveActivity? activity) {
    if (activity == null) return const SizedBox.shrink();
    final history = activity.roundHistory;
    final target = activity.targetScore;
    final isSwiftplay = target <= 5;
    final totalSlots = isSwiftplay ? 9 : 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ROUND TIMELINE',
              style: AppTextStyles.badge(color: AppColors.textSecondary).copyWith(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'First to $target Wins',
              style: AppTextStyles.badge(color: AppColors.textMuted).copyWith(
                fontSize: 8.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              history.length < totalSlots ? totalSlots : history.length + 1,
              (index) {
                final isCurrent = index == history.length;
                final isPast = index < history.length;
                final isHalftime = !isSwiftplay && index == 12;

                Color pipColor;
                BoxBorder? border;
                List<BoxShadow>? shadows;

                if (isPast) {
                  final won = history[index];
                  pipColor = won ? AppColors.winGreen : AppColors.red;
                  shadows = [
                    BoxShadow(
                      color: pipColor.withValues(alpha: 0.4),
                      blurRadius: 3,
                    ),
                  ];
                } else if (isCurrent) {
                  pipColor = AppColors.drawAmber;
                  border = Border.all(color: AppColors.drawAmber, width: 1.2);
                  shadows = [
                    BoxShadow(
                      color: AppColors.drawAmber.withValues(alpha: 0.6),
                      blurRadius: 5,
                    ),
                  ];
                } else {
                  pipColor = AppColors.surface.withValues(alpha: 0.5);
                  border = Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 0.8,
                  );
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isHalftime)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 1.5,
                        height: 12,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                    Tooltip(
                      message: isPast
                          ? 'Round ${index + 1}: ${history[index] ? "Ally Won" : "Enemy Won"}'
                          : (isCurrent
                              ? 'Round ${index + 1}: In Progress'
                              : 'Round ${index + 1}'),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: isCurrent ? 8 : 6.5,
                        height: isCurrent ? 12 : 9.5,
                        decoration: BoxDecoration(
                          color: pipColor,
                          borderRadius: BorderRadius.circular(2),
                          border: border,
                          boxShadow: shadows,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundSimulationBar() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              context.read<SocialCubit>().simulateRoundWon(widget.friend.puuid);
            },
            borderRadius: AppRadius.roundedSm,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4.5),
              decoration: BoxDecoration(
                color: AppColors.winGreen.withValues(alpha: 0.12),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: AppColors.winGreen.withValues(alpha: 0.45),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 13, color: AppColors.winGreen),
                  SizedBox(width: 3),
                  Text(
                    'WIN ROUND',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.winGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: InkWell(
            onTap: () {
              context.read<SocialCubit>().simulateRoundLost(widget.friend.puuid);
            },
            borderRadius: AppRadius.roundedSm,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4.5),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.12),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: AppColors.red.withValues(alpha: 0.45),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 13, color: AppColors.red),
                  SizedBox(width: 3),
                  Text(
                    'ENEMY WIN',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.red,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
