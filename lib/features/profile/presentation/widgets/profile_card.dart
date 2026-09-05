import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';

class ProfileCard extends StatelessWidget {
  final VoidCallback? onSignInTap;

  const ProfileCard({super.key, this.onSignInTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          return _ActiveProfileCard(profile: state.profile);
        } else if (state is ProfileLoading && state.cachedProfile != null) {
          return _ActiveProfileCard(
            profile: state.cachedProfile!,
            isRefreshing: true,
          );
        } else if (state is ProfileLoading) {
          return const _ProfileCardShimmer();
        } else if (state is ProfileError && state.cachedProfile != null) {
          return _ActiveProfileCard(profile: state.cachedProfile!);
        } else {
          return _UnauthenticatedProfileCard(onSignInTap: onSignInTap);
        }
      },
    );
  }
}

class _ActiveProfileCard extends StatelessWidget {
  final UserProfile profile;
  final bool isRefreshing;

  const _ActiveProfileCard({
    required this.profile,
    this.isRefreshing = false,
  });

  void _copyRiotId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: profile.displayName));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Riot ID "${profile.displayName}" disalin ke clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWideArt =
        profile.cardWideArt != null && profile.cardWideArt!.isNotEmpty;
    final hasSmallArt =
        profile.cardSmallArt != null && profile.cardSmallArt!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.valorantRed.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.valorantRed.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ─── 1. Background Wide Art ───────────────────────
            if (hasWideArt)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: profile.cardWideArt!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // ─── 2. Atmospheric Gradient Overlay ──────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0F1722).withValues(alpha: 0.96),
                      const Color(0xFF0F1722).withValues(alpha: 0.88),
                      const Color(0xFF141F2D).withValues(alpha: 0.70),
                    ],
                  ),
                ),
              ),
            ),

            // Subtle Red Accent Lines / Ambient Glow
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.valorantRed.withValues(alpha: 0.15),
                ),
              ),
            ),

            // ─── 3. Card Content ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar, Name, Title, Actions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with Level Badge
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.valorantRed,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.valorantRed
                                      .withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: hasSmallArt
                                  ? CachedNetworkImage(
                                      imageUrl: profile.cardSmallArt!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: AppTheme.surfaceLight,
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppTheme.surfaceLight,
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppTheme.surfaceLight,
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: AppTheme.valorantRed,
                                        size: 32,
                                      ),
                                    ),
                            ),
                          ),
                          // Level Badge
                          Positioned(
                            bottom: -7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2733),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.valorantRed,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    size: 10,
                                    color: AppTheme.valorantRed,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${profile.accountLevel}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Player Details (Name, Tag, Title, Region)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Game Name & TagLine + Copy Button
                            InkWell(
                              onTap: () => _copyRiotId(context),
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: profile.gameName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          if (profile.tagLine.isNotEmpty)
                                            TextSpan(
                                              text: ' #${profile.tagLine}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.valorantRed
                                                    .withValues(alpha: 0.9),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Player Title
                            if (profile.titleText != null &&
                                profile.titleText!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  profile.titleText!.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: Color(0xFFFFDF78),
                                  ),
                                ),
                              ),

                            // Region & Card Name Pills
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _InfoChip(
                                  icon: Icons.public_rounded,
                                  text:
                                      '${profile.region.toUpperCase()} (${profile.shard})',
                                  color: Colors.cyanAccent,
                                ),
                                if (profile.cardName != null)
                                  _InfoChip(
                                    icon: Icons.style_rounded,
                                    text: profile.cardName!,
                                    color: Colors.white70,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Refresh Icon Button
                      IconButton(
                        tooltip: 'Muat ulang profil',
                        icon: isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.valorantRed,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                        onPressed: () {
                          context
                              .read<ProfileCubit>()
                              .loadProfile(forceRefresh: true);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),

                  const SizedBox(height: 12),

                  // Bottom Row: Live Wallet Balances (VP, RP, KC)
                  Row(
                    children: [
                      // VP Chip
                      _WalletChip(
                        icon: Icons.monetization_on_outlined,
                        iconColor: AppTheme.valorantRed,
                        amount: profile.valorantPoints,
                        symbol: 'VP',
                      ),
                      const SizedBox(width: 8),

                      // RP Chip
                      _WalletChip(
                        icon: Icons.change_circle_outlined,
                        iconColor: Colors.cyanAccent,
                        amount: profile.radianitePoints,
                        symbol: 'RP',
                      ),
                      const SizedBox(width: 8),

                      // Kingdom Credits Chip
                      _WalletChip(
                        icon: Icons.workspace_premium_rounded,
                        iconColor: const Color(0xFFFFD700),
                        amount: profile.kingdomCredits,
                        symbol: 'KC',
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int amount;
  final String symbol;

  const _WalletChip({
    required this.icon,
    required this.iconColor,
    required this.amount,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$amount $symbol',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnauthenticatedProfileCard extends StatelessWidget {
  final VoidCallback? onSignInTap;

  const _UnauthenticatedProfileCard({this.onSignInTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.valorantRed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.valorantRed.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  color: AppTheme.valorantRed,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riot Account Belum Masuk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hubungkan akun Riot untuk memuat kartu profil dan rotasi store.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSignInTap ?? () => context.pushNamed('login'),
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('SIGN IN WITH RIOT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCardShimmer extends StatelessWidget {
  const _ProfileCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surfaceLight,
        highlightColor: AppTheme.surfaceDark,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 90,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 110,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
