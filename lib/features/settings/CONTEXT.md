# settings — CONTEXT

User preferences (currency, theme, reminders, onboarding, profile display). **Currently partial** — pages exist but no BLoC and no repository wired yet; reads/writes go straight through `SettingsDao`.

## Key files

### Domain
- `entities/user_settings_entity.dart` — `UserSettingsEntity { userId, currency (ISO-4217), themeMode, notificationsEnabled, dailyReminderEnabled, dailyReminderTime ('HH:mm'), firstDayOfWeek (1=Mon..7=Sun, ISO-8601), onboardingCompleted, displayName?, avatarUrl?, updatedAt }` + `enum AppThemeMode { light, dark, system }` (renamed from Flutter's `ThemeMode` to avoid import clashes).

### Data
- `mappers/user_settings_mapper.dart` — Drift ↔ entity for `user_settings` table.
- **No repository impl, no use cases, no BLoC yet.**

### Presentation
- `pages/settings_page.dart` — `@RoutePage()` plain `ListView`: profile card → Appearance / Notifications / Export Data / About tiles (onTap empty) → Sign Out (dispatches `AuthEvent.signOutRequested` on `AuthBloc`). Uses `_SettingsTile` private helper.
- `pages/profile_page.dart` — `@RoutePage()` profile screen.

## Public surface
None exposed. `user_settings` table is owned by `core/database/` (`SettingsDao`); `DatabaseSeeder._seedSettings` populates it in mock mode.

## Gotchas
- Use `AppThemeMode` (not Flutter's `ThemeMode`) in domain and data layers — the entity intentionally shadows it.
- `themeMode` is persisted as a string (`'light'`/`'dark'`/`'system'`) by the DAO mapper.
- `firstDayOfWeek` follows ISO-8601 (1=Mon). Date-formatting utilities elsewhere assume this; don't accidentally store 0-indexed.
- To wire real settings management:
  1. Create `domain/repositories/settings_repository.dart` (`Either<Failure, T>`) + impl, `@LazySingleton(as: ...)`.
  2. Add use cases (e.g. `GetUserSettings`, `WatchUserSettings`, `UpdateUserSettings`).
  3. Create `SettingsBloc` or a per-form bloc, follow BlocSelector mandate in the page.
- Sign-out currently dispatches on the globally-provided `AuthBloc` (from `TrackApp`) — no local provider needed.
