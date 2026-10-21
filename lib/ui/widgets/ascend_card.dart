import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum PanelTone { surface, elevated, inset }

class DataPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final PanelTone tone;
  final double borderRadius;
  final bool showBorder;

  const DataPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.tone = PanelTone.surface,
    this.borderRadius = AppRadius.lg,
    this.showBorder = true,
  });

  Color get _background => switch (tone) {
        PanelTone.surface => AppColors.surface,
        PanelTone.elevated => AppColors.card,
        PanelTone.inset => AppColors.background,
      };

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: radius,
        border: showBorder
            ? Border.all(color: AppColors.border, width: 1)
            : null,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    final wrapped = margin == null ? content : Padding(
      padding: margin!,
      child: content,
    );

    if (onTap == null) return wrapped;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: wrapped,
      ),
    );
  }
}

class HudCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final Gradient? gradient;
  final bool hasGlow;
  final Color? glowColor;

  const HudCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = AppRadius.lg,
    this.gradient,
    this.hasGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final content = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: radius,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? AppColors.border,
                width: borderWidth,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );

    final wrapped = margin == null ? content : Padding(
      padding: margin!,
      child: content,
    );

    if (onTap == null) return wrapped;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: wrapped,
      ),
    );
  }
}

typedef AscendCard = HudCard;
