import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_session.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  final AuthSession session;
  const AuthAuthenticated(this.session);

  @override
  List<Object?> get props => [session];
}

class Auth2FaRequired extends AuthState {
  final String email;
  final String method;
  final String sessionCookies;

  const Auth2FaRequired({
    required this.email,
    required this.method,
    required this.sessionCookies,
  });

  @override
  List<Object?> get props => [email, method, sessionCookies];
}

class AuthUnauthenticated extends AuthState {
  final String? message;
  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
