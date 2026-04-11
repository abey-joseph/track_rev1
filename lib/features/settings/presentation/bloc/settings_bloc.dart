import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/settings/domain/usecases/get_user_settings.dart';
import 'package:track/features/settings/domain/usecases/save_user_settings.dart';
import 'package:track/features/settings/domain/usecases/watch_user_settings.dart';
import 'package:track/features/settings/presentation/bloc/settings_event.dart';
import 'package:track/features/settings/presentation/bloc/settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(
    this._watchUserSettings,
    this._saveUserSettings,
  ) : super(const SettingsState.initial()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsDisplayNameChanged>(_onDisplayNameChanged);
    on<SettingsCurrencyChanged>(_onCurrencyChanged);
  }

  final WatchUserSettings _watchUserSettings;
  final SaveUserSettings _saveUserSettings;

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsState.loading());
    await emit.forEach(
      _watchUserSettings(GetUserSettingsParams(userId: event.userId)),
      onData:
          (result) => result.fold(
            (failure) => SettingsState.error(failure: failure),
            (settings) => SettingsState.loaded(settings: settings),
          ),
      onError:
          (_, _) => const SettingsState.error(
            failure: Failure.cache(message: 'Failed to watch settings'),
          ),
    );
  }

  Future<void> _onThemeChanged(
    SettingsThemeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = current.settings.copyWith(themeMode: event.themeMode);
    await _saveUserSettings(SaveUserSettingsParams(settings: updated));
  }

  Future<void> _onDisplayNameChanged(
    SettingsDisplayNameChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = current.settings.copyWith(
      displayName: event.displayName,
    );
    await _saveUserSettings(SaveUserSettingsParams(settings: updated));
  }

  Future<void> _onCurrencyChanged(
    SettingsCurrencyChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = current.settings.copyWith(
      currency: event.currencyCode,
    );
    await _saveUserSettings(SaveUserSettingsParams(settings: updated));
  }
}
