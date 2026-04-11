import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/settings/domain/repositories/settings_repository.dart';

/// Returns [Right(true)] when the user has already completed onboarding,
/// [Right(false)] when they have not, or a [Left(Failure)] on error.
@lazySingleton
class CheckOnboardingStatus {
  CheckOnboardingStatus(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  Future<Either<Failure, bool>> call(String userId) async {
    final result = await _settingsRepository.getSettings(userId);
    return result.map((settings) => settings.onboardingCompleted);
  }
}
