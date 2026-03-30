import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class SignOut implements UseCase<Unit, NoParams> {
  SignOut(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.signOut();
}
