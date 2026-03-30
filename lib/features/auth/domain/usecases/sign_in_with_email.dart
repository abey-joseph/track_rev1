import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';

part 'sign_in_with_email.freezed.dart';

@lazySingleton
class SignInWithEmail implements UseCase<UserEntity, SignInWithEmailParams> {
  SignInWithEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignInWithEmailParams params) =>
      _repository.signInWithEmail(
        email: params.email,
        password: params.password,
      );
}

@freezed
abstract class SignInWithEmailParams with _$SignInWithEmailParams {
  const factory SignInWithEmailParams({
    required String email,
    required String password,
  }) = _SignInWithEmailParams;
}
