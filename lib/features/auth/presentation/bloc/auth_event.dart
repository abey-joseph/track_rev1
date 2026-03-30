import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.signInWithEmailRequested({
    required String email,
    required String password,
  }) = SignInWithEmailRequested;

  const factory AuthEvent.signInWithGoogleRequested() =
      SignInWithGoogleRequested;

  const factory AuthEvent.signInWithAppleRequested() = SignInWithAppleRequested;

  const factory AuthEvent.signInAnonymouslyRequested() =
      SignInAnonymouslyRequested;

  const factory AuthEvent.signOutRequested() = SignOutRequested;

  const factory AuthEvent.authCheckRequested() = AuthCheckRequested;

  const factory AuthEvent.createAccountWithEmailRequested({
    required String email,
    required String password,
  }) = CreateAccountWithEmailRequested;
}
