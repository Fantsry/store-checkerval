import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';

class EquippedLoadoutPreview extends StatelessWidget {
  final List<EquippedWeaponSkin> equippedWeapons;

  const EquippedLoadoutPreview({super.key, required this.equippedWeapons});

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
    if (equippedWeapons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EQUIPPED LOADOUT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${equippedWeapons.length} Weapons',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: equippedWeapons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final weapon = equippedWeapons[index];
              final tierColor = _parseTierColor(weapon.tierColor);

              return Container(
                width: 140,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tierColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          weapon.weaponName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tierColor,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: weapon.skinIcon != null
                            ? CachedNetworkImage(
                                imageUrl: weapon.skinIcon!,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppTheme.valorantRed,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 20,
                                  color: AppTheme.textSecondary,
                                ),
                              )
                            : const Icon(
                                Icons.shield_outlined,
                                size: 24,
                                color: AppTheme.textSecondary,
                              ),
                      ),
                    ),
                    Text(
                      weapon.skinName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
