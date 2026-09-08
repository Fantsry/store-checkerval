import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';

class OwnedSkinCard extends StatelessWidget {
  final OwnedSkinItem skin;

  const OwnedSkinCard({super.key, required this.skin});

  Color _parseTierColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF5A9FE2);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF5A9FE2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = _parseTierColor(skin.tierColor);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: skin.isEquipped
              ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
          width: skin.isEquipped ? 1.5 : 1.0,
        ),
        boxShadow: skin.isEquipped
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Tier badge & Equipped Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    skin.tierName?.toUpperCase() ?? 'SKIN',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: tierColor,
                    ),
                  ),
                ),
                if (skin.isEquipped)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'EQUIPPED',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ),
              ],
            ),

            // Skin Weapon Icon
            Expanded(
              child: Center(
                child: skin.displayIcon != null
                    ? CachedNetworkImage(
                        imageUrl: skin.displayIcon!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.valorantRed,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          size: 24,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.shield_outlined,
                        size: 28,
                        color: AppTheme.textSecondary,
                      ),
              ),
            ),

            // Skin Name
            Text(
              skin.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Bottom Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  skin.weapon,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  skin.cost > 0 ? '${skin.cost} VP' : 'FREE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: skin.cost > 0
                        ? const Color(0xFFE5B94E)
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
