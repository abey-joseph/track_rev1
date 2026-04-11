import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/settings/domain/entities/user_settings_entity.dart';

part 'settings_state.freezed.dart';

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = SettingsInitial;

  const factory SettingsState.loading() = SettingsLoading;

  const factory SettingsState.loaded({required UserSettingsEntity settings}) =
      SettingsLoaded;

  const factory SettingsState.error({required Failure failure}) = SettingsError;
}
