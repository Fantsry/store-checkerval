import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';

sealed class StoreAlertState extends Equatable {
  const StoreAlertState();

  @override
  List<Object?> get props => [];
}

class StoreAlertInitial extends StoreAlertState {
  const StoreAlertInitial();
}

class StoreAlertLoading extends StoreAlertState {
  const StoreAlertLoading();
}

class StoreAlertLoaded extends StoreAlertState {
  final List<StoreAlertRule> rules;

  const StoreAlertLoaded({required this.rules});

  @override
  List<Object?> get props => [rules];
}

class StoreAlertError extends StoreAlertState {
  final String message;

  const StoreAlertError(this.message);

  @override
  List<Object?> get props => [message];
}
