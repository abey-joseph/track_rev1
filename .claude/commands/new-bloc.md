# Create a New BLoC

You are adding a new BLoC to an existing feature in the Track app. Before generating code, ask the user these questions using `AskUserQuestion`:

## Step 1: Gather Requirements

1. **Feature name** — which existing feature does this BLoC belong to? (auth, habits, home, insights, money, settings)
2. **BLoC name** — the name for this BLoC (e.g., `habit_form`, `transaction_filter`, `account_detail`)
3. **State type** — ask with these options:
   - **Standard (sealed union):** For page/section states with `initial | loading | loaded | error` pattern. Uses `@freezed sealed class`.
   - **Form (single class):** For form state with many fields and `@Default()` values. Uses `@freezed abstract class`.
4. **Events needed** — list of events (e.g., "loadRequested, filterChanged, itemDeleted, submitted")
5. **Use cases** — which existing use cases does this BLoC need? (or "none yet — I'll wire them later")

## Step 2: Generate Files

Create 3 files in `lib/features/[feature]/presentation/bloc/`:

### Event file: `[bloc_name]_event.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[bloc_name]_event.freezed.dart';

@freezed
sealed class [BlocName]Event with _$[BlocName]Event {
  // One factory constructor per event from user input
  const factory [BlocName]Event.eventName({/* params */}) = [BlocName]EventName;
}
```

### State file: `[bloc_name]_state.dart`

**If standard (sealed union):**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';

part '[bloc_name]_state.freezed.dart';

@freezed
sealed class [BlocName]State with _$[BlocName]State {
  const factory [BlocName]State.initial() = [BlocName]Initial;
  const factory [BlocName]State.loading() = [BlocName]Loading;
  const factory [BlocName]State.loaded({required [DataType] data}) = [BlocName]Loaded;
  const factory [BlocName]State.error({required Failure failure}) = [BlocName]Error;
}
```

**If form (single class):**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[bloc_name]_state.freezed.dart';

@freezed
abstract class [BlocName]State with _$[BlocName]State {
  const factory [BlocName]State({
    @Default('') String fieldName,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _[BlocName]State;
}
```

### BLoC file: `[bloc_name]_bloc.dart`

```dart
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class [BlocName]Bloc extends Bloc<[BlocName]Event, [BlocName]State> {
  [BlocName]Bloc(/* use case injections */) : super(const [BlocName]State.initial()) {
    on<[EventType]>(_onEventName);
    // register all handlers
  }

  // One handler method per event
  Future<void> _onEventName([EventType] event, Emitter<[BlocName]State> emit) async {
    // implement
  }
}
```

## Step 3: Run Codegen

```bash
make gen
make format
make analyze
```

## Reminders

- Use `@injectable` (NOT `@lazySingleton`) for BLoCs
- Constructor inject use cases, not repositories
- Register all event handlers in the constructor body with `on<Event>(_handler)`
- For form BLoCs: use `state.copyWith(...)` to emit updated state
- For standard BLoCs: emit distinct state variants (loading, loaded, error)
- Include `part` directives for freezed generated files
