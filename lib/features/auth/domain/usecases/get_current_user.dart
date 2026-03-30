import 'package:injectable/injectable.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class GetCurrentUser {
  GetCurrentUser(this._repository);

  final AuthRepository _repository;

  UserEntity? call() => _repository.currentUser;
}
