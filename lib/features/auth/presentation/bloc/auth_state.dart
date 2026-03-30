import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated({required UserEntity user}) =
      Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.error({required Failure failure}) = AuthError;
}
