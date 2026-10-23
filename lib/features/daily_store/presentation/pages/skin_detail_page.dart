import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:valorant_store_tracker/l10n/l10n.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_badge.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';

class SkinDetailPage extends StatefulWidget {
  final String skinId;

  const SkinDetailPage({super.key, required this.skinId});

  @override
  State<SkinDetailPage> createState() => _SkinDetailPageState();
}

class _SkinDetailPageState extends State<SkinDetailPage> {
  SkinItem? _skin;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedChromaIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSkinDetail();
  }

  Future<void> _loadSkinDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = getIt<StoreRepository>();
    final result = await repo.getSkinDetail(widget.skinId);

    if (!mounted) return;

    result.when(
      success: (skin) {
        setState(() {
          _skin = skin;
          _isLoading = false;
        });
      },
      failure: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        });
      },
    );
  }

  Color _parseTierColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.accent;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Skin detail')),
        body: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              ShimmerBox(height: 240, borderRadius: AppRadius.lg),
              SizedBox(height: AppSpacing.lg),
              ShimmerBox(height: 24),
              SizedBox(height: AppSpacing.sm),
              ShimmerBox(height: 80, borderRadius: AppRadius.lg),
            ],
          ),
        ),
      );
    }

    if (_skin == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Skin detail')),
        body: ErrorStateView(
          message: _errorMessage ?? 'Skin not found.',
          onRetry: _loadSkinDetail,
        ),
      );
    }

    final skin = _skin!;
    final tierColor = _parseTierColor(skin.tierColor);

    String? currentImage = skin.displayIcon;
    if (skin.chromas.isNotEmpty &&
        _selectedChromaIndex < skin.chromas.length) {
      final chroma = skin.chromas[_selectedChromaIndex];
      currentImage = chroma.fullRender ?? chroma.displayIcon ?? currentImage;
    }

    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (context, wishlistState) {
        final isWishlisted = wishlistState is WishlistLoaded &&
            wishlistState.isInWishlist(skin.uuid);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                leadingWidth: 56,
                leading: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.roundedSm,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: IconButton(
                      onPressed: () {
                        context.read<WishlistCubit>().toggleWishlist(skin);
                      },
                      icon: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 19,
                        color: isWishlisted
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.roundedSm,
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHero(
                    skin,
                    tierColor,
                    currentImage,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatBadge(
                            text: skin.weaponName ?? 'Weapon',
                            color: tierColor,
                            outlined: true,
                            fontSize: 9,
                          ),
                          if (skin.tierName != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              skin.tierName!,
                              style: AppTextStyles.statLabel(
                                color: tierColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        skin.displayName,
                        style: AppTextStyles.h1(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DataPanel(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PRICE',
                                    style: AppTextStyles.statLabel(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${skin.cost} VP',
                                    style: AppTextStyles.statValue(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                context
                                    .read<WishlistCubit>()
                                    .toggleWishlist(skin);
                              },
                              icon: Icon(
                                isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isWishlisted
                                    ? context.l10n.wishlistAdded
                                    : context.l10n.wishlistAdd,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: isWishlisted
                                    ? AppColors.cardElevated
                                    : AppColors.accent,
                                foregroundColor: isWishlisted
                                    ? AppColors.accent
                                    : AppColors.onAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (skin.chromas.length > 1) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        SectionHeader(
                          index: '01',
                          title: 'VARIANTS',
                          subtitle: '${skin.chromas.length} chromas',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: skin.chromas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final chroma = skin.chromas[index];
                              final isSelected = index == _selectedChromaIndex;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedChromaIndex = index;
                                  });
                                },
                                child: Container(
                                  width: 72,
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: AppRadius.roundedSm,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: chroma.displayIcon != null
                                      ? CachedNetworkImage(
                                          imageUrl: chroma.displayIcon!,
                                          fit: BoxFit.contain,
                                        )
                                      : Center(
                                          child: Text(
                                            'V${index + 1}',
                                            style: AppTextStyles.statValue(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (skin.levels.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        SectionHeader(
                          index: skin.chromas.length > 1 ? '02' : '01',
                          title: 'UPGRADE LEVELS',
                          subtitle: '${skin.levels.length} levels',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DataPanel(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < skin.levels.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                _buildLevelRow(skin.levels[i], i),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(
    SkinItem skin,
    Color tierColor,
    String? currentImage,
  ) {
    return Container(
      color: AppColors.surface,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -60,
            top: 40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tierColor.withValues(alpha: 0.14),
                  width: 28,
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Text(
              'SKIN DETAIL',
              style: AppTextStyles.statLabel(color: AppColors.textMuted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              64,
              AppSpacing.xxl,
              36,
            ),
            child: currentImage != null
                ? CachedNetworkImage(
                    imageUrl: currentImage,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  )
                : const Icon(
                    Icons.shield_outlined,
                    size: 56,
                    color: AppColors.textMuted,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow(SkinLevel level, int index) {
    final item = level.levelItemLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: AppTextStyles.statLabel(color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              level.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (item != null && item.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              item,
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
