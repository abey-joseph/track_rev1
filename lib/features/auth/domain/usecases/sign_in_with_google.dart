import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class SignInWithGoogle implements UseCase<UserEntity, NoParams> {
  SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.signInWithGoogle();
}
