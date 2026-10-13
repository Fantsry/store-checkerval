import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class AgentAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? agentName;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool isCircular;

  const AgentAvatar({
    super.key,
    this.imageUrl,
    this.agentName,
    this.size = 44,
    this.borderColor,
    this.borderWidth = 1.5,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isCircular ? BorderRadius.circular(size / 2) : AppRadius.roundedMd;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.card,
                  child: const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppColors.card,
      child: Center(
        child: Text(
          (agentName != null && agentName!.isNotEmpty)
              ? agentName!.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
