import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_state.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/add_friend_dialog.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/friend_card.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/custom_tab_bar.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _spinController;
  Timer? _livePollingTimer;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Initial load
    final cubit = context.read<SocialCubit>();
    if (cubit.state is SocialInitial) {
      cubit.loadFriends();
    }

    // Auto-poll live presence every 15s when friends are in match
    _livePollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        final s = context.read<SocialCubit>().state;
        if (s is SocialLoaded && s.playingCount > 0 && !s.isRefreshing) {
          context.read<SocialCubit>().refreshLivePresence();
        }
      }
    });
  }

  @override
  void dispose() {
    _livePollingTimer?.cancel();
    _searchController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (_) => const AddFriendDialog(),
    );
  }

  Future<void> _handleRefresh() async {
    _spinController.repeat();
    try {
      await context.read<SocialCubit>().refreshLivePresence();
    } finally {
      if (mounted) {
        _spinController.stop();
        _spinController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'SQUAD & SOCIAL',
                  style: AppTextStyles.h4(color: AppColors.textPrimary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.6)),
                  ),
                  child: const Text(
                    'LIVE RADAR',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.red,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Pantau teman yang sedang bermain secara real-time',
              style: AppTextStyles.caption(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.cyan),
            tooltip: 'Sinkronkan Teman Riot (XMPP)',
            onPressed: () async {
              _spinController.repeat();
              try {
                await context.read<SocialCubit>().syncRiotFriends(clearMocks: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Daftar teman Riot berhasil disinkronkan!'),
                      backgroundColor: AppColors.cardElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  _spinController.stop();
                  _spinController.reset();
                }
              }
            },
          ),
          RotationTransition(
            turns: _spinController,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              tooltip: 'Perbarui Status Live',
              onPressed: _handleRefresh,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.red),
            tooltip: 'Tambah Teman',
            onPressed: _showAddFriendDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            color: AppColors.card,
            onSelected: (value) async {
              if (value == 'clear_mock') {
                await context.read<SocialCubit>().clearMockFriends();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data teman dummy berhasil dibersihkan!'),
                      backgroundColor: AppColors.cardElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'import_teammates') {
                final count = await context.read<SocialCubit>().importRecentTeammates();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count rekan tim berhasil diimpor!'),
                      backgroundColor: AppColors.cardElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'demo_squad') {
                await context.read<SocialCubit>().loadDemoSquad();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_mock',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_rounded, color: AppColors.lossRed, size: 18),
                    SizedBox(width: 8),
                    Text('Bersihkan Data Dummy'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_teammates',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.cyan, size: 18),
                    SizedBox(width: 8),
                    Text('Impor Rekan Tim Match'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'demo_squad',
                child: Row(
                  children: [
                    Icon(Icons.sports_esports_outlined, color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 8),
                    Text('Muat Demo Squad'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
      ),
      body: BlocConsumer<SocialCubit, SocialState>(
        listener: (context, state) {
          if (state is SocialLoaded && state.isRefreshing) {
            if (!_spinController.isAnimating) {
              _spinController.repeat();
            }
          } else {
            if (_spinController.isAnimating) {
              _spinController.stop();
              _spinController.reset();
            }
          }
        },
        builder: (context, state) {
          if (state is SocialLoading && state.cachedFriends == null) {
            return _buildLoadingShimmer();
          }

          if (state is SocialError &&
              (state.cachedFriends == null || state.cachedFriends!.isEmpty)) {
            return ErrorStateView(
              message: state.message,
              onRetry: () => context.read<SocialCubit>().loadFriends(forceRefresh: true),
            );
          }

          if (state is SocialLoaded) {
            return _buildLoadedContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFriendDialog,
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(
          'TAMBAH TEMAN',
          style: AppTextStyles.badge(color: Colors.white)
              .copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildLoadedContent(SocialLoaded state) {
    if (state.friends.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<SocialCubit>().syncRiotFriends(clearMocks: true),
        color: AppColors.cyan,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyFriendsState(),
            ),
          ],
        ),
      );
    }

    final filtered = state.filteredFriends;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.red,
      backgroundColor: AppColors.card,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── 1. Squad Activity Summary Hero ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _buildSummaryHero(state),
            ),
          ),

          // ─── 2. Search & Filter Bar ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        context.read<SocialCubit>().setSearchQuery(val),
                    style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Cari nama teman, rank, agen, map...',
                      hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context.read<SocialCubit>().setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.roundedMd,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.roundedMd,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.roundedMd,
                        borderSide: const BorderSide(
                          color: AppColors.cyan,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Filter Tabs
                  CustomTabBar(
                    tabs: [
                      'ALL (${state.totalCount})',
                      'IN-GAME (${state.playingCount})',
                      'LOBBY (${state.inLobbyCount})',
                      'OFFLINE (${state.offlineCount})',
                    ],
                    selectedIndex: state.activeFilter.index,
                    onTabSelected: (idx) {
                      context
                          .read<SocialCubit>()
                          .setFilter(FriendFilter.values[idx]);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ─── 3. Friends List ─────────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: Icons.person_search_rounded,
                title: 'Tidak Ada Teman Ditemukan',
                description: state.searchQuery.isNotEmpty
                    ? 'Tidak ada teman yang cocok dengan "${state.searchQuery}".'
                    : 'Belum ada teman dalam kategori ini.',
                buttonText: 'TAMBAH TEMAN',
                onButtonPressed: _showAddFriendDialog,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                80, // Space for FAB
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final friend = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: FriendCard(
                        friend: friend,
                        onFavoriteTap: () => context
                            .read<SocialCubit>()
                            .toggleFavorite(friend.puuid),
                        onDeleteTap: () => _confirmDeleteFriend(friend),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryHero(SocialLoaded state) {
    return AscendCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.lg,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B2836), Color(0xFF141E28)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'SQUAD RADAR STATUS',
                  style: AppTextStyles.badge(color: AppColors.cyan)
                      .copyWith(letterSpacing: 0.8),
                ),
              ),
              if (state.playingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${state.playingCount} PLAYING',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: 'TOTAL SQUAD',
                value: '${state.totalCount}',
                color: AppColors.textPrimary,
                icon: Icons.people_outline_rounded,
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              _buildMetricItem(
                label: 'IN-MATCH',
                value: '${state.playingCount}',
                color: AppColors.red,
                icon: Icons.sports_esports_rounded,
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              _buildMetricItem(
                label: 'IN LOBBY',
                value: '${state.inLobbyCount}',
                color: AppColors.winGreen,
                icon: Icons.hourglass_top_rounded,
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              _buildMetricItem(
                label: 'OFFLINE',
                value: '${state.offlineCount}',
                color: AppColors.textMuted,
                icon: Icons.power_settings_new_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.h3(color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _confirmDeleteFriend(friend) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedMd,
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'HAPUS TEMAN',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${friend.displayName} dari daftar Squad?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('BATAL', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SocialCubit>().removeFriend(friend.puuid);
            },
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Icon(
                  Icons.group_off_rounded,
                  size: 38,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Belum Ada Teman Terhubung',
              style: AppTextStyles.h4(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Sinkronkan daftar teman asli Anda langsung dari akun Riot Games Anda atau tambahkan teman dengan Riot ID.',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => context.read<SocialCubit>().syncRiotFriends(clearMocks: true),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('SINKRONKAN TEMAN RIOT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
                minimumSize: const Size(220, 44),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _showAddFriendDialog,
              icon: const Icon(Icons.person_add_rounded, color: AppColors.red),
              label: const Text(
                'TAMBAH DENGAN RIOT ID',
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.red),
                minimumSize: const Size(220, 44),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () async {
                final count = await context.read<SocialCubit>().importRecentTeammates();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count rekan tim dari riwayat pertandingan berhasil diimpor!'),
                      backgroundColor: AppColors.cardElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
              label: const Text(
                'Impor Rekan Tim dari Match History',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => context.read<SocialCubit>().loadDemoSquad(),
              child: const Text(
                'Lihat Tampilan Contoh (Demo Squad)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        ShimmerBox(height: 110, borderRadius: AppRadius.lg),
        SizedBox(height: AppSpacing.md),
        ShimmerBox(height: 48, borderRadius: AppRadius.md),
        SizedBox(height: AppSpacing.md),
        ShimmerBox(height: 140, borderRadius: AppRadius.lg),
        SizedBox(height: AppSpacing.md),
        ShimmerBox(height: 140, borderRadius: AppRadius.lg),
        SizedBox(height: AppSpacing.md),
        ShimmerBox(height: 140, borderRadius: AppRadius.lg),
      ],
    );
  }
}
