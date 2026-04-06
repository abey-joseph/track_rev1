# Generate BLoC Tests

You are generating tests for a BLoC in the Track app. Before generating code, determine which BLoC to test:

## Step 1: Identify the BLoC

Ask the user using `AskUserQuestion`:

1. **Which BLoC to test?** — feature name + bloc name (e.g., "habits/habits_bloc", "money/transaction_form_bloc")
   - Or if already clear from conversation context, skip this question

## Step 2: Read the BLoC

Read these files to understand the BLoC:
- The BLoC file (`_bloc.dart`) — to find all event handlers and injected dependencies
- The event file (`_event.dart`) — to find all events and their parameters
- The state file (`_state.dart`) — to find all states and their fields
- The use case files — to understand return types and params

## Step 3: Generate Test File

Create: `test/features/[feature]/presentation/bloc/[bloc_name]_bloc_test.dart`

### Structure:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:track/core/error/failures.dart';
// import bloc, events, states, use cases, entities

// === Mock classes ===
class Mock[UseCase] extends Mock implements [UseCase] {}
// one per injected dependency

void main() {
  // === Declarations ===
  late [BlocName]Bloc bloc;
  late Mock[UseCase] mock[UseCase];
  // one per dependency

  // === Test data ===
  // Define const test entities/values used across tests

  // === Setup ===
  setUpAll(() {
    // Register fallback values for custom param types
    registerFallbackValue([ParamType](...));
  });

  setUp(() {
    mock[UseCase] = Mock[UseCase]();
    // initialize all mocks
    bloc = [BlocName]Bloc(mock[UseCase], ...);
  });

  tearDown(() => bloc.close());

  // === Tests ===

  test('initial state is [BlocName]Initial', () {
    expect(bloc.state, equals(const [BlocName]State.initial()));
  });

  // --- Group by event ---
  group('[EventName]', () {
    blocTest<[BlocName]Bloc, [BlocName]State>(
      'emits [loading, loaded] when [event] succeeds',
      build: () {
        when(() => mock[UseCase](any()))
            .thenAnswer((_) async => Right(testData));
        return bloc;
      },
      act: (bloc) => bloc.add(const [BlocName]Event.eventName(/* params */)),
      expect: () => [
        const [BlocName]State.loading(),
        [BlocName]State.loaded(data: testData),
      ],
    );

    blocTest<[BlocName]Bloc, [BlocName]State>(
      'emits [loading, error] when [event] fails',
      build: () {
        when(() => mock[UseCase](any()))
            .thenAnswer((_) async => const Left(
                  Failure.server(message: 'Test error'),
                ));
        return bloc;
      },
      act: (bloc) => bloc.add(const [BlocName]Event.eventName(/* params */)),
      expect: () => [
        const [BlocName]State.loading(),
        const [BlocName]State.error(
          failure: Failure.server(message: 'Test error'),
        ),
      ],
    );
  });

  // Repeat group for each event...
}
```

### For Form BLoCs (non-sealed state):

```dart
blocTest<[BlocName]Bloc, [BlocName]State>(
  'updates field when [fieldChanged] event is added',
  build: () => bloc,
  act: (bloc) => bloc.add(const [BlocName]Event.fieldChanged(field: 'value')),
  expect: () => [
    const [BlocName]State(field: 'value'),
  ],
);

blocTest<[BlocName]Bloc, [BlocName]State>(
  'emits [submitting, success] when submitted succeeds',
  build: () {
    when(() => mock[UseCase](any()))
        .thenAnswer((_) async => const Right(unit));
    return bloc;
  },
  seed: () => const [BlocName]State(name: 'Test'),
  act: (bloc) => bloc.add(const [BlocName]Event.submitted(/* params */)),
  expect: () => [
    // isSubmitting: true
    // isSuccess: true
  ],
);
```

## Step 4: Run Tests

```bash
make test-feature FEATURE=[feature]
```

## Reminders

- Use `mocktail` (NOT mockito)
- Use `bloc_test` for all BLoC tests
- Create one `group()` per event type
- Each group has at minimum: success case + failure case
- Use `seed:` for tests that need pre-existing state
- Use `any()` for matcher in `when()` calls
- Register fallback values in `setUpAll` for all custom param types
- Use `const` for test expectations where possible
- Create the test directory structure to mirror lib: `test/features/[feature]/presentation/bloc/`
