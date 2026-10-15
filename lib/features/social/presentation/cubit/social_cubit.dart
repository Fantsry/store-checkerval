import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/domain/repositories/social_repository.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_state.dart';

class SocialCubit extends Cubit<SocialState> {
  final SocialRepository _socialRepository;

  SocialCubit({required SocialRepository socialRepository})
      : _socialRepository = socialRepository,
        super(const SocialInitial());

  List<FriendEntity>? get _currentFriends {
    final s = state;
    if (s is SocialLoaded) return s.friends;
    if (s is SocialLoading) return s.cachedFriends;
    if (s is SocialError) return s.cachedFriends;
    return null;
  }

  Future<void> loadFriends({bool forceRefresh = false}) async {
    final current = _currentFriends;
    if (current == null) {
      emit(const SocialLoading());
    } else if (state is SocialLoaded) {
      emit((state as SocialLoaded).copyWith(isRefreshing: true));
    }

    final result = await _socialRepository.getFriends(forceRefresh: forceRefresh);

    result.when(
      success: (friends) {
        if (state is SocialLoaded) {
          final s = state as SocialLoaded;
          emit(s.copyWith(friends: friends, isRefreshing: false));
        } else {
          emit(SocialLoaded(friends: friends));
        }
      },
      failure: (failure) {
        if (current != null && current.isNotEmpty) {
          emit(SocialLoaded(friends: current, isRefreshing: false));
        } else {
          emit(SocialError(message: failure.message, cachedFriends: current));
        }
      },
    );
  }

  Future<void> refreshLivePresence() async {
    if (state is SocialLoaded) {
      emit((state as SocialLoaded).copyWith(isRefreshing: true));
    }

    final result = await _socialRepository.refreshLivePresence();

    result.when(
      success: (updated) {
        if (state is SocialLoaded) {
          emit((state as SocialLoaded).copyWith(friends: updated, isRefreshing: false));
        } else {
          emit(SocialLoaded(friends: updated));
        }
      },
      failure: (failure) {
        if (state is SocialLoaded) {
          emit((state as SocialLoaded).copyWith(isRefreshing: false));
        } else {
          emit(SocialError(message: failure.message, cachedFriends: _currentFriends));
        }
      },
    );
  }

  void setFilter(FriendFilter filter) {
    if (state is SocialLoaded) {
      emit((state as SocialLoaded).copyWith(activeFilter: filter));
    }
  }

  void setSearchQuery(String query) {
    if (state is SocialLoaded) {
      emit((state as SocialLoaded).copyWith(searchQuery: query));
    }
  }

  Future<bool> addFriend({
    required String puuid,
    String? gameName,
    String? tagLine,
  }) async {
    final result = await _socialRepository.addFriend(
      puuid: puuid,
      gameName: gameName,
      tagLine: tagLine,
    );

    return result.when(
      success: (friend) {
        final list = List<FriendEntity>.from(_currentFriends ?? []);
        list.removeWhere((f) => f.puuid == friend.puuid);
        list.insert(0, friend);

        if (state is SocialLoaded) {
          emit((state as SocialLoaded).copyWith(friends: list));
        } else {
          emit(SocialLoaded(friends: list));
        }
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<bool> addFriendByRiotId(String riotId) async {
    final result = await _socialRepository.addFriendByRiotId(riotId);

    return result.when(
      success: (friend) {
        final list = List<FriendEntity>.from(_currentFriends ?? []);
        list.removeWhere((f) => f.puuid == friend.puuid);
        list.insert(0, friend);

        if (state is SocialLoaded) {
          emit((state as SocialLoaded).copyWith(friends: list));
        } else {
          emit(SocialLoaded(friends: list));
        }
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<void> removeFriend(String puuid) async {
    final result = await _socialRepository.removeFriend(puuid);

    result.when(
      success: (_) {
        final list = List<FriendEntity>.from(_currentFriends ?? []);
        list.removeWhere((f) => f.puuid == puuid);
        if (state is SocialLoaded) {
          emit((state as SocialLoaded).copyWith(friends: list));
        } else {
          emit(SocialLoaded(friends: list));
        }
      },
      failure: (_) {},
    );
  }

  Future<void> toggleFavorite(String puuid) async {
    final result = await _socialRepository.toggleFavorite(puuid);

    result.when(
      success: (updated) {
        final list = List<FriendEntity>.from(_currentFriends ?? []);
        final idx = list.indexWhere((f) => f.puuid == puuid);
        if (idx != -1) {
          list[idx] = updated;
          if (state is SocialLoaded) {
            emit((state as SocialLoaded).copyWith(friends: list));
          } else {
            emit(SocialLoaded(friends: list));
          }
        }
      },
      failure: (_) {},
    );
  }

  Future<int> importRecentTeammates() async {
    final result = await _socialRepository.importRecentTeammates();

    return result.when(
      success: (imported) {
        if (imported.isNotEmpty) {
          final list = List<FriendEntity>.from(_currentFriends ?? []);
          for (final f in imported) {
            list.removeWhere((existing) => existing.puuid == f.puuid);
            list.add(f);
          }
          if (state is SocialLoaded) {
            emit((state as SocialLoaded).copyWith(friends: list));
          } else {
            emit(SocialLoaded(friends: list));
          }
        }
        return imported.length;
      },
      failure: (_) => 0,
    );
  }

  Future<List<MatchPlayerSummary>> getRecentAvailableTeammates() {
    return _socialRepository.getRecentAvailableTeammates();
  }

  /// Manually advance round won by ally (friend's team)
  Future<void> simulateRoundWon(String puuid) async {
    final result = await _socialRepository.updateFriendRound(
      puuid: puuid,
      isAllyWon: true,
    );

    result.when(
      success: (updated) {
        final list = List<FriendEntity>.from(_currentFriends ?? []);
        final idx = list.indexWhere((f) => f.puuid == puuid);
        if (idx != -1) {
          list[idx] = updated;
          if (state is SocialLoaded) {
            emit((state as SocialLoaded).copyWith(friends: list));
          } else {
            emit(SocialLoaded(friends: list));
          }
        }
      },
      failure: (_) {},
    );
  }

  /// Manually advance round won by enemy team
  Future<void> simulateRoundLost(String puuid) async {
    final result = await _socialRepository.updateFriendRound(
      puuid: puuid,
      isAllyWon: false,
    );

    result.when(
      success: (updated) {
        final list = List<FriendEntity>.from(_currentFriends ?? []);
        final idx = list.indexWhere((f) => f.puuid == puuid);
        if (idx != -1) {
          list[idx] = updated;
          if (state is SocialLoaded) {
            emit((state as SocialLoaded).copyWith(friends: list));
          } else {
            emit(SocialLoaded(friends: list));
          }
        }
      },
      failure: (_) {},
    );
  }
}
