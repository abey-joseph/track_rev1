# home — CONTEXT

App shell (bottom-nav tabs + FAB) and the dashboard/today screen. Owns no BLoC, no domain, no data layer — it composes state from the `habits` and `money` feature BLoCs via `BlocProvider`s mounted at the shell.

## Key files
- `presentation/pages/app_shell_page.dart` — `@RoutePage() AppShellPage`. Wraps `AutoTabsScaffold` with 4 tabs (Today/Habits/Money/Insights). Mounts `HabitsBloc` and `MoneyBloc` via `MultiBlocProvider` and dispatches `loadRequested(userId)` from the current `AuthBloc` state. FAB varies per tab (add-habit on tab 1, add-transaction on 0 & 2, hidden on Insights). Listens to `AuthBloc.unauthenticated` to replace-all to `LoginRoute`.
- `presentation/pages/dashboard_page.dart` — `@RoutePage() DashboardPage`. Composes `StreakScoreCard` (`BlocSelector` returning a record), `TodayHabitsSection` (`BlocBuilder` with `buildWhen` that compares only today-eligible habits via `listEquals`), `SpendingSummaryCard`, `AiInsightCard`, `RecentActivityFeed`. Measurable habits open `MeasurableLogSheet` on toggle. Tab jumps use `AutoTabsRouter.of(context).setActiveIndex(...)`.
- `presentation/pages/home_page.dart` — legacy placeholder screen; **not wired into the router**. Safe to delete once confirmed unused.

### Widgets (`presentation/widgets/`)
- `streak_score_card.dart` — `StreakScoreCard(currentStreak, habitsCompleted, habitsTotal)`.
- `today_habits_section.dart` — exports `HabitItem`, `DayStatus`, `TodayHabitsSection(habits, onToggle(id), onSeeAll)`.
- `spending_summary_card.dart` — exports `CategorySpend { name, icon, amount }`, `SpendingSummaryCard(todaySpend, weekSpend, topCategories, dailySpends, onSeeAll)`. **Currently uses hard-coded demo data.**
- `ai_insight_card.dart` — `AiInsightCard(insightText, onTap)`. **Demo text only.**
- `recent_activity_feed.dart` — `ActivityItem { time, title, type, subtitle? }`, `enum ActivityType { habitCompletion, expense }`. **Currently uses hard-coded demo data.**

## Public surface
None — `home` exposes no repositories or use cases. All widgets and pages are internal UI.

## Gotchas
- Dashboard reads `HabitsBloc` / `MoneyBloc` via `context.read`/`BlocSelector`; these BLoCs are provided by `AppShellPage`, not by the dashboard. Any page moved out of the tab shell must provide them itself.
- `SpendingSummaryCard`, `AiInsightCard`, and `RecentActivityFeed` are still wired to hard-coded demo data inside `DashboardPage`. When these are connected to real data (money/insights/activity), update this file and `lib/features/money/CONTEXT.md` / `lib/features/insights/CONTEXT.md`.
- `_parseColor(hex)` in `dashboard_page.dart` is a private helper duplicated per page; if it appears a third time, hoist to `core/utils/`.
- `HomePage` is unreferenced (not in `app_router.dart`) — treat as dead code unless otherwise told.
