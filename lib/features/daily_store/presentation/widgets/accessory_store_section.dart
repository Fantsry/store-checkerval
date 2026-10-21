import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';

class AccessoryStoreSection extends StatefulWidget {
  final List<AccessoryStoreItem> items;
  final String? index;

  const AccessoryStoreSection({super.key, required this.items, this.index});

  @override
  State<AccessoryStoreSection> createState() => _AccessoryStoreSectionState();
}

class _AccessoryStoreSectionState extends State<AccessoryStoreSection> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _initRemainingSeconds();
    _startTimer();
  }

  void _initRemainingSeconds() {
    final rawRemaining = widget.items.isNotEmpty
        ? widget.items.first.remainingDurationSeconds
        : 0;
    if (rawRemaining > 0) {
      _remainingSeconds = rawRemaining;
    } else {
      _remainingSeconds = TimezoneHelper.timeUntilAccessoryReset.inSeconds;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingSeconds <= 0) {
      _initRemainingSeconds();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _initRemainingSeconds();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant AccessoryStoreSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isNotEmpty) {
      final newRemaining = widget.items.first.remainingDurationSeconds;
      if (newRemaining > 0 && newRemaining != _remainingSeconds) {
        setState(() {
          _remainingSeconds = newRemaining;
        });
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          index: widget.index,
          title: 'ACCESSORY STORE',
          subtitle: 'Weekly Kingdom Credits rotation',
          trailing: _remainingSeconds > 0
              ? Text(
                  TimezoneHelper.formatWeeklyDuration(
                    Duration(seconds: _remainingSeconds),
                  ),
                  style: AppTextStyles.statLabel(color: AppColors.accentSoft),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.86,
          ),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];

            return DataPanel(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft.withValues(alpha: 0.1),
                          borderRadius: AppRadius.roundedSm,
                          border: Border.all(
                            color: AppColors.accentSoft.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          item.itemType.toUpperCase(),
                          style: AppTextStyles.statLabel(
                            color: AppColors.accentSoft,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.kcCost > 0 ? '${item.kcCost} KC' : '-- KC',
                        style: AppTextStyles.statValue(
                          color: AppColors.accentSoft,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Center(
                      child:
                          item.displayIcon != null &&
                              item.displayIcon!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.displayIcon!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentSoft,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                size: 26,
                                color: AppColors.textMuted,
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: AppRadius.roundedSm,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 22,
                                    color: AppColors.accentSoft,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.displayName,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.statLabel(
                                      color: AppColors.accentSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
