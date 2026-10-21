import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _riotIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  List<MatchPlayerSummary> _recentTeammates = [];
  bool _isLoadingTeammates = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecentTeammates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _riotIdController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentTeammates() async {
    setState(() => _isLoadingTeammates = true);
    final teammates =
        await context.read<SocialCubit>().getRecentAvailableTeammates();
    if (mounted) {
      setState(() {
        _recentTeammates = teammates;
        _isLoadingTeammates = false;
      });
    }
  }

  Future<void> _submitRiotId() async {
    final input = _riotIdController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Masukkan Riot ID atau PUUID');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final cubit = context.read<SocialCubit>();
    bool success = false;

    if (input.contains('-') && input.length >= 32) {
      // Looks like a PUUID
      success = await cubit.addFriend(puuid: input);
    } else {
      // Riot ID: Name#Tag
      success = await cubit.addFriendByRiotId(input);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Teman "$input" berhasil ditambahkan ke Squad!'),
            backgroundColor: AppColors.cardElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _errorMessage = 'Gagal menambahkan teman. Cek Riot ID.');
      }
    }
  }

  Future<void> _addTeammate(MatchPlayerSummary player) async {
    final success = await context.read<SocialCubit>().addFriend(
          puuid: player.puuid,
          gameName: player.gameName,
          tagLine: player.tagLine,
        );

    if (mounted && success) {
      setState(() {
        _recentTeammates.removeWhere((p) => p.puuid == player.puuid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.gameName} ditambahkan ke Squad!'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.cardElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importAllTeammates() async {
    setState(() => _isLoading = true);
    final count = await context.read<SocialCubit>().importRecentTeammates();
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count rekan tim berhasil diimpor ke Squad!'),
          backgroundColor: AppColors.cardElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedXl,
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TAMBAH TEMAN / SQUAD',
                          style: AppTextStyles.h4(color: AppColors.textPrimary),
                        ),
                        Text(
                          'Lacak aktivitas live teman bermain',
                          style: AppTextStyles.caption(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                indicatorWeight: 2,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.badge(color: AppColors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'RIOT ID / PUUID'),
                  Tab(text: 'RECENT TEAMMATES'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRiotIdTab(),
                  _buildRecentTeammatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiotIdTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MASUKKAN RIOT ID ATAU PUUID',
            style: AppTextStyles.badge(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Format: GameName#TagLine (contoh: TenZ#0001 atau f0rsakeN#PRX)',
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),

          // Input field
          TextField(
            controller: _riotIdController,
            style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Contoh: TenZ#SEN',
              hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
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
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              prefixIcon: const Icon(
                Icons.tag_rounded,
                color: AppColors.cyan,
                size: 20,
              ),
            ),
            onSubmitted: (_) => _submitRiotId(),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage!,
              style: AppTextStyles.caption(color: AppColors.accent),
            ),
          ],

          const Spacer(),

          // Submit Button
          ElevatedButton(
            onPressed: _isLoading ? null : _submitRiotId,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.roundedMd,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'TAMBAHKAN KE SQUAD',
                        style: AppTextStyles.badge(color: Colors.white)
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTeammatesTab() {
    if (_isLoadingTeammates) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_recentTeammates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.group_off_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tidak ada rekan tim baru',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Mainkan match Valorant atau tambahkan manual via Riot ID',
                style: AppTextStyles.caption(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // List of teammates
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _recentTeammates.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final player = _recentTeammates[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Agent Icon
                    if (player.agentIconUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: player.agentIconUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.person, color: AppColors.textMuted),
                        ),
                      )
                    else
                      const Icon(Icons.person, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.md),

                    // Name and Rank
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.gameName.toUpperCase(),
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              GemRankIcon(
                                  tierName: player.rankName ?? 'Unranked',
                                  size: 14),
                              const SizedBox(width: 4),
                              Text(
                                player.rankName ?? 'Unranked',
                                style: AppTextStyles.caption(
                                  color: AppColors.getRankColor(player.rankName),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // + Add Button
                    ElevatedButton(
                      onPressed: () => _addTeammate(player),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardElevated,
                        foregroundColor: AppColors.cyan,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        side: const BorderSide(color: AppColors.cyan, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.roundedSm,
                        ),
                      ),
                      child: Text(
                        '+ ADD',
                        style: AppTextStyles.badge(color: AppColors.cyan),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Import All Button at Bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _importAllTeammates,
            icon: const Icon(Icons.group_add_rounded, size: 16),
            label: const Text('IMPOR SEMUA REKAN TIM TERAKHIR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cyan,
              side: const BorderSide(color: AppColors.cyan, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.roundedMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
