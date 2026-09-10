import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/core/utils/timezone_helper.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/daily_store.dart';

class AccessoryStoreSection extends StatefulWidget {
  final List<AccessoryStoreItem> items;

  const AccessoryStoreSection({super.key, required this.items});

  @override
  State<AccessoryStoreSection> createState() => _AccessoryStoreSectionState();
}

class _AccessoryStoreSectionState extends State<AccessoryStoreSection> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.items.isNotEmpty
        ? widget.items.first.remainingDurationSeconds
        : 0;
    if (_remainingSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AccessoryStoreSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isNotEmpty) {
      final newRemaining = widget.items.first.remainingDurationSeconds;
      if (newRemaining != _remainingSeconds && newRemaining > 0) {
        _remainingSeconds = newRemaining;
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
        // Accessory Store Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF00E5FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCESSORY STORE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Weekly Kingdom Credits rotation',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_remainingSeconds > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TimezoneHelper.formatDuration(
                          Duration(seconds: _remainingSeconds),
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Grid of 4 accessory items
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];

            return Container(
              padding: const EdgeInsets.all(12),
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
                  // Top Type pill tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.itemType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                      // KC badge
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.kcCost} KC',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Accessory Icon / Art
                  Expanded(
                    child: Center(
                      child: item.displayIcon != null &&
                              item.displayIcon!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.displayIcon!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                size: 28,
                                color: AppTheme.textSecondary,
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.badge_rounded,
                                    size: 24,
                                    color: Color(0xFF00E5FF),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.displayName.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: Color(0xFF00E5FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Accessory Display Name
                  Text(
                    item.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
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
