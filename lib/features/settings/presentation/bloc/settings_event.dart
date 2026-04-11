import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/features/settings/domain/entities/user_settings_entity.dart';

part 'settings_event.freezed.dart';

@freezed
sealed class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.loadRequested({required String userId}) =
      SettingsLoadRequested;

  const factory SettingsEvent.themeChanged({
    required AppThemeMode themeMode,
  }) = SettingsThemeChanged;

  const factory SettingsEvent.displayNameChanged({
    required String displayName,
  }) = SettingsDisplayNameChanged;

  const factory SettingsEvent.currencyChanged({
    required String currencyCode,
  }) = SettingsCurrencyChanged;
}
