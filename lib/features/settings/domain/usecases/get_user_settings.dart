import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/settings/domain/entities/user_settings_entity.dart';
import 'package:track/features/settings/domain/repositories/settings_repository.dart';

@lazySingleton
class GetUserSettings
    implements UseCase<UserSettingsEntity, GetUserSettingsParams> {
  GetUserSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, UserSettingsEntity>> call(
    GetUserSettingsParams params,
  ) => _repository.getSettings(params.userId);
}

class GetUserSettingsParams extends Equatable {
  const GetUserSettingsParams({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}
