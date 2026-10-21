import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class CountdownTimerWidget extends StatefulWidget {
  final int initialRemainingSeconds;
  final VoidCallback? onTimerExpired;
  final bool compact;

  const CountdownTimerWidget({
    super.key,
    required this.initialRemainingSeconds,
    this.onTimerExpired,
    this.compact = false,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialRemainingSeconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRemainingSeconds != widget.initialRemainingSeconds) {
      _remaining = widget.initialRemainingSeconds;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 0) {
        setState(() {
          _remaining--;
        });
      } else {
        timer.cancel();
        widget.onTimerExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00:00';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
        vertical: widget.compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 14,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _formatDuration(_remaining),
            style: AppTextStyles.statValue(
              color: AppColors.textPrimary,
              fontSize: widget.compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
