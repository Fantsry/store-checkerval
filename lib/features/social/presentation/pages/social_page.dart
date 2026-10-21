import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/widgets/gem_rank_icon.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_state.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/add_friend_dialog.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/social_chat_sheet.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/custom_tab_bar.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/shimmer_loading.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_rail.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _livePollingTimer;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();

    final cubit = context.read<SocialCubit>();
    if (cubit.state is SocialInitial) {
      cubit.loadFriends();
    }

    _livePollingTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) {
        final state = context.read<SocialCubit>().state;
        if (state is SocialLoaded && !state.isRefreshing) {
          context.read<SocialCubit>().refreshLivePresence();
        }
      }
    });
  }

  @override
  void dispose() {
    _livePollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (_) => const AddFriendDialog(),
    );
  }

  Future<void> _handleRefresh() async {
    await context.read<SocialCubit>().syncRiotFriends(clearMocks: true);
  }

  SocialLoaded? _loadedFrom(SocialState state) {
    if (state is SocialLoaded) return state;
    if (state is SocialLoading && state.cachedFriends != null) {
      return SocialLoaded(friends: state.cachedFriends!);
    }
    if (state is SocialError && state.cachedFriends != null) {
      return SocialLoaded(friends: state.cachedFriends!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Social',
          style: AppTextStyles.h2(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Add friend',
            onPressed: _showAddFriendDialog,
          ),
          IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Social options',
            onPressed: () => _showSettingsMenu(context),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<SocialCubit, SocialState>(
          builder: (context, state) {
            final loaded = _loadedFrom(state);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: StatRail(
                    items: [
                      StatRailItem(
                        label: 'FRIENDS',
                        value: loaded == null ? '—' : '${loaded.totalCount}',
                      ),
                      StatRailItem(
                        label: 'ONLINE',
                        value: loaded == null
                            ? '—'
                            : '${loaded.totalCount - loaded.offlineCount}',
                        valueColor: loaded == null
                            ? null
                            : AppColors.accent,
                      ),
                      StatRailItem(
                        label: 'IN GAME',
                        value: loaded == null
                            ? '—'
                            : '${loaded.playingCount}',
                      ),
                      StatRailItem(
                        label: 'UNREAD',
                        value: loaded == null ? '—' : '${loaded.totalUnread}',
                        valueColor: loaded != null && loaded.totalUnread > 0
                            ? AppColors.vpGold
                            : null,
                      ),
                    ],
                  ),
                ),
                CustomTabBar(
                  tabs: [
                    'FRIENDS',
                    'CHATS${loaded != null && loaded.totalUnread > 0 ? ' ${loaded.totalUnread}' : ''}',
                  ],
                  selectedIndex: _selectedTabIndex,
                  onTabSelected: (index) {
                    setState(() => _selectedTabIndex = index);
                  },
                ),
                _buildSearchBar(),
                Expanded(child: _buildContent(state, loaded)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                  context.read<SocialCubit>().setSearchQuery(value);
                },
                style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search friends or chats',
                  hintStyle: AppTextStyles.bodyMedium(
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {});
                  context.read<SocialCubit>().setSearchQuery('');
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SocialState state, SocialLoaded? loaded) {
    if (loaded == null) {
      if (state is SocialError) {
        return ErrorStateView(
          message: state.message,
          onRetry: _handleRefresh,
        );
      }
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          ShimmerBox(height: 64),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(height: 64),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(height: 64),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(height: 64),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      child: _selectedTabIndex == 0
          ? _buildFriendsTab(loaded)
          : _buildChatsTab(loaded),
    );
  }

  Widget _buildFriendsTab(SocialLoaded state) {
    final inGame = state.inGameFriends;
    final online = state.onlineFriends;
    final offline = state.offlineFriends;
    final hasResults =
        inGame.isNotEmpty || online.isNotEmpty || offline.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (!hasResults)
          EmptyStateView(
            icon: Icons.group_outlined,
            title: state.friends.isEmpty
                ? 'No friends connected'
                : 'No friends match this search',
            description: state.friends.isEmpty
                ? 'Sync your Riot friends to see live presence and matches.'
                : 'Try a different name or clear the search.',
            buttonText: state.friends.isEmpty ? 'SYNC RIOT FRIENDS' : null,
            onButtonPressed: state.friends.isEmpty ? _handleRefresh : null,
          )
        else ...[
          if (inGame.isNotEmpty)
            _buildGroup(
              index: '01',
              title: 'IN GAME',
              friends: inGame,
              unreadCounts: state.unreadCounts,
            ),
          if (online.isNotEmpty)
            _buildGroup(
              index: inGame.isNotEmpty ? '02' : '01',
              title: 'ONLINE',
              friends: online,
              unreadCounts: state.unreadCounts,
            ),
          if (offline.isNotEmpty)
            _buildGroup(
              index: inGame.isNotEmpty && online.isNotEmpty
                  ? '03'
                  : (inGame.isNotEmpty || online.isNotEmpty ? '02' : '01'),
              title: 'OFFLINE',
              friends: offline,
              unreadCounts: state.unreadCounts,
            ),
        ],
      ],
    );
  }

  Widget _buildChatsTab(SocialLoaded state) {
    final chats = state.chatFriends;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (chats.isEmpty)
          const EmptyStateView(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No conversations yet',
            description: 'Chats with your Riot friends will appear here.',
          )
        else
          _buildGroup(
            index: '01',
            title: 'CHATS',
            friends: chats,
            unreadCounts: state.unreadCounts,
            isChat: true,
          ),
      ],
    );
  }

  Widget _buildGroup({
    required String index,
    required String title,
    required List<FriendEntity> friends,
    required Map<String, int> unreadCounts,
    bool isChat = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            index: index,
            title: title,
            trailing: Text(
              '${friends.length}',
              style: AppTextStyles.statLabel(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          DataPanel(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: AppRadius.roundedLg,
              child: Column(
                children: [
                  for (var i = 0; i < friends.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    _buildFriendRow(
                      friends[i],
                      isChat: isChat,
                      unreadCount: unreadCounts[friends[i].puuid] ?? 0,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRow(
    FriendEntity friend, {
    required bool isChat,
    required int unreadCount,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isChat
            ? SocialChatSheet.show(context, friend)
            : _showFriendDetailSheet(friend),
        child: Container(
          color: friend.isPlaying
              ? AppColors.accent.withValues(alpha: 0.035)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _buildAvatar(friend),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (friend.isFavorite) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.vpGold,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    _buildSubtitle(friend, isChat),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isChat)
                _buildChatTrailing(friend, unreadCount)
              else
                _buildPresenceTrailing(friend),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(FriendEntity friend) {
    final initial = friend.gameName.isNotEmpty
        ? friend.gameName[0].toUpperCase()
        : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: AppRadius.roundedSm,
            border: Border.all(
              color: friend.isPlaying
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: friend.cardSmallArt != null
              ? CachedNetworkImage(
                  imageUrl: friend.cardSmallArt!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Center(
                    child: Text(
                      initial,
                      style: AppTextStyles.mono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initial,
                    style: AppTextStyles.mono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(friend.status),
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(FriendEntity friend, bool isChat) {
    if (isChat) {
      return Text(
        friend.lastChatMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(color: AppColors.textSecondary),
      );
    }

    if (friend.isPlaying) {
      return Row(
        children: [
          const Icon(
            Icons.sports_esports_outlined,
            size: 12,
            color: AppColors.accent,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _activityText(friend),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(
                color: AppColors.accent,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    final text = switch (friend.status) {
      FriendLiveStatus.inLobby => friend.clientActivity ?? 'In client',
      FriendLiveStatus.away => friend.isMobile ? 'Away on mobile' : 'Away',
      FriendLiveStatus.offline => 'Offline',
      _ => friend.clientActivity ?? 'Online',
    };

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.caption(color: AppColors.textMuted),
    );
  }

  Widget _buildPresenceTrailing(FriendEntity friend) {
    if (!friend.isPlaying) {
      return GestureDetector(
        onTap: () => SocialChatSheet.show(context, friend),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: AppRadius.roundedSm,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 15,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    final activity = friend.liveActivity;
    final score = activity?.scoreDisplay.isNotEmpty == true
        ? activity!.scoreDisplay.replaceAll(' ', '')
        : 'LIVE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          score,
          style: AppTextStyles.statValue(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        if (activity != null && activity.roundHistory.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildRoundTape(activity.roundHistory),
        ],
      ],
    );
  }

  Widget _buildRoundTape(List<bool> history) {
    final visible = history.length > 6
        ? history.sublist(history.length - 6)
        : history;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final won in visible)
          Container(
            width: 3,
            height: 9,
            margin: const EdgeInsets.only(left: 2),
            color: won ? AppColors.winGreen : AppColors.lossRed,
          ),
      ],
    );
  }

  Widget _buildChatTrailing(FriendEntity friend, int unreadCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatChatDate(friend.lastChatTimestamp),
          style: AppTextStyles.statLabel(color: AppColors.textMuted).copyWith(
            fontSize: 9,
            letterSpacing: 0,
          ),
        ),
        if (unreadCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(minWidth: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: AppRadius.roundedPill,
            ),
            alignment: Alignment.center,
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: AppTextStyles.mono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.onAccent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _activityText(FriendEntity friend) {
    final activity = friend.liveActivity;
    if (activity == null) return friend.clientActivity ?? 'In game';

    final parts = <String>[
      activity.modeName ?? 'Competitive',
      if (activity.mapName != null && activity.mapName!.isNotEmpty)
        activity.mapName!,
    ];
    return parts.join(' / ');
  }

  Color _statusColor(FriendLiveStatus status) {
    return switch (status) {
      FriendLiveStatus.inGame => AppColors.accent,
      FriendLiveStatus.inAgentSelect => AppColors.vpGold,
      FriendLiveStatus.inLobby => AppColors.winGreen,
      FriendLiveStatus.away => AppColors.drawAmber,
      FriendLiveStatus.offline => AppColors.textMuted,
    };
  }

  String _formatChatDate(DateTime? time) {
    if (time == null) return '';
    return DateFormat('MMM d').format(time);
  }

  Future<void> _showFriendDetailSheet(FriendEntity friend) async {
    var isFavorite = friend.isFavorite;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activity = friend.liveActivity;

            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.82,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDetailArt(friend, sheetContext),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _buildAvatar(friend),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend.gameName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.h2(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        friend.tagLine.isEmpty
                                            ? 'RIOT ID'
                                            : '#${friend.tagLine}',
                                        style: AppTextStyles.statLabel(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ValorantRankIcon(
                                  tier: friend.rankTier,
                                  iconUrl: friend.rankIcon,
                                  tierName: friend.rankName ?? 'Unrated',
                                  size: 34,
                                ),
                              ],
                            ),
                            if (activity != null && friend.isPlaying) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _buildLivePanel(activity),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            DataPanel(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'RANK',
                                    friend.rankName ?? 'Unrated',
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                  _buildInfoRow(
                                    'LEVEL',
                                    '${friend.accountLevel}',
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                  _buildInfoRow(
                                    'STATUS',
                                    _statusLabel(friend.status),
                                    valueColor: _statusColor(friend.status),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(sheetContext).pop();
                                      SocialChatSheet.show(this.context, friend);
                                    },
                                    icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('MESSAGE'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                OutlinedButton(
                                  onPressed: () {
                                    setSheetState(
                                      () => isFavorite = !isFavorite,
                                    );
                                    this
                                        .context
                                        .read<SocialCubit>()
                                        .toggleFavorite(friend.puuid);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(46, 46),
                                    padding: EdgeInsets.zero,
                                    foregroundColor: isFavorite
                                        ? AppColors.vpGold
                                        : AppColors.textSecondary,
                                  ),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(sheetContext).pop();
                                    this
                                        .context
                                        .read<SocialCubit>()
                                        .removeFriend(friend.puuid);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(46, 46),
                                    padding: EdgeInsets.zero,
                                    foregroundColor: AppColors.lossRed,
                                  ),
                                  child: const Icon(
                                    Icons.person_remove_outlined,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailArt(FriendEntity friend, BuildContext sheetContext) {
    return SizedBox(
      height: 170,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (friend.cardWideArt != null)
            CachedNetworkImage(
              imageUrl: friend.cardWideArt!,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: AppColors.surface),
            )
          else
            const ColoredBox(color: AppColors.surface),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.background],
                stops: [0.35, 1],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: IconButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
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

  Widget _buildLivePanel(FriendLiveActivity activity) {
    return DataPanel(
      tone: PanelTone.inset,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LIVE MATCH',
                style: AppTextStyles.statLabel(color: AppColors.accent),
              ),
              const Spacer(),
              Text(
                activity.durationDisplay,
                style: AppTextStyles.statLabel(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.scoreDisplay.isEmpty ? '0 - 0' : activity.scoreDisplay,
                style: AppTextStyles.scoreLarge(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (activity.roundHistory.isNotEmpty)
                _buildRoundTape(activity.roundHistory),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              activity.modeName ?? 'Competitive',
              if (activity.mapName != null) activity.mapName!,
              if (activity.agentName != null) activity.agentName!,
            ].join(' / '),
            style: AppTextStyles.caption(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.statLabel(color: AppColors.textMuted),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium(
              color: valueColor ?? AppColors.textPrimary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _statusLabel(FriendLiveStatus status) {
    return switch (status) {
      FriendLiveStatus.inGame => 'In game',
      FriendLiveStatus.inAgentSelect => 'Agent select',
      FriendLiveStatus.inLobby => 'Online',
      FriendLiveStatus.away => 'Away',
      FriendLiveStatus.offline => 'Offline',
    };
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.roundedPill,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(
                  Icons.sync_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                title: Text(
                  'Sync Riot friends',
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  this.context
                      .read<SocialCubit>()
                      .syncRiotFriends(clearMocks: true);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.history_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                title: Text(
                  'Import recent teammates',
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final count = await this
                      .context
                      .read<SocialCubit>()
                      .importRecentTeammates();
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('$count teammates imported')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_add_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                title: Text(
                  'Add friend manually',
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddFriendDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
