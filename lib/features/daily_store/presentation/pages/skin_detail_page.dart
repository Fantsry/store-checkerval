import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_store_tracker/app/di.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_state.dart';

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

    if (mounted) {
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
  }

  Color _parseTierColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF5A9FE2);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF5A9FE2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.valorantRed),
        ),
      );
    }

    if (_skin == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Skin Detail'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.valorantRed),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Skin not found',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadSkinDetail,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final skin = _skin!;
    final tierColor = _parseTierColor(skin.tierColor);

    // Current selected image (chroma full render or default displayIcon)
    String? currentImage = skin.displayIcon;
    if (skin.chromas.isNotEmpty &&
        _selectedChromaIndex < skin.chromas.length) {
      final c = skin.chromas[_selectedChromaIndex];
      currentImage = c.fullRender ?? c.displayIcon ?? currentImage;
    }

    return BlocBuilder<WishlistCubit, WishlistState>(
      builder: (context, wishlistState) {
        final isWishlisted = wishlistState is WishlistLoaded &&
            wishlistState.isInWishlist(skin.uuid);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          body: CustomScrollView(
            slivers: [
              // ─── App Bar with Skin Image ─────────────────────
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppTheme.surfaceDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial background glow matching tier color
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              tierColor.withValues(alpha: 0.25),
                              AppTheme.backgroundDark,
                            ],
                          ),
                        ),
                      ),

                      // Image
                      if (currentImage != null)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: CachedNetworkImage(
                            imageUrl: currentImage,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.valorantRed,
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image_rounded,
                              size: 48,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        context.read<WishlistCubit>().toggleWishlist(skin);
                      },
                      icon: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: isWishlisted
                            ? AppTheme.accentMagenta
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              // ─── Details Content ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weapon & Tier badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: tierColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              skin.weaponName?.toUpperCase() ?? 'WEAPON',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tierColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (skin.tierName != null)
                            Text(
                              skin.tierName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: tierColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Skin Full Display Name
                      Text(
                        skin.displayName,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Price Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 20,
                                  color: AppTheme.accentMagenta,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${skin.cost} VP',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                context
                                    .read<WishlistCubit>()
                                    .toggleWishlist(skin);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isWishlisted
                                    ? AppTheme.surfaceLight
                                    : AppTheme.accentMagenta,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              icon: Icon(
                                isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isWishlisted
                                    ? 'IN WISHLIST'
                                    : 'ADD TO WISHLIST',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Chromas Variants ────────────────────
                      if (skin.chromas.length > 1) ...[
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentMagenta,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Text(
                              'VARIANTS & CHROMAS',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: skin.chromas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
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
                                  width: 80,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.accentMagenta
                                            .withValues(alpha: 0.15)
                                        : AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.accentMagenta
                                          : Colors.white.withValues(alpha: 0.08),
                                      width: isSelected ? 1.5 : 1,
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
                                            style: GoogleFonts.rajdhani(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ─── Upgrade Levels ──────────────────────
                      if (skin.levels.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentMagenta,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Text(
                              'UPGRADE LEVELS',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(skin.levels.length, (index) {
                          final level = skin.levels[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.accentMagenta
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentMagenta,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    level.displayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (level.levelItem != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceDark,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.06),
                                      ),
                                    ),
                                    child: Text(
                                      level.levelItem!
                                          .replaceAll('EEquippableSkinLevelItem::', ''),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
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
}
