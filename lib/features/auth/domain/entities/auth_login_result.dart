import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/auth/domain/entities/auth_session.dart';

sealed class AuthLoginResult extends Equatable {
  const AuthLoginResult();

  @override
  List<Object?> get props => [];
}

class AuthLoginSuccess extends AuthLoginResult {
  final AuthSession session;
  const AuthLoginSuccess(this.session);

  @override
  List<Object?> get props => [session];
}

class AuthLogin2FaRequired extends AuthLoginResult {
  final String email;
  final String method;
  final String sessionCookies;

  const AuthLogin2FaRequired({
    required this.email,
    required this.method,
    required this.sessionCookies,
  });

  @override
  List<Object?> get props => [email, method, sessionCookies];
}
