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
