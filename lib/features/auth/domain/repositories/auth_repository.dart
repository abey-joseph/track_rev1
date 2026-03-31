import 'package:fpdart/fpdart.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  UserEntity? get currentUser;

  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signInWithGoogle();

  Future<Either<Failure, UserEntity>> signInAnonymously();

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, UserEntity>> createAccountWithEmail({
    required String email,
    required String password,
  });
}
