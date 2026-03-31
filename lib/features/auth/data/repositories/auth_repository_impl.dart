import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/exceptions.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:track/features/auth/data/mappers/user_mapper.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  UserEntity? get currentUser => _remoteDataSource.currentUser?.toEntity();

  @override
  Stream<UserEntity?> get authStateChanges =>
      _remoteDataSource.authStateChanges.map((dto) => dto?.toEntity());

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final dto = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(
        Failure.auth(message: e.message, code: e.statusCode?.toString()),
      );
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final dto = await _remoteDataSource.signInWithGoogle();
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(
        Failure.auth(message: e.message, code: e.statusCode?.toString()),
      );
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInAnonymously() async {
    try {
      final dto = await _remoteDataSource.signInAnonymously();
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(
        Failure.auth(message: e.message, code: e.statusCode?.toString()),
      );
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(unit);
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final dto = await _remoteDataSource.createAccountWithEmail(
        email: email,
        password: password,
      );
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(
        Failure.auth(message: e.message, code: e.statusCode?.toString()),
      );
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }
}
