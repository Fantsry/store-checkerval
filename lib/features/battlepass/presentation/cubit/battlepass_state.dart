import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/entities/battlepass_overview.dart';

abstract class BattlepassState extends Equatable {
  const BattlepassState();

  @override
  List<Object?> get props => [];
}

class BattlepassInitial extends BattlepassState {
  const BattlepassInitial();
}

class BattlepassLoading extends BattlepassState {
  const BattlepassLoading();
}

class BattlepassLoaded extends BattlepassState {
  final BattlepassOverview overview;

  const BattlepassLoaded({required this.overview});

  @override
  List<Object?> get props => [overview];
}

class BattlepassError extends BattlepassState {
  final String message;

  const BattlepassError({required this.message});

  @override
  List<Object?> get props => [message];
}
