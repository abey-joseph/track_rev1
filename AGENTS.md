# AGENTS.md — Track

> Full architecture reference, templates, and decision log: see `PROJECT_BIBLE.md`

## Context Index (read lazily)

Each section below has a per-section `CONTEXT.md` with its purpose, key files, public surface (repo methods, use cases, BLoC events/state), and gotchas. **Do not read all of them up front.** Read only the ones relevant to the current task. Names and routes are already in the file paths — `find` / `grep` first, open a `CONTEXT.md` only when you need orientation for that section.

| Section | Path | Covers |
|---|---|---|
| core | `lib/core/CONTEXT.md` | Drift DB (schema v7), DI, router + auth guard, theme, failures/exceptions, usecase base, network, logger, widgets, env, constants |
| auth | `lib/features/auth/CONTEXT.md` | Firebase auth (email / Google / anon), `AuthRepository`, `AuthBloc`, splash + login |
| habits | `lib/features/habits/CONTEXT.md` | Habit entity + logs + streaks, `HabitsBloc` (optimistic), habit form, pages + widgets |
| home | `lib/features/home/CONTEXT.md` | `AppShellPage` (tabs + FAB), `DashboardPage`, dashboard widgets — no domain/data |
| insights | `lib/features/insights/CONTEXT.md` | Insight entity (currently skeleton pages only, no repo/bloc) |
| money | `lib/features/money/CONTEXT.md` | Transactions, accounts, categories, currencies, recurring, budgets; many sub-BLoCs |
| settings | `lib/features/settings/CONTEXT.md` | Settings entity + pages (no bloc/repo yet) |

### `CONTEXT.md` update rule (scoped)

Update a section's `CONTEXT.md` only when **any** of the following change in that section:

- **Public surface** — a repository method added/renamed/removed, a use case added/renamed/removed.
- **Public entity shape** — adding/removing fields on entities exported from `domain/`, adding/removing enum variants on public enums.
- **BLoC contract** — new event variants, new state variants, or a new BLoC file.
- **File layout** — new/removed page, new/removed top-level folder under the section, a file moves between `domain/`, `data/`, or `presentation/`.
- **Non-obvious behaviour** — a gotcha that a future contributor would benefit from knowing (concurrency, optimistic updates, schema migrations, cross-feature coupling).

Do **not** update `CONTEXT.md` for: widget internals, private helpers, bug fixes that don't change the surface, formatting, or import reorders. Be terse — each section targets ~150–400 tokens. If the bullet is obvious from file names, drop it.

When you add a **new top-level section** under `lib/features/`, create a `CONTEXT.md` in it and add a row to the table above in this file and in `CLAUDE.md`.

---

## Quick Reference

- **Architecture:** Clean Architecture (presentation → domain → data)
- **State:** BLoC (`flutter_bloc`) — never Cubit
- **DI:** `get_it` + `injectable`
- **Routing:** `auto_route`
- **Database:** Drift (SQLite) — local-first, source of truth
- **Models:** freezed everywhere (entities, DTOs, events, states, failures)
- **Error handling:** `Either<Failure, T>` from `fpdart`
- **Features:** auth, habits, home, insights, money, settings

---

## MUST

- Use `package:track/...` imports (never relative)
- Include `part` directives for all freezed/json_serializable files
- Use `Either<Failure, T>` for all repository return types
- Route all business logic through use cases — BLoCs call use cases, never repositories
- Use `@injectable` for BLoCs, `@lazySingleton` for repos/data sources/use cases
- Use `@RoutePage()` on every page widget
- Use `const` constructors wherever possible
- Keep domain layer free of external dependencies (no Firebase, no Drift imports)
- Mirror `lib/` structure in `test/`
- Separate DTOs and entities — even if fields are identical

## MUST NOT

- Use `Cubit` — always `Bloc` with events
- Call repositories directly from BLoCs or widgets
- Put business logic in widgets or BLoCs — it belongs in use cases
- Wrap entire pages in a single `BlocBuilder`
- Use relative imports
- Import across features (e.g., `features/auth/` from `features/habits/`)
- Expose Drift types or DTOs in domain/presentation layers
- Use `setState` for anything BLoC should manage
- Use `dynamic` types
- Use `.then()` chains — use `async/await`

---

## BlocSelector Mandate (NON-NEGOTIABLE)

**Only the specific widget that needs to update should rebuild — never the entire page.**

### Pattern: Parent selects IDs, child selects its own data

```dart
// Parent: rebuilds only on add/remove/reorder
BlocSelector<MyBloc, MyState, List<int>>(
  selector: (state) => state is MyLoaded
      ? state.items.map((i) => i.id).toList()
      : <int>[],
  builder: (context, ids) => ListView.builder(
    itemCount: ids.length,
    itemBuilder: (_, index) => _ItemCard(id: ids[index]),
  ),
)

// Child: rebuilds only when THIS item changes
BlocSelector<MyBloc, MyState, MyItem?>(
  selector: (state) => state is MyLoaded
      ? state.items.where((i) => i.id == id).firstOrNull
      : null,
  builder: (context, item) {
    if (item == null) return const SizedBox.shrink();
    return ItemWidget(item: item);
  },
)
```

### Rules

1. **List items** → each item uses `BlocSelector` selecting by its own ID
2. **Summary/aggregate widgets** → `BlocSelector` returning a record of derived values
3. **`BlocBuilder`/`BlocListener`** → always provide `buildWhen`/`listenWhen` comparing only the relevant subset
4. **Freezed equality** makes `BlocSelector` work out of the box — leverage it

### Anti-patterns

- Single `BlocBuilder` wrapping entire page body
- `buildWhen: (prev, curr) => prev.items != curr.items` on lists (always true — list reference changes)
- Passing full entities from parent `BlocBuilder` to list item children

---

## Naming Conventions

| Type | File suffix | Class pattern | Annotation |
|---|---|---|---|
| Entity | `_entity.dart` | `[Name]Entity` | `@freezed abstract class` |
| DTO | `_dto.dart` | `[Name]Dto` | `@freezed` + `@JsonSerializable` |
| Repository (abstract) | `_repository.dart` | `[Name]Repository` | — |
| Repository (impl) | `_repository_impl.dart` | `[Name]RepositoryImpl` | `@LazySingleton(as:)` |
| Use Case | `verb_noun.dart` | `VerbNoun` | `@lazySingleton` |
| Data Source (abstract) | `_data_source.dart` | `[Name]DataSource` | — |
| Data Source (impl) | `_data_source.dart` | `[Name]DataSourceImpl` | `@LazySingleton(as:)` |
| Mapper | `_mapper.dart` | Extensions | — |
| BLoC | `_bloc.dart` | `[Name]Bloc` | `@injectable` |
| Event | `_event.dart` | `[Name]Event` | `@freezed sealed class` |
| State (union) | `_state.dart` | `[Name]State` | `@freezed sealed class` |
| State (form) | `_state.dart` | `[Name]State` | `@freezed abstract class` + `@Default` |
| Page | `_page.dart` | `[Name]Page` | `@RoutePage()` |
| Failure | in `failures.dart` | `[Type]Failure` | `@freezed sealed class` |
| Params | in use case file | `[Name]Params` | extends `Equatable` |

---

## Codegen Annotations Cheat Sheet

```
@freezed abstract class   → Entities, form states (with @Default values)
@freezed sealed class     → Events, union states (initial/loading/loaded/error), Failures
@injectable               → BLoCs (fresh instance per screen)
@lazySingleton            → Use cases, data sources (impl), services
@LazySingleton(as: X)     → Repository impls, data source impls (bound to abstract)
@RoutePage()              → Every page widget
```

---

## After Making Changes

1. **If you created/modified freezed or auto_route files** → `make gen`
2. **Format** → `make format`
3. **Analyze** → `make analyze`
