# Create a New Use Case

You are adding a new use case to an existing feature in the Track app. Before generating code, ask the user these questions using `AskUserQuestion`:

## Step 1: Gather Requirements

1. **Feature name** — which feature? (auth, habits, home, insights, money, settings)
2. **Use case name** — VerbNoun format (e.g., `CreateTransaction`, `GetAccountBalance`, `WatchBudgetProgress`)
3. **Return type** — what does it return on success? (e.g., `Unit`, `int`, `TransactionEntity`, `List<AccountEntity>`)
4. **Params** — options:
   - `NoParams` — no parameters needed
   - Single entity (e.g., `TransactionEntity`) — pass entity directly
   - Custom params — describe the fields (e.g., "accountId: int, startDate: DateTime, endDate: DateTime")
5. **Async type** — `Future` (UseCase) or `Stream` (StreamUseCase)?
6. **Does the repository already have the method?** — Yes (just wire it) or No (add it)

## Step 2: Generate Files

### Use case file: `lib/features/[feature]/domain/usecases/[verb]_[noun].dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/[feature]/domain/repositories/[feature]_repository.dart';

@lazySingleton
class [VerbNoun] implements UseCase<[ReturnType], [ParamType]> {
  [VerbNoun](this._repository);

  final [Feature]Repository _repository;

  @override
  Future<Either<Failure, [ReturnType]>> call([ParamType] params) =>
      _repository.[methodName](/* extract params */);
}
```

**If custom params are needed**, add below the use case class:

```dart
class [VerbNoun]Params extends Equatable {
  const [VerbNoun]Params({required this.field1, required this.field2});

  final Type1 field1;
  final Type2 field2;

  @override
  List<Object?> get props => [field1, field2];
}
```

**If StreamUseCase**, use `StreamUseCase` instead of `UseCase` and return `Stream<Either<...>>`.

### If repository method doesn't exist yet

Add the method signature to `lib/features/[feature]/domain/repositories/[feature]_repository.dart`:

```dart
Future<Either<Failure, [ReturnType]>> [methodName]({/* params */});
```

Then add the implementation to the repository impl in `lib/features/[feature]/data/repositories/[feature]_repository_impl.dart`.

## Step 3: Run Codegen

```bash
make gen
make format
make analyze
```

## Reminders

- Use `@lazySingleton` (NOT `@injectable`) for use cases
- Import `Equatable` from `package:equatable/equatable.dart` for custom params
- Use `NoParams` from `package:track/core/usecases/usecase.dart` when no params needed
- The use case should be a thin wrapper — no business logic beyond calling the repository method
