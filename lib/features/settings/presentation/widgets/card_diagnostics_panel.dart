import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_state.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';

class CardDiagnosticsPanel extends StatelessWidget {
  const CardDiagnosticsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DataPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CARD DIAGNOSTICS',
              style: AppTextStyles.statLabel(color: AppColors.accentSoft),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Data langsung dari Riot dan Valorant-API. Tidak ada data dummy.',
              style: AppTextStyles.caption(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                final profile = switch (state) {
                  ProfileLoaded(:final profile) => profile,
                  ProfileLoading(:final cachedProfile) => cachedProfile,
                  ProfileError(:final cachedProfile) => cachedProfile,
                  _ => null,
                };
                return _block('PROFIL SENDIRI', [
                  _line('Card ID', profile?.cardUuid),
                  _line('Card name', profile?.cardName),
                  _line('Shard', profile?.shard),
                  _line('Wide art', profile?.cardWideArt),
                ]);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocBuilder<SocialCubit, SocialState>(
              builder: (context, state) {
                final friends = switch (state) {
                  SocialLoaded(:final friends) => friends,
                  SocialLoading(:final cachedFriends) => cachedFriends ?? [],
                  SocialError(:final cachedFriends) => cachedFriends ?? [],
                  _ => const <FriendEntity>[],
                };
                return _block(
                  'TEMAN (${friends.length})',
                  friends.take(3).map((friend) {
                    return _line(
                      friend.displayName,
                      '${friend.cardUuid ?? 'null'} | ${friend.cardWideArt ?? 'null'}',
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            BlocBuilder<LiveMatchCubit, LiveMatchState>(
              builder: (context, state) {
                final match = switch (state) {
                  LiveMatchLoaded(:final matchData) => matchData,
                  _ => null,
                };
                final players = match == null
                    ? const []
                    : [...match.blueTeam, ...match.redTeam];
                return _block(
                  'LIVE MATCH (${players.length})',
                  players.take(3).map((player) {
                    return _line(
                      player.displayName,
                      '${player.cardUuid ?? 'null'} | ${player.cardWideArt ?? 'null'}',
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _block(String title, List<Widget> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.statValue()),
        const SizedBox(height: AppSpacing.xs),
        if (lines.isEmpty)
          Text('Tidak ada data', style: AppTextStyles.caption())
        else
          ...lines,
      ],
    );
  }

  Widget _line(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: ${value == null || value.isEmpty ? 'null' : value}',
        style: AppTextStyles.caption(color: AppColors.textSecondary),
      ),
    );
  }
}
