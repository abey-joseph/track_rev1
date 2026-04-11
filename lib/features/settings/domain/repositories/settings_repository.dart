import 'package:fpdart/fpdart.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/settings/domain/entities/user_settings_entity.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserSettingsEntity>> getSettings(String userId);

  Stream<Either<Failure, UserSettingsEntity>> watchSettings(String userId);

  Future<Either<Failure, Unit>> saveSettings(UserSettingsEntity settings);

  Future<Either<Failure, Unit>> updateDisplayName(
    String userId,
    String displayName,
  );

  Future<Either<Failure, Unit>> updateCurrency(
    String userId,
    String currencyCode,
  );

  Future<Either<Failure, Unit>> completeOnboarding(String userId);
}
