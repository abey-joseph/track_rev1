import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/settings/domain/entities/user_settings_entity.dart';
import 'package:track/features/settings/domain/repositories/settings_repository.dart';
import 'package:track/features/settings/domain/usecases/get_user_settings.dart';

@lazySingleton
class WatchUserSettings
    implements StreamUseCase<UserSettingsEntity, GetUserSettingsParams> {
  WatchUserSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Stream<Either<Failure, UserSettingsEntity>> call(
    GetUserSettingsParams params,
  ) => _repository.watchSettings(params.userId);
}
