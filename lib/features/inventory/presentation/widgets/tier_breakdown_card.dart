import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';

class TierBreakdownCard extends StatelessWidget {
  final Map<String, int> tierBreakdown;

  const TierBreakdownCard({super.key, required this.tierBreakdown});

  Color _tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'exclusive':
        return const Color(0xFFE5B94E);
      case 'ultra':
        return const Color(0xFFEAB93A);
      case 'premium':
        return const Color(0xFFD1548D);
      case 'deluxe':
        return const Color(0xFF00B1A7);
      case 'select':
      default:
        return const Color(0xFF5A9FE2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiers = ['Exclusive', 'Ultra', 'Premium', 'Deluxe', 'Select'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SKIN TIERS DISTRIBUTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: tiers.map((tier) {
              final count = tierBreakdown[tier] ?? 0;
              final color = _tierColor(tier);

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tier,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
