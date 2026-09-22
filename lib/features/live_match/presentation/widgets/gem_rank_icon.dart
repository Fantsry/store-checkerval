import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/app/theme.dart';

/// Custom diamond/gem shaped rank icon widget.
/// Draws a flat-shaded diamond using CustomPainter with colors
/// derived from rank tier name (Iron, Bronze, Silver, Gold, etc.).
class GemRankIcon extends StatelessWidget {
  final String tierName;
  final double size;
  final bool showGlow;
  final bool isCurrent;

  const GemRankIcon({
    super.key,
    required this.tierName,
    this.size = 24,
    this.showGlow = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getRankTierColor(tierName);
    final isUnranked = tierName.toLowerCase() == 'unranked' ||
        tierName.isEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow ring for current rank
          if (showGlow && !isUnranked)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: size * 0.4,
                    spreadRadius: size * 0.05,
                  ),
                ],
              ),
            ),
          // The gem itself
          CustomPaint(
            size: Size(size * 0.8, size * 0.8),
            painter: _GemPainter(
              color: color,
              isUnranked: isUnranked,
            ),
          ),
        ],
      ),
    );
  }
}

class _GemPainter extends CustomPainter {
  final Color color;
  final bool isUnranked;

  _GemPainter({
    required this.color,
    required this.isUnranked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isUnranked) {
      _paintUnranked(canvas, size);
      return;
    }

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Diamond shape points
    final top = Offset(cx, 0);
    final right = Offset(size.width, cy);
    final bottom = Offset(cx, size.height);
    final left = Offset(0, cy);

    // Main diamond fill
    final mainPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(mainPath, mainPaint);

    // Top-left facet (lighter)
    final topLeftPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(cx, cy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final topLeftPaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.25)!
      ..style = PaintingStyle.fill;
    canvas.drawPath(topLeftPath, topLeftPaint);

    // Top-right facet (slightly lighter)
    final topRightPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(cx, cy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final topRightPaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.12)!
      ..style = PaintingStyle.fill;
    canvas.drawPath(topRightPath, topRightPaint);

    // Bottom-right facet (darker)
    final bottomRightPath = Path()
      ..moveTo(right.dx, right.dy)
      ..lineTo(cx, cy)
      ..lineTo(bottom.dx, bottom.dy)
      ..close();

    final bottomRightPaint = Paint()
      ..color = Color.lerp(color, Colors.black, 0.2)!
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottomRightPath, bottomRightPaint);

    // Bottom-left facet (darkest)
    final bottomLeftPath = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(cx, cy)
      ..lineTo(bottom.dx, bottom.dy)
      ..close();

    final bottomLeftPaint = Paint()
      ..color = Color.lerp(color, Colors.black, 0.3)!
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottomLeftPath, bottomLeftPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(mainPath, outlinePaint);

    // Inner highlight line
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawLine(top, Offset(cx, cy), highlightPaint);
  }

  void _paintUnranked(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final top = Offset(cx, 0);
    final right = Offset(size.width, cy);
    final bottom = Offset(cx, size.height);
    final left = Offset(0, cy);

    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final paint = Paint()
      ..color = const Color(0xFF3E4049)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    final outlinePaint = Paint()
      ..color = const Color(0xFF6B6F7B).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, outlinePaint);

    // Question mark for unranked
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: Color(0xFF6B6F7B),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _GemPainter oldDelegate) =>
      color != oldDelegate.color || isUnranked != oldDelegate.isUnranked;
}
