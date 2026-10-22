import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';

String? resolveBannerArtUrl({
  String? wideArt,
  String? largeArt,
  String? smallArt,
}) {
  for (final candidate in [wideArt, largeArt, smallArt]) {
    final value = candidate?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

class PlayerBannerArt extends StatelessWidget {
  final String? wideArt;
  final String? largeArt;
  final String? smallArt;
  final Alignment alignment;
  final bool showFallbackIcon;

  const PlayerBannerArt({
    super.key,
    this.wideArt,
    this.largeArt,
    this.smallArt,
    this.alignment = Alignment.centerRight,
    this.showFallbackIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final artUrl = resolveBannerArtUrl(
      wideArt: wideArt,
      largeArt: largeArt,
      smallArt: smallArt,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(320, 2400)
                  .toInt()
            : null;

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.surface),
            if (showFallbackIcon)
              Align(
                key: const Key('player-banner-fallback'),
                alignment: alignment,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xl),
                  child: Icon(
                    Icons.person_rounded,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                  ),
                ),
              ),
            if (artUrl != null)
              CachedNetworkImage(
                imageUrl: artUrl,
                fit: BoxFit.cover,
                alignment: alignment,
                fadeInDuration: const Duration(milliseconds: 180),
                fadeInCurve: Curves.easeOut,
                memCacheWidth: cacheWidth,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xE60C0E11),
                    Color(0x990C0E11),
                    Color(0x1A0C0E11),
                  ],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD90C0E11)],
                  stops: [0.35, 1],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PlayerBannerCard extends StatelessWidget {
  final String? wideArt;
  final String? largeArt;
  final String? smallArt;
  final String displayName;
  final String? title;
  final String? badge;
  final String? meta;
  final Widget? trailing;
  final Widget? footer;
  final double height;
  final Alignment alignment;
  final VoidCallback? onTap;

  const PlayerBannerCard({
    super.key,
    this.wideArt,
    this.largeArt,
    this.smallArt,
    required this.displayName,
    this.title,
    this.badge,
    this.meta,
    this.trailing,
    this.footer,
    this.height = 176,
    this.alignment = Alignment.centerRight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: AppRadius.roundedLg,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadius.roundedLg,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PlayerBannerArt(
                wideArt: wideArt,
                largeArt: largeArt,
                smallArt: smallArt,
                alignment: alignment,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (badge != null)
                          _BannerBadge(text: badge!)
                        else
                          const SizedBox.shrink(),
                        const Spacer(),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    const Spacer(),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h1(color: AppColors.textPrimary),
                    ),
                    if (title != null && title!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(
                          color: AppColors.accentSoft,
                        ),
                      ),
                    ],
                    if (meta != null && meta!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.statLabel(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      footer!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

class _BannerBadge extends StatelessWidget {
  final String text;

  const _BannerBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.statLabel(color: AppColors.accent),
      ),
    );
  }
}
