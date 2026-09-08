import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';

abstract class LiveMatchState extends Equatable {
  const LiveMatchState();

  @override
  List<Object?> get props => [];
}

class LiveMatchInitial extends LiveMatchState {
  const LiveMatchInitial();
}

class LiveMatchLoading extends LiveMatchState {
  const LiveMatchLoading();
}

class LiveMatchLoaded extends LiveMatchState {
  final LiveMatchData matchData;

  const LiveMatchLoaded({required this.matchData});

  @override
  List<Object?> get props => [matchData];
}

class LiveMatchError extends LiveMatchState {
  final String message;

  const LiveMatchError({required this.message});

  @override
  List<Object?> get props => [message];
}
