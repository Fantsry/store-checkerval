import 'package:flutter/material.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/player_banner.dart';

class FriendProfileHeader extends StatelessWidget {
  final FriendEntity friend;
  final VoidCallback? onClose;

  const FriendProfileHeader({
    super.key,
    required this.friend,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlayerBannerArt(
            wideArt: friend.cardWideArt,
            largeArt: friend.cardLargeArt,
            smallArt: friend.cardSmallArt,
            alignment: Alignment.topCenter,
            showFallbackIcon: false,
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: IconButton(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            bottom: AppSpacing.md,
            child: Text(
              'PLAYER PROFILE',
              style: AppTextStyles.statLabel(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
