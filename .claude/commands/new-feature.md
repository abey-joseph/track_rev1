# Scaffold a New Feature Module

You are scaffolding a new feature for the Track app following Clean Architecture. Before generating any code, ask the user these questions using `AskUserQuestion`:

## Step 1: Gather Requirements

Ask all of these in one AskUserQuestion call:

1. **Feature name** (snake_case, e.g., `goals`, `journal`, `workouts`)
2. **Main entity fields** — ask the user to describe the entity with its fields and types (e.g., "id: int, name: String, amount: double, category: String, createdAt: DateTime")
3. **Use cases needed** — which operations? Options: Create, Read (get single), List (get all), Watch (stream), Update, Delete, plus any custom ones
4. **Data source type** — Local only (Drift) or Local + Remote (Drift + API)

## Step 2: Generate Files

Generate ALL files following the exact patterns from the habits feature. Use `package:track/...` imports everywhere.

### File creation order (respect dependency flow):

**Domain layer first (no dependencies):**

1. `lib/features/[name]/domain/entities/[name]_entity.dart`
   - `@freezed abstract class [Name]Entity with _$[Name]Entity`
   - `part '[name]_entity.freezed.dart';`
   - All fields from user input

2. `lib/features/[name]/domain/repositories/[name]_repository.dart`
   - Abstract class with `Future<Either<Failure, T>>` methods
   - One method per use case the user requested

3. `lib/features/[name]/domain/usecases/[verb]_[name].dart` (one per use case)
   - `@lazySingleton`
   - `implements UseCase<ReturnType, ParamType>` or `StreamUseCase<ReturnType, ParamType>`
   - Constructor injects the repository
   - Use `NoParams` for parameterless use cases
   - Use custom `[Name]Params extends Equatable` for multi-param use cases

**Data layer (depends on domain):**

4. `lib/features/[name]/data/mappers/[name]_mapper.dart`
   - Extension on Drift row type: `toEntity()` method
   - Extension on Entity: `toCompanion()` method returning `[Name]Companion`
   - Use `Value.absent()` for auto-increment IDs (when `id == 0`)
   - Parse enums via switch expressions

5. `lib/features/[name]/data/datasources/[name]_local_data_source.dart`
   - Abstract class (no annotation) with all data operations
   - Implementation class with `@LazySingleton(as: [Name]LocalDataSource)`
   - Constructor injects `AppDatabase`
   - All methods wrapped in try-catch, throwing `CacheException`
   - Delegates to DAO methods

6. `lib/features/[name]/data/repositories/[name]_repository_impl.dart`
   - `@LazySingleton(as: [Name]Repository)`
   - Constructor injects data source(s)
   - Catches exceptions → returns `Left(Failure.cache(...))`  or `Left(Failure.server(...))`
   - Returns `Right(result.toEntity())` on success

**Presentation layer (depends on domain):**

7. `lib/features/[name]/presentation/bloc/[name]_event.dart`
   - `@freezed sealed class [Name]Event with _$[Name]Event`
   - One factory constructor per user action

8. `lib/features/[name]/presentation/bloc/[name]_state.dart`
   - `@freezed sealed class [Name]State with _$[Name]State`
   - Standard: `initial`, `loading`, `loaded`, `error`

9. `lib/features/[name]/presentation/bloc/[name]_bloc.dart`
   - `@injectable`
   - Constructor injects all use cases
   - Register handlers with `on<EventType>(_handler)` in constructor
   - Each handler: emit loading → call use case → fold result → emit loaded/error

10. `lib/features/[name]/presentation/pages/[name]_page.dart`
    - `@RoutePage()` annotation
    - Stateless wrapper providing `BlocProvider` + `_[Name]View` internal widget
    - Use `BlocSelector` for list items (NOT BlocBuilder wrapping entire page)
    - Pattern match state with `.when()`

**Wiring:**

11. Add route to `lib/core/router/app_router.dart`:
    - `AutoRoute(page: [Name]Route.page)`

## Step 3: Run Codegen & Verify

```bash
make gen
make format
make analyze
```

Fix any analysis issues before finishing.

## Important Reminders

- **DO NOT** create a Drift table or DAO — the user will handle database schema separately
- **DO** create the mapper assuming the Drift table already exists (use the entity field names)
- **DO** use `package:track/...` imports everywhere
- **DO** include `part` directives for all freezed files
- **DO** follow the BlocSelector mandate for any list rendering in the page
