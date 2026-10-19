import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_state.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/add_friend_dialog.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/friend_card.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/social_chat_sheet.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _livePollingTimer;
  int _selectedTabIndex = 0; // 0: Friends, 1: Community, 2: Team

  @override
  void initState() {
    super.initState();

    final cubit = context.read<SocialCubit>();
    if (cubit.state is SocialInitial) {
      cubit.loadFriends();
    }

    // Auto-poll live presence every 15s to update real-time match scores and statuses
    _livePollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        final s = context.read<SocialCubit>().state;
        if (s is SocialLoaded && !s.isRefreshing) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  const Text(
                    'Social',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.push_pin_rounded, color: AppColors.red, size: 24),
                    tooltip: 'Pinned Squad',
                    onPressed: () {
                      context.read<SocialCubit>().refreshLivePresence();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 24),
                    tooltip: 'Social Settings',
                    onPressed: () => _showSettingsMenu(context),
                  ),
                ],
              ),
            ),

            // ── Top Tabs: [Friends] [Community] [Team] ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabPill(index: 0, title: 'Friends'),
                  const SizedBox(width: 8),
                  _buildTabPill(index: 1, title: 'Community'),
                  const SizedBox(width: 8),
                  _buildTabPill(index: 2, title: 'Team'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Search & Add Friend Bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF262C36), width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded, color: Color(0xFF8B949E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => context.read<SocialCubit>().setSearchQuery(val),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search friends or chats...',
                          hintStyle: TextStyle(color: Color(0xFF6E7681), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SocialCubit>().setSearchQuery('');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.red, size: 22),
                      tooltip: 'Add Friend',
                      onPressed: _showAddFriendDialog,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Content Area ────────────────────────────────────────────
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildFriendsTab()
                  : _selectedTabIndex == 1
                      ? _buildCommunityTab()
                      : _buildTeamTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({required int index, required String title}) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.red : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.red : const Color(0xFF262C36),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF8B949E),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return BlocConsumer<SocialCubit, SocialState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is SocialLoading && state.cachedFriends == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.red),
          );
        }

        if (state is SocialError && (state.cachedFriends == null || state.cachedFriends!.isEmpty)) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<SocialCubit>().syncRiotFriends(clearMocks: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Sinkronkan Ulang Teman Riot'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                ),
              ],
            ),
          );
        }

        if (state is SocialLoaded) {
          final inGame = state.inGameFriends;
          final chats = state.chatFriends;
          final online = state.onlineFriends;
          final offline = state.offlineFriends;

          if (state.friends.isEmpty) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.red,
              backgroundColor: const Color(0xFF161B22),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.group_outlined, size: 64, color: Color(0xFF334155)),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Belum ada teman yang terhubung',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Tarik ke bawah untuk menyinkronkan teman Riot secara real-time',
                      style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<SocialCubit>().syncRiotFriends(clearMocks: true),
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Sinkronkan Teman Riot (XMPP)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.red,
            backgroundColor: const Color(0xFF161B22),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // ── 1. IN GAME SECTION ──────────────────────────────────
                if (inGame.isNotEmpty) ...[
                  _buildSectionHeader('IN GAME', inGame.length),
                  const SizedBox(height: 8),
                  ...inGame.map((f) => _buildRealtimeFriendCard(f, section: 'IN_GAME')),
                  const SizedBox(height: 16),
                ],

                // ── 2. CHATS SECTION ────────────────────────────────────
                if (chats.isNotEmpty) ...[
                  _buildSectionHeader('CHATS', chats.length),
                  const SizedBox(height: 8),
                  ...chats.map((f) => _buildRealtimeFriendCard(f, section: 'CHATS')),
                  const SizedBox(height: 16),
                ],

                // ── 3. ONLINE SECTION ───────────────────────────────────
                if (online.isNotEmpty) ...[
                  _buildSectionHeader('ONLINE', online.length),
                  const SizedBox(height: 8),
                  ...online.map((f) => _buildRealtimeFriendCard(f, section: 'ONLINE')),
                  const SizedBox(height: 16),
                ],

                // ── 4. OFFLINE SECTION ──────────────────────────────────
                if (offline.isNotEmpty) ...[
                  _buildSectionHeader('OFFLINE', offline.length),
                  const SizedBox(height: 8),
                  ...offline.map((f) => _buildRealtimeFriendCard(f, section: 'OFFLINE')),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Text(
      '$title · $count',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF8B949E),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildRealtimeFriendCard(FriendEntity friend, {required String section}) {
    final isChatSection = section == 'CHATS';
    final isPlaying = friend.isPlaying;
    final isAway = friend.status == FriendLiveStatus.away;
    final isLobby = friend.status == FriendLiveStatus.inLobby;

    Color statusDotColor = const Color(0xFF64748B);
    if (isPlaying) {
      statusDotColor = AppColors.red;
    } else if (isLobby) {
      statusDotColor = const Color(0xFF22C55E); // Green dot
    } else if (isAway) {
      statusDotColor = const Color(0xFFEAB308); // Yellow dot
    }

    final avatarLetter = friend.gameName.isNotEmpty ? friend.gameName[0].toUpperCase() : 'A';
    final avatarBgColor = _getLetterColor(avatarLetter);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262C36), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showFriendDetailSheet(friend),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ── Left: Avatar with Status Dot ────────────────────────
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: avatarBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: friend.cardSmallArt != null
                          ? CachedNetworkImage(
                              imageUrl: friend.cardSmallArt!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(
                                child: Text(
                                  avatarLetter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                avatarLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusDotColor,
                          border: Border.all(color: const Color(0xFF161B22), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // ── Center: Title & Subtitle ────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Subtitle
                      if (isChatSection)
                        Text(
                          friend.lastChatMessage ?? '',
                          style: const TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (isPlaying)
                        Row(
                          children: [
                            const Icon(
                              Icons.desktop_windows_outlined,
                              size: 14,
                              color: AppColors.red,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _buildInGameSubtitle(friend),
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else if (isAway)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_android_rounded,
                              size: 14,
                              color: Color(0xFFEAB308),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Away',
                              style: TextStyle(
                                color: Color(0xFFEAB308),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else if (isLobby)
                        Row(
                          children: [
                            const Icon(
                              Icons.desktop_windows_outlined,
                              size: 14,
                              color: Color(0xFF8B949E),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              friend.clientActivity ?? 'In Riot Client',
                              style: const TextStyle(
                                color: Color(0xFF8B949E),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Offline',
                          style: TextStyle(
                            color: Color(0xFF6E7681),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Right: Trailing Chat Button or Date ─────────────────
                if (isChatSection)
                  Text(
                    _formatChatDate(friend.lastChatTimestamp),
                    style: const TextStyle(
                      color: Color(0xFF6E7681),
                      fontSize: 12,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => SocialChatSheet.show(context, friend),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C222B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF282F3B), width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF8B949E),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildInGameSubtitle(FriendEntity friend) {
    final activity = friend.liveActivity;
    if (activity == null) return friend.clientActivity ?? 'In Game';

    final mode = activity.modeName ?? 'Competitive';
    final map = activity.mapName ?? 'Valorant';
    final scoreAlly = activity.scoreAlly;
    final scoreEnemy = activity.scoreEnemy;

    if (scoreAlly != null && scoreEnemy != null) {
      return '$mode · $map · $scoreAlly-$scoreEnemy';
    }
    return '$mode · $map';
  }

  String _formatChatDate(DateTime? time) {
    if (time == null) return '';
    return DateFormat('MMM d, yyyy').format(time);
  }

  Color _getLetterColor(String letter) {
    final colors = [
      const Color(0xFF2E7D32), // Green
      const Color(0xFF00838F), // Teal
      const Color(0xFF4527A0), // Deep Purple
      const Color(0xFFAD1457), // Pink
      const Color(0xFFD84315), // Deep Orange
      const Color(0xFF1565C0), // Blue
    ];
    final code = letter.codeUnitAt(0);
    return colors[code % colors.length];
  }

  void _showFriendDetailSheet(FriendEntity friend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FriendCard(
                friend: friend,
                onFavoriteTap: () => context.read<SocialCubit>().toggleFavorite(friend.puuid),
                onDeleteTap: () {
                  Navigator.of(context).pop();
                  context.read<SocialCubit>().removeFriend(friend.puuid);
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  SocialChatSheet.show(context, friend);
                },
                icon: const Icon(Icons.chat_rounded),
                label: Text('Chat dengan ${friend.gameName}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sync_rounded, color: AppColors.cyan),
                title: const Text('Sinkronkan Ulang Teman Riot (XMPP)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<SocialCubit>().syncRiotFriends(clearMocks: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: Colors.white70),
                title: const Text('Impor Teman dari Riwayat Match', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(context).pop();
                  final count = await context.read<SocialCubit>().importRecentTeammates();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$count rekan tim berhasil diimpor!')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_rounded, color: AppColors.red),
                title: const Text('Tambah Teman Manual', style: TextStyle(color: Colors.white)),
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

  Widget _buildCommunityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCommunityCard(
          title: 'Official Valorant Discord',
          subtitle: 'Join 500k+ players for LFG, patch notes, & squad scrims',
          icon: Icons.discord,
          badge: 'ACTIVE',
        ),
        const SizedBox(height: 12),
        _buildCommunityCard(
          title: 'SEA Competitive Hub',
          subtitle: 'Find Ascendant - Radiant 5-stack parties and tournaments',
          icon: Icons.shield_rounded,
          badge: 'COMPETITIVE',
        ),
        const SizedBox(height: 12),
        _buildCommunityCard(
          title: 'Skin Trading & Market Watch',
          subtitle: 'Live night market discussions and bundle reviews',
          icon: Icons.shopping_bag_outlined,
          badge: 'TRENDING',
        ),
      ],
    );
  }

  Widget _buildCommunityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262C36)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C222B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.red, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(color: AppColors.red, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6E7681), size: 14),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2633), Color(0xFF161B22)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded, color: AppColors.red, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Premier Division',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'STAGE E10',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Squad roster terhubung dengan Riot XMPP Roster. Buat tim Premier atau pantau jadwal pertandingan mingguan bersama teman.',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddFriendDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Undang Teman ke Squad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
