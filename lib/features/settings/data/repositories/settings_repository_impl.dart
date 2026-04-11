import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/error/exceptions.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:track/features/settings/data/mappers/user_settings_mapper.dart';
import 'package:track/features/settings/domain/entities/user_settings_entity.dart';
import 'package:track/features/settings/domain/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, UserSettingsEntity>> getSettings(
    String userId,
  ) async {
    try {
      var row = await _localDataSource.getSettings(userId);
      if (row == null) {
        // Create-on-read: upsert a default row for first-time users.
        await _localDataSource.upsertSettings(
          UserSettingsCompanion(
            userId: Value(userId),
            updatedAt: Value(DateTime.now()),
          ),
        );
        row = await _localDataSource.getSettings(userId);
      }
      return Right(row!.toEntity());
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserSettingsEntity>> watchSettings(String userId) {
    return _localDataSource.watchSettings(userId).map((row) {
      if (row == null) return const Left(Failure.cache(message: 'No settings'));
      return Right(row.toEntity());
    });
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(
    UserSettingsEntity settings,
  ) async {
    try {
      await _localDataSource.upsertSettings(settings.toCompanion());
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateDisplayName(
    String userId,
    String displayName,
  ) async {
    try {
      await _localDataSource.updateSettings(
        userId,
        UserSettingsCompanion(
          displayName: Value(displayName),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCurrency(
    String userId,
    String currencyCode,
  ) async {
    try {
      await _localDataSource.updateSettings(
        userId,
        UserSettingsCompanion(
          currency: Value(currencyCode),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeOnboarding(String userId) async {
    try {
      await _localDataSource.updateSettings(
        userId,
        UserSettingsCompanion(
          onboardingCompleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }
}
