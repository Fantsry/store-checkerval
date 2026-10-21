import 'package:fl_chart/fl_chart.dart';
import 'package:valorant_store_tracker/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';

class CareerTrendCharts extends StatelessWidget {
  final CareerOverview overview;

  const CareerTrendCharts({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final rrMatches = _rrMatches(overview.matches);
    final rrValues = _rrSeries(overview, rrMatches);
    final kdMatches = overview.matches.take(10).toList().reversed.toList();
    final kdValues = kdMatches
        .map((m) => m.deaths > 0 ? m.kills / m.deaths : m.kills.toDouble())
        .toList();

    if (rrMatches.isEmpty && kdValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (rrValues.length >= 2) ...[
          _TrendCard(
            title: context.l10n.careerRatingTrend,
            value: '${overview.currentRankRating} RR',
            color: AppColors.accent,
            values: rrValues.map((v) => v.toDouble()).toList(),
            labels: rrMatches.reversed
                .map((m) => m.won == true ? 'W' : 'L')
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (kdValues.isNotEmpty)
          _TrendCard(
            title: context.l10n.careerKdTrend,
            value:
                '${(kdValues.reduce((a, b) => a + b) / kdValues.length).toStringAsFixed(2)} K/D',
            color: AppColors.accentSoft,
            values: kdValues,
            labels: kdMatches
                .map((m) => m.won == true ? 'W' : (m.isDraw ? 'D' : 'L'))
                .toList(),
          ),
      ],
    );
  }

  List<MatchSummary> _rrMatches(List<MatchSummary> matches) {
    return matches
        .where((m) => m.queueId.toLowerCase().contains('competitive'))
        .where((m) => m.rankRatingEarned != null)
        .take(10)
        .toList();
  }

  List<int> _rrSeries(CareerOverview overview, List<MatchSummary> matches) {
    if (matches.isEmpty) return const [];

    var rating = overview.currentRankRating;
    final reversed = <int>[];
    for (final match in matches) {
      reversed.add(rating);
      rating -= match.rankRatingEarned ?? 0;
    }
    return reversed.reversed.toList();
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final List<double> values;
  final List<String> labels;

  const _TrendCard({
    required this.title,
    required this.value,
    required this.color,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final spread = (maxValue - minValue).abs();
    final padding = spread < 0.1 ? 1.0 : spread * 0.2;
    final minY = minValue - padding;
    final maxY = maxValue + padding;

    return DataPanel(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.statLabel(color: AppColors.textSecondary),
              ),
              Text(value, style: AppTextStyles.h4(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 96,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 16,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        final isWin = labels[index] == 'W';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            labels[index],
                            style: AppTextStyles.caption(
                              color: labels[index] == 'D'
                                  ? AppColors.drawAmber
                                  : (isWin
                                        ? AppColors.winGreen
                                        : AppColors.lossRed),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: color,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 2.5,
                            color: color,
                            strokeWidth: 0,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
