import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/inventory/domain/entities/inventory_overview.dart';

class AccountValueCard extends StatelessWidget {
  final InventoryOverview overview;
  final VoidCallback? onOwnedSkinsTap;

  const AccountValueCard({
    super.key,
    required this.overview,
    this.onOwnedSkinsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with tag and info button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.accentMagenta.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 13,
                      color: AppTheme.accentMagenta,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'ACCOUNT INVENTORY VALUE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppTheme.accentMagenta,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => _showCalculationInfo(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Estimated IDR (Rupiah)
          Text(
            overview.formattedEstimatedIdr,
            style: GoogleFonts.rajdhani(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Estimated Total Spent (Indonesian Rupiah)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 14),

          // Stats Sub-Row: Total VP & Total Skins
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            size: 14,
                            color: Color(0xFFE5B94E),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'TOTAL VP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${overview.totalVpSpent} VP',
                        style: GoogleFonts.rajdhani(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE5B94E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Store purchases',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOwnedSkinsTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: Color(0xFF00E5FF),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'OWNED SKINS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${overview.totalSkinsCount} Skins',
                          style: GoogleFonts.rajdhani(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${overview.storeSkinsCount} Store • ${overview.battlepassSkinsCount} BP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCalculationInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'About Account Valuation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Total VP is calculated by querying your Riot account skin entitlements and matching each skin to its official Riot store price.\n\n'
                '2. Default weapon skins (cost 0 VP) and Battlepass level rewards are excluded from the purchase valuation.\n\n'
                '3. Estimated IDR (Rupiah) uses current Indonesian Valorant Point retail bundle averages (~Rp 135 per 1 VP).',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('GOT IT'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
