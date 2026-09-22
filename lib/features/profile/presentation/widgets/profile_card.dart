import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
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
        backgroundColor: AppTheme.cardDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: AppTheme.accentMagenta.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.accentMagenta),
            SizedBox(width: 8),
            Text(
              'LOGOUT AKUN',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin logout dari akun Riot ini? Sesi login dan token akan dibersihkan.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'BATAL',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMagenta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await context.read<AuthCubit>().logout();
      if (context.mounted) {
        context.read<ProfileCubit>().clearProfile();
        context.goNamed('login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveWideArt = (profile.cardWideArt != null && profile.cardWideArt!.isNotEmpty)
        ? profile.cardWideArt!
        : (profile.cardLargeArt ?? '');
    final effectiveSmallArt = (profile.cardSmallArt != null && profile.cardSmallArt!.isNotEmpty)
        ? profile.cardSmallArt!
        : (profile.cardWideArt ?? profile.cardLargeArt ?? '');

    final hasWideArt = effectiveWideArt.isNotEmpty;
    final hasSmallArt = effectiveSmallArt.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentMagenta.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentMagenta.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // ─── 1. Background Wide Art ───────────────────────
            if (hasWideArt)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: effectiveWideArt,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
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
                    stops: hasWideArt ? const [0.0, 0.40, 0.75, 1.0] : null,
                    colors: hasWideArt
                        ? [
                            const Color(0xFF0B0C10).withValues(alpha: 0.95),
                            const Color(0xFF0B0C10).withValues(alpha: 0.75),
                            const Color(0xFF0B0C10).withValues(alpha: 0.30),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFF0B0C10).withValues(alpha: 0.98),
                            const Color(0xFF0B0C10).withValues(alpha: 0.90),
                            const Color(0xFF121319).withValues(alpha: 0.75),
                          ],
                  ),
                ),
              ),
            ),

            // Subtle Magenta Accent Glow
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentMagenta.withValues(alpha: 0.12),
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
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.accentMagenta,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentMagenta
                                      .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: hasSmallArt
                                  ? CachedNetworkImage(
                                      imageUrl: effectiveSmallArt,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: AppTheme.surfaceDark,
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppTheme.surfaceDark,
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppTheme.surfaceDark,
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: AppTheme.accentMagenta,
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
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppTheme.accentMagenta,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    size: 9,
                                    color: AppTheme.accentMagenta,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${profile.accountLevel}',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 11,
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
                              borderRadius: BorderRadius.circular(4),
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
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          if (profile.tagLine.isNotEmpty)
                                            TextSpan(
                                              text: ' #${profile.tagLine}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.accentMagenta
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
                                    size: 13,
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
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  profile.titleText!.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
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

                      // Action Buttons (Refresh & Logout)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Muat ulang profil',
                            icon: isRefreshing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.accentMagenta,
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
                          IconButton(
                            tooltip: 'Logout akun Riot',
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 20,
                              color: AppTheme.accentMagenta,
                            ),
                            onPressed: () => _showLogoutDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),

                  const SizedBox(height: 12),

                  // Bottom Row: Live Wallet Balances (VP, RP, KC)
                  Row(
                    children: [
                      // VP Chip
                      _WalletChip(
                        icon: Icons.monetization_on_outlined,
                        iconColor: const Color(0xFFE5B94E),
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

                  const SizedBox(height: 12),

                  // Logout Action Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentMagenta,
                        side: BorderSide(
                          color: AppTheme.accentMagenta.withValues(alpha: 0.4),
                          width: 1,
                        ),
                        backgroundColor:
                            AppTheme.accentMagenta.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text(
                        'LOGOUT AKUN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      onPressed: () => _showLogoutDialog(context),
                    ),
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
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(4),
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
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
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
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentMagenta.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.accentMagenta.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  color: AppTheme.accentMagenta,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RIOT ACCOUNT BELUM MASUK',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hubungkan akun Riot untuk memuat kartu profil dan rotasi store.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
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
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surfaceLight.withValues(alpha: 0.3),
        highlightColor: AppTheme.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
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
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
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
