# habits — CONTEXT

Local-first habit tracker with daily/weekly/custom frequency, min- or max-type targets, measurable (quantitative) habits, and server-side streak/score computation in the DAO.

## Key files

### Domain
- `entities/habit_entity.dart` — `HabitEntity`, `enum HabitFrequency { daily, weekly, custom }`, `enum HabitTargetType { min, max }`.
- `entities/habit_log_entity.dart` — `HabitLogEntity { id, habitId, loggedDate (ISO), value, createdAt, note? }` and `HabitStreakEntity { habitId, currentStreak, longestStreak, totalCompletions, updatedAt, lastCompletedDate? }`.
- `entities/habit_with_details.dart` — bundles `HabitEntity` + `recentLogs` (last 7 days, most recent first) + `streak` + `score` (0–100, frequency-aware).
- `helpers/completion_helpers.dart` — `isHabitCompleted(value, target, targetType)` and `completionProgress(...)` (null for max-type).
- `repositories/habits_repository.dart` — see surface below.
- `usecases/` — `GetHabitsWithDetails`, `WatchHabitsWithDetails`, `CreateHabit`, `ToggleHabitLog`, `LogHabitValue`, `DeleteHabitLog`, `DeleteHabit`.

### Data
- `datasources/habits_local_data_source.dart` — delegates to `HabitsDao`.
- `mappers/habit_mapper.dart` — Drift ↔ entity extensions.
- `repositories/habits_repository_impl.dart` — `@LazySingleton(as: HabitsRepository)`.

### Presentation
- `bloc/habits_bloc.dart` — main list bloc (optimistic toggles, resync).
- `bloc/habit_form_bloc.dart` — create/edit form (form state, not sealed union).
- `pages/habits_page.dart`, `habit_create_edit_page.dart`, `habit_detail_page.dart`, `habit_stats_page.dart`.
- `utils/habit_icon_resolver.dart` — `resolveHabitIcon(iconName)` (Material icon name string → `IconData`).
- `widgets/day_indicator.dart`, `habit_card.dart`, `measurable_log_sheet.dart` (`MeasurableLogResult { delete, value }`).

## Public surface — `HabitsRepository`
- `getHabitsWithDetails(userId) → List<HabitWithDetails>`
- `watchHabitsWithDetails(userId) → Stream<List<HabitWithDetails>>`
- `createHabit(HabitEntity) → int`
- `toggleHabitLog({habitId, date})`
- `logHabitValue({habitId, date, value})`
- `deleteHabitLog({habitId, date})`
- `deleteHabit({habitId})`

## State — `HabitsState` (sealed)
`initial | loading | loaded(habits) | error(failure)`

## Events — `HabitsEvent` (sealed)
`loadRequested(userId) | refreshRequested | toggleLog | logValue | deleteLog | deleteHabit`

## Form state — `HabitFormState` (abstract)
Defaults: name='', desc='', icon='check_circle', color='#4CAF50', freq=daily, days=[1..7], targetValue=1.0, targetType=min, unit='', reminderEnabled=false, reminderTime='08:00', isSubmitting=false, isSuccess=false.

## Gotchas
- `HabitsBloc` applies **optimistic** updates then calls `_refreshHabits(emit)` regardless of success/failure to pick up DAO-recomputed streaks/scores. Placeholder log IDs of `-1` are used during the optimistic phase.
- The watch stream observes only the `habits` table — log changes don't flip it. That's why mutations trigger a manual `_getHabitsWithDetails` refresh.
- Three-state toggle cycle on `toggleLog`: `no log → value=1.0 → value=0.0 → no log`.
- `frequencyDays` is stored as a JSON string in Drift (e.g. `'[1,3,5]'`), mapped to `List<int>` in entity. `weekly` + `frequencyDays.contains(weekday)` determines today-eligible habits; `daily`/`custom` check `frequencyDays`.
- Dashboard filters today's habits with `frequencyType != weekly && frequencyDays.contains(todayWeekday)` (see `DashboardPage`).
- **Non-BlocSelector** risk: the habits list page must use the parent-IDs / child-BlocSelector pattern (see `BlocSelector Mandate` in CLAUDE.md). Don't wrap the whole list in one `BlocBuilder`.
