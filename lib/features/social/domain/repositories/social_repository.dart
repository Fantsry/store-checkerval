import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/chat_message.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';

abstract class SocialRepository {
  /// Retrieve all tracked friends with their current live status & player card.
  Future<Result<List<FriendEntity>>> getFriends({bool forceRefresh = false});

  /// Add a friend by PUUID and fetch their real player card, rank, and live activity.
  Future<Result<FriendEntity>> addFriend({
    required String puuid,
    String? gameName,
    String? tagLine,
  });

  /// Add a friend by Riot ID (e.g. "TenZ#0001").
  Future<Result<FriendEntity>> addFriendByRiotId(String riotId);

  /// Remove a tracked friend.
  Future<Result<void>> removeFriend(String puuid);

  /// Toggle favorite / pinned status for a friend.
  Future<Result<FriendEntity>> toggleFavorite(String puuid);

  /// Automatically import teammates from recent matches into tracked friends list.
  Future<Result<List<FriendEntity>>> importRecentTeammates();

  /// Poll live match telemetry (GLZ CoreGame & PreGame) for all tracked friends.
  Future<Result<List<FriendEntity>>> refreshLivePresence();

  /// Get recent teammates from career who aren't yet added to friends.
  Future<List<MatchPlayerSummary>> getRecentAvailableTeammates();

  /// Update or simulate a round win or loss for a friend in an active match.
  Future<Result<FriendEntity>> updateFriendRound({
    required String puuid,
    required bool isAllyWon,
  });

  /// Synchronize real Riot friends from remote XMPP roster and match history.
  /// Automatically purges mock/dummy friends.
  Future<Result<List<FriendEntity>>> syncRiotFriends({bool clearMocks = true});

  /// Remove all mock/dummy seeded friends from local storage.
  Future<Result<void>> clearMockFriends();

  /// Load locally persisted direct-message history for a friend.
  Future<Result<List<ChatMessageEntity>>> getChatMessages(String puuid);

  /// Send a direct XMPP message and persist it locally.
  Future<Result<ChatMessageEntity>> sendChatMessage({
    required String puuid,
    required String body,
  });

  /// Unread incoming message counts keyed by friend PUUID.
  Future<Map<String, int>> getUnreadChatCounts();

  /// Mark the latest stored message in a conversation as read.
  Future<void> markChatRead(String puuid);
}
