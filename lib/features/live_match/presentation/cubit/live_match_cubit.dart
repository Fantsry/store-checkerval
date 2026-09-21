import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/features/live_match/domain/repositories/live_match_repository.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';

class LiveMatchCubit extends Cubit<LiveMatchState> {
  final LiveMatchRepository _repository;
  Timer? _transitionPollTimer;

  LiveMatchCubit({required LiveMatchRepository repository})
      : _repository = repository,
        super(const LiveMatchInitial());

  Future<void> scanLiveMatch({bool silent = false}) async {
    if (!silent) {
      emit(const LiveMatchLoading());
    }

    final result = await _repository.checkLiveMatch();

    result.when(
      success: (data) {
        emit(LiveMatchLoaded(matchData: data));
        if (data.phase == LiveMatchPhase.transitioning) {
          _scheduleTransitionPoll();
        } else {
          _transitionPollTimer?.cancel();
        }
      },
      failure: (failure) {
        emit(LiveMatchError(message: failure.message));
        _transitionPollTimer?.cancel();
      },
    );
  }

  void _scheduleTransitionPoll() {
    _transitionPollTimer?.cancel();
    _transitionPollTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed && state is LiveMatchLoaded) {
        final current = (state as LiveMatchLoaded).matchData;
        if (current.phase == LiveMatchPhase.transitioning) {
          scanLiveMatch(silent: true);
        }
      }
    });
  }

  @override
  Future<void> close() {
    _transitionPollTimer?.cancel();
    return super.close();
  }
}
