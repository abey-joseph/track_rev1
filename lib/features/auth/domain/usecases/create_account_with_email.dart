import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';
import 'package:track/features/auth/domain/usecases/sign_in_with_email.dart';

@lazySingleton
class CreateAccountWithEmail
    implements UseCase<UserEntity, SignInWithEmailParams> {
  CreateAccountWithEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignInWithEmailParams params) =>
      _repository.createAccountWithEmail(
        email: params.email,
        password: params.password,
      );
}
