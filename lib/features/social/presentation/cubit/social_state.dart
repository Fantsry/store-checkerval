import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';

enum FriendFilter {
  all,
  inGame,
  inLobby,
  offline,
}

abstract class SocialState extends Equatable {
  const SocialState();

  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {
  const SocialInitial();
}

class SocialLoading extends SocialState {
  final List<FriendEntity>? cachedFriends;

  const SocialLoading({this.cachedFriends});

  @override
  List<Object?> get props => [cachedFriends];
}

class SocialLoaded extends SocialState {
  final List<FriendEntity> friends;
  final FriendFilter activeFilter;
  final String searchQuery;
  final bool isRefreshing;

  const SocialLoaded({
    required this.friends,
    this.activeFilter = FriendFilter.all,
    this.searchQuery = '',
    this.isRefreshing = false,
  });

  int get totalCount => friends.length;

  int get playingCount => friends
      .where((f) =>
          f.status == FriendLiveStatus.inGame ||
          f.status == FriendLiveStatus.inAgentSelect)
      .length;

  int get inLobbyCount =>
      friends.where((f) => f.status == FriendLiveStatus.inLobby || f.status == FriendLiveStatus.away).length;

  int get awayCount =>
      friends.where((f) => f.status == FriendLiveStatus.away).length;

  int get offlineCount =>
      friends.where((f) => f.status == FriendLiveStatus.offline).length;

  int get chatCount =>
      friends.where((f) => f.lastChatMessage != null && f.lastChatMessage!.isNotEmpty).length;

  List<FriendEntity> get inGameFriends =>
      filteredFriends.where((f) => f.isPlaying).toList();

  List<FriendEntity> get chatFriends =>
      filteredFriends.where((f) => f.lastChatMessage != null && f.lastChatMessage!.isNotEmpty).toList();

  List<FriendEntity> get onlineFriends =>
      filteredFriends.where((f) => f.status == FriendLiveStatus.inLobby || f.status == FriendLiveStatus.away).toList();

  List<FriendEntity> get offlineFriends =>
      filteredFriends.where((f) => f.status == FriendLiveStatus.offline).toList();

  List<FriendEntity> get filteredFriends {
    var list = friends;

    // Filter by tab
    switch (activeFilter) {
      case FriendFilter.inGame:
        list = list.where((f) => f.isPlaying).toList();
        break;
      case FriendFilter.inLobby:
        list = list
            .where((f) => f.status == FriendLiveStatus.inLobby || f.status == FriendLiveStatus.away)
            .toList();
        break;
      case FriendFilter.offline:
        list = list
            .where((f) => f.status == FriendLiveStatus.offline)
            .toList();
        break;
      case FriendFilter.all:
        break;
    }

    // Filter by search query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((f) {
        return f.gameName.toLowerCase().contains(q) ||
            f.tagLine.toLowerCase().contains(q) ||
            (f.clientActivity?.toLowerCase().contains(q) ?? false) ||
            (f.lastChatMessage?.toLowerCase().contains(q) ?? false) ||
            (f.liveActivity?.mapName?.toLowerCase().contains(q) ?? false) ||
            (f.liveActivity?.modeName?.toLowerCase().contains(q) ?? false) ||
            (f.liveActivity?.agentName?.toLowerCase().contains(q) ?? false) ||
            (f.rankName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Sort: Favorites first, then Playing (inGame > inAgentSelect), then inLobby, then away, then offline
    final sorted = List<FriendEntity>.from(list);
    sorted.sort((a, b) {
      // 1. Favorites always at top
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }

      // 2. Status priority
      final aPriority = _statusPriority(a.status);
      final bPriority = _statusPriority(b.status);
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      // 3. Rank rating
      final aTier = a.rankTier ?? 0;
      final bTier = b.rankTier ?? 0;
      if (aTier != bTier) {
        return bTier.compareTo(aTier);
      }

      // 4. Alphabetical
      return a.gameName.toLowerCase().compareTo(b.gameName.toLowerCase());
    });

    return sorted;
  }

  static int _statusPriority(FriendLiveStatus status) {
    switch (status) {
      case FriendLiveStatus.inGame:
        return 0;
      case FriendLiveStatus.inAgentSelect:
        return 1;
      case FriendLiveStatus.inLobby:
        return 2;
      case FriendLiveStatus.away:
        return 3;
      case FriendLiveStatus.offline:
        return 4;
    }
  }

  SocialLoaded copyWith({
    List<FriendEntity>? friends,
    FriendFilter? activeFilter,
    String? searchQuery,
    bool? isRefreshing,
  }) {
    return SocialLoaded(
      friends: friends ?? this.friends,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        friends,
        activeFilter,
        searchQuery,
        isRefreshing,
      ];
}

class SocialError extends SocialState {
  final String message;
  final List<FriendEntity>? cachedFriends;

  const SocialError({
    required this.message,
    this.cachedFriends,
  });

  @override
  List<Object?> get props => [message, cachedFriends];
}
