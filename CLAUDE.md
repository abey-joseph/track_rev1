# CLAUDE.md — Project Guidelines for AI Assistants

## Architecture

- **State Management:** BLoC pattern with `flutter_bloc`, `freezed` for immutable state/events
- **DI:** `get_it` + `injectable` for dependency injection
- **Routing:** `auto_route` for navigation
- **Database:** Drift ORM with DAOs
- **Structure:** Feature-based (auth, habits, home, insights, money, settings) with data/domain/presentation layers

## BLoC Rebuild Rules (MANDATORY)

**Only the specific widget that needs to update should rebuild — never the entire page.**

This is a non-negotiable rule for all BLoC consumer widgets:

1. **Use `BlocSelector` for individual list items.** When a BLoC state contains a list (e.g., `List<HabitWithDetails>`), each list item widget must use `BlocSelector` to select only its own data by ID. The parent list widget should only select the list of IDs (not full objects) to drive the `ListView.builder`.

2. **Use `BlocSelector` with derived values for summary widgets.** When a widget displays computed/aggregated data (e.g., streak count, completion percentage), use `BlocSelector` to return only the derived values as a record. The widget only rebuilds when those specific values change.

3. **Use precise `buildWhen` / `listenWhen`.** When `BlocBuilder` or `BlocListener` is used, always provide `buildWhen`/`listenWhen` that compares only the relevant subset of state. Never compare the entire state when only a portion matters.

4. **Leverage freezed equality.** All entities are freezed, providing deep value equality. `BlocSelector` uses `==` to short-circuit rebuilds — this works correctly with freezed types out of the box.

### Example: Per-item selector pattern

```dart
// Parent: selects only IDs — rebuilds only on add/remove/reorder
BlocSelector<MyBloc, MyState, List<int>>(
  selector: (state) => state is MyLoaded
      ? state.items.map((i) => i.id).toList()
      : <int>[],
  builder: (context, ids) => ListView.builder(
    itemCount: ids.length,
    itemBuilder: (_, index) => _ItemCard(id: ids[index]),
  ),
)

// Child: selects only its own item — rebuilds only when this item changes
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

### Anti-patterns to avoid

- Wrapping an entire page body in a single `BlocBuilder` that rebuilds on any state change
- Using `buildWhen: (prev, curr) => prev.habits != curr.habits` on a list — this always returns true when any item changes since the list reference changes
- Passing full entity objects from a parent `BlocBuilder` down to list item widgets instead of letting each item select its own data

## Clean Architecture & Layer Separation (MANDATORY)

**Strict adherence to the three-layer architecture is non-negotiable. No business logic in the presentation layer, no UI concerns in the data/domain layers.**

1. **Presentation Layer (UI/BLoC):** Only handles UI state, navigation, and user interactions. All BLoCs and pages live here. No database queries, API calls, or business logic — delegate to the domain layer via use cases.

2. **Domain Layer (Business Logic):** Contains entities, repository interfaces, and use cases. This layer defines *what* the app can do, independent of implementation. Use cases orchestrate domain entities and repository calls. **No external dependencies** — domain must not import any packages except `freezed`, `equatable`, or other pure Dart libraries.

3. **Data Layer (Infrastructure):** Handles all external operations: database queries (Drift DAOs), API calls, local storage. Implements repository interfaces from the domain layer. DTOs/Models map external data to domain entities. Data layer imports domain but domain never imports data.

### Key Rules

- **No cross-feature imports:** Features (auth, habits, home, insights, money, settings) are isolated. Reusable utilities go in the `core` package. Never import from another feature's library.
- **Use repository pattern:** Data operations always go through repositories. Pages/BLoCs never call DAOs or API clients directly.
- **Pass entities, not DTOs:** Domain and presentation layers work with domain entities. DTOs stay in the data layer and are converted at the boundary.
- **Unidirectional dependency flow:** Presentation → Domain → Data. Never reverse this. Use dependency injection to invert control.

### Anti-patterns to avoid

- Calling database queries or API functions directly from BLoCs or pages
- Putting business logic (calculations, validation, transformations) in presentation widgets
- Importing from another feature's internal structure (e.g., importing `features/auth/data` from `features/habits`)
- Exposing data-layer types (DTOs, DAOs) in domain or presentation layers
- Repository implementations in the domain layer
