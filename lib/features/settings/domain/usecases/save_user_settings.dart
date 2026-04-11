import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/settings/domain/entities/user_settings_entity.dart';
import 'package:track/features/settings/domain/repositories/settings_repository.dart';

@lazySingleton
class SaveUserSettings implements UseCase<Unit, SaveUserSettingsParams> {
  SaveUserSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveUserSettingsParams params) =>
      _repository.saveSettings(params.settings);
}

class SaveUserSettingsParams {
  const SaveUserSettingsParams({required this.settings});

  final UserSettingsEntity settings;
}
