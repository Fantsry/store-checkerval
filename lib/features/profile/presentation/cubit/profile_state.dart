import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  final UserProfile? cachedProfile;
  const ProfileLoading({this.cachedProfile});

  @override
  List<Object?> get props => [cachedProfile];
}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  final UserProfile? cachedProfile;
  const ProfileError(this.message, {this.cachedProfile});

  @override
  List<Object?> get props => [message, cachedProfile];
}

class ProfileUnauthenticated extends ProfileState {
  const ProfileUnauthenticated();
}
