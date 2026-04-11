import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';
import 'package:track/features/settings/domain/repositories/settings_repository.dart';

@lazySingleton
class CompleteOnboarding implements UseCase<Unit, CompleteOnboardingParams> {
  CompleteOnboarding(this._settingsRepository, this._authRepository);

  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, Unit>> call(CompleteOnboardingParams params) async {
    // 1. Save display name to local settings.
    final nameResult = await _settingsRepository.updateDisplayName(
      params.userId,
      params.displayName,
    );
    if (nameResult.isLeft()) return nameResult;

    // 2. Save currency to local settings.
    final currencyResult = await _settingsRepository.updateCurrency(
      params.userId,
      params.currencyCode,
    );
    if (currencyResult.isLeft()) return currencyResult;

    // 3. Mark onboarding complete in local settings.
    final completeResult = await _settingsRepository.completeOnboarding(
      params.userId,
    );
    if (completeResult.isLeft()) return completeResult;

    // 4. Update Firebase Auth display name (best-effort, non-blocking).
    await _authRepository.updateDisplayName(params.displayName);

    return const Right(unit);
  }
}

class CompleteOnboardingParams extends Equatable {
  const CompleteOnboardingParams({
    required this.userId,
    required this.displayName,
    required this.currencyCode,
  });

  final String userId;
  final String displayName;
  final String currencyCode;

  @override
  List<Object?> get props => [userId, displayName, currencyCode];
}
