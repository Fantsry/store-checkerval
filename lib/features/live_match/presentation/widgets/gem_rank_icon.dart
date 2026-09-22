import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';

/// Official Valorant rank badge icon widget using authentic Riot Games assets.
class ValorantRankIcon extends StatelessWidget {
  final String? iconUrl;
  final int? tier;
  final String tierName;
  final double size;
  final bool showGlow;
  final bool isCurrent;

  const ValorantRankIcon({
    super.key,
    this.iconUrl,
    this.tier,
    this.tierName = 'Unrated',
    this.size = 24,
    this.showGlow = false,
    this.isCurrent = false,
  });

  /// Map common Valorant tier names to official tier index (0 - 27).
  static int tierNameToIndex(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.contains('radiant')) return 27;
    if (clean.contains('immortal 3')) return 26;
    if (clean.contains('immortal 2')) return 25;
    if (clean.contains('immortal')) return 24;
    if (clean.contains('ascendant 3')) return 23;
    if (clean.contains('ascendant 2')) return 22;
    if (clean.contains('ascendant')) return 21;
    if (clean.contains('diamond 3')) return 20;
    if (clean.contains('diamond 2')) return 19;
    if (clean.contains('diamond')) return 18;
    if (clean.contains('platinum 3')) return 17;
    if (clean.contains('platinum 2')) return 16;
    if (clean.contains('platinum')) return 15;
    if (clean.contains('gold 3')) return 14;
    if (clean.contains('gold 2')) return 13;
    if (clean.contains('gold')) return 12;
    if (clean.contains('silver 3')) return 11;
    if (clean.contains('silver 2')) return 10;
    if (clean.contains('silver')) return 9;
    if (clean.contains('bronze 3')) return 8;
    if (clean.contains('bronze 2')) return 7;
    if (clean.contains('bronze')) return 6;
    if (clean.contains('iron 3')) return 5;
    if (clean.contains('iron 2')) return 4;
    if (clean.contains('iron')) return 3;
    return 0; // Unrated / Unranked
  }

  /// Official Valorant-API.com competitive tiers image URL.
  static String getOfficialTierIconUrl(int tier) {
    return 'https://media.valorant-api.com/competitivetiers/03621f52-342b-449e-a4f6-4eb2b294d734/$tier/largeicon.png';
  }

  String _resolveImageUrl() {
    if (iconUrl != null && iconUrl!.trim().isNotEmpty) {
      return iconUrl!.trim();
    }
    final tierIndex = tier ?? tierNameToIndex(tierName);
    return getOfficialTierIconUrl(tierIndex);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getRankTierColor(tierName);
    final isUnranked = tierName.toLowerCase() == 'unranked' ||
        tierName.toLowerCase() == 'unrated' ||
        (tier == 0) ||
        tierName.isEmpty;
    final imageUrl = _resolveImageUrl();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Esports subtle ambient glow behind the official badge
          if (showGlow && !isUnranked)
            Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: size * 0.45,
                    spreadRadius: size * 0.05,
                  ),
                ],
              ),
            ),

          // Authentic Riot Games Valorant Rank Icon from official CDN
          CachedNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholder: (context, url) => SizedBox(
              width: size * 0.6,
              height: size * 0.6,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.accentMagenta,
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              // Fallback to small icon URL if largeicon failed, or unrated badge
              if (url.contains('largeicon.png')) {
                return CachedNetworkImage(
                  imageUrl: url.replaceAll('largeicon.png', 'smallicon.png'),
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) =>
                      _buildFallbackBadge(color, isUnranked),
                );
              }
              return _buildFallbackBadge(color, isUnranked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBadge(Color color, bool isUnranked) {
    return Icon(
      Icons.military_tech_rounded,
      size: size * 0.85,
      color: isUnranked ? AppTheme.textSecondary : color,
    );
  }
}

/// Backwards compatibility alias
typedef GemRankIcon = ValorantRankIcon;
