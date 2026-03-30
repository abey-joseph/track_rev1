import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:track/core/error/exceptions.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:track/features/auth/data/models/user_dto.dart';
import 'package:track/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  const testDto = UserDto(
    uid: 'test-uid',
    email: 'test@test.com',
    isAnonymous: false,
  );

  const testEntity = UserEntity(
    uid: 'test-uid',
    email: 'test@test.com',
    isAnonymous: false,
  );

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  group('signInWithEmail', () {
    test('returns UserEntity on success', () async {
      when(
        () => mockRemoteDataSource.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testDto);

      final result = await repository.signInWithEmail(
        email: 'test@test.com',
        password: 'password',
      );

      expect(result, equals(const Right<Failure, UserEntity>(testEntity)));
    });

    test('returns AuthFailure on ServerException', () async {
      when(
        () => mockRemoteDataSource.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ServerException(message: 'Invalid credentials', statusCode: 401),
      );

      final result = await repository.signInWithEmail(
        email: 'test@test.com',
        password: 'wrong',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('signOut', () {
    test('returns Right(unit) on success', () async {
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, equals(const Right<Failure, Unit>(unit)));
    });
  });
}
