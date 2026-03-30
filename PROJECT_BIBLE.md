# PROJECT BIBLE — Track

## Last Updated: 2026-03-30

---

## 1. Architecture Overview

### Pattern: Pure Clean Architecture

```
┌─────────────────────────────────┐
│        PRESENTATION             │
│  (Pages, Widgets, BLoCs)        │
│                                 │
│  Depends on: Domain             │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│          DOMAIN                 │
│  (Entities, Use Cases,          │
│   Repository Contracts)         │
│                                 │
│  Depends on: Nothing            │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│           DATA                  │
│  (DTOs, Data Sources,           │
│   Repository Implementations)   │
│                                 │
│  Depends on: Domain             │
└─────────────────────────────────┘
```

### Data Flow

```
User Action → BLoC Event → BLoC → Use Case → Repository (abstract) → Repository Impl → Data Source → External Service (Firebase/Drift/API)
                                                                                                            │
Response ← BLoC State ← BLoC ← Either<Failure, T> ← Repository Impl ← Data Source ← External Service ─────┘
```

### Folder Structure

```
lib/
├── main.dart                            # App entry point
├── injection.dart                       # injectable config
│
├── core/
│   ├── constants/                       # App-wide constants
│   ├── database/                        # Drift database root
│   ├── error/                           # Exceptions & Failures
│   ├── extensions/                      # Dart/Flutter extensions
│   ├── network/                         # Dio setup, network info
│   ├── router/                          # auto_route config + guards
│   ├── theme/                           # Material 3 theme
│   ├── usecases/                        # Base UseCase class
│   ├── utils/                           # Logger, validators, helpers
│   └── widgets/                         # Shared reusable widgets
│
├── features/
│   └── [feature_name]/
│       ├── domain/
│       │   ├── entities/                # Business objects (freezed)
│       │   ├── repositories/            # Abstract contracts
│       │   └── usecases/                # Business logic
│       ├── data/
│       │   ├── models/                  # DTOs (freezed + json_serializable)
│       │   ├── mappers/                 # DTO ↔ Entity conversion
│       │   ├── datasources/             # Remote & local data sources
│       │   └── repositories/            # Repository implementations
│       └── presentation/
│           ├── bloc/                    # BLoC + Events + States
│           ├── pages/                   # Full screen pages
│           └── widgets/                 # Feature-specific widgets
│
└── gen/                                 # flutter_gen generated assets
```

### Feature Structure Template

Every new feature MUST contain these files at minimum:

```
features/[name]/
├── domain/
│   ├── entities/[name]_entity.dart
│   ├── repositories/[name]_repository.dart
│   └── usecases/[primary_action].dart
├── data/
│   ├── models/[name]_dto.dart
│   ├── mappers/[name]_mapper.dart
│   ├── datasources/[name]_remote_data_source.dart
│   └── repositories/[name]_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── [name]_bloc.dart
    │   ├── [name]_event.dart
    │   └── [name]_state.dart
    └── pages/[name]_page.dart
```

---

## 2. Naming Conventions

### Files (snake_case)

| Type | Suffix | Example |
|---|---|---|
| Page (full screen) | `_page.dart` | `login_page.dart` |
| Widget | `_widget.dart` or descriptive | `social_sign_in_button.dart` |
| BLoC | `_bloc.dart` | `auth_bloc.dart` |
| Event | `_event.dart` | `auth_event.dart` |
| State | `_state.dart` | `auth_state.dart` |
| Entity | `_entity.dart` | `user_entity.dart` |
| DTO/Model | `_dto.dart` | `user_dto.dart` |
| Repository (abstract) | `_repository.dart` | `auth_repository.dart` |
| Repository (impl) | `_repository_impl.dart` | `auth_repository_impl.dart` |
| Data Source | `_data_source.dart` | `auth_remote_data_source.dart` |
| Use Case | descriptive verb | `sign_in_with_email.dart` |
| Mapper | `_mapper.dart` | `user_mapper.dart` |
| Test | `_test.dart` | `auth_bloc_test.dart` |

### Classes (PascalCase)

| Type | Pattern | Example |
|---|---|---|
| Page | `[Name]Page` | `LoginPage` |
| BLoC | `[Name]Bloc` | `AuthBloc` |
| Event | `[Name]Event` (sealed) | `AuthEvent` |
| State | `[Name]State` (sealed) | `AuthState` |
| Entity | `[Name]Entity` | `UserEntity` |
| DTO | `[Name]Dto` | `UserDto` |
| Repository (abstract) | `[Name]Repository` | `AuthRepository` |
| Repository (impl) | `[Name]RepositoryImpl` | `AuthRepositoryImpl` |
| Data Source (abstract) | `[Name]DataSource` | `AuthRemoteDataSource` |
| Data Source (impl) | `[Name]DataSourceImpl` | `AuthRemoteDataSourceImpl` |
| Use Case | `VerbNoun` | `SignInWithEmail` |
| Failure | `[Type]Failure` | `ServerFailure` |

### Variables & Constants

- Variables: `camelCase` — `final userName = 'John';`
- Private: `_camelCase` — `final _repository = AuthRepository();`
- Constants: `camelCase` — `static const maxRetries = 3;`
- Enums: `PascalCase` name, `camelCase` values — `enum AuthStatus { authenticated, unauthenticated }`

---

## 3. State Management Rules

### Solution: BLoC (flutter_bloc)

**Why BLoC**: Predictable event-driven pattern. Events create an audit trail. Excellent testability with `bloc_test`. Clear separation of UI and business logic. Extremely well-documented and AI-friendly.

### Creating a New BLoC (Step-by-Step)

1. Create `[name]_event.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[name]_event.freezed.dart';

@freezed
sealed class [Name]Event with _$[Name]Event {
  const factory [Name]Event.started() = [Name]Started;
  const factory [Name]Event.dataLoaded() = [Name]DataLoaded;
  // Add more events as needed
}
```

2. Create `[name]_state.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[name]_state.freezed.dart';

@freezed
sealed class [Name]State with _$[Name]State {
  const factory [Name]State.initial() = [Name]Initial;
  const factory [Name]State.loading() = [Name]Loading;
  const factory [Name]State.loaded({required [DataType] data}) = [Name]Loaded;
  const factory [Name]State.error({required Failure failure}) = [Name]Error;
}
```

3. Create `[name]_bloc.dart`:
```dart
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class [Name]Bloc extends Bloc<[Name]Event, [Name]State> {
  [Name]Bloc(this._useCase) : super(const [Name]State.initial()) {
    on<[Name]Started>(_onStarted);
  }

  final [UseCaseName] _useCase;

  Future<void> _onStarted(
    [Name]Started event,
    Emitter<[Name]State> emit,
  ) async {
    emit(const [Name]State.loading());
    final result = await _useCase(params);
    result.fold(
      (failure) => emit([Name]State.error(failure: failure)),
      (data) => emit([Name]State.loaded(data: data)),
    );
  }
}
```

4. Run `make gen` to generate freezed files.

5. Register BLoC via `@injectable` annotation (injectable handles it automatically).

6. Provide BLoC in the widget tree:
```dart
BlocProvider(
  create: (_) => getIt<[Name]Bloc>()..add(const [Name]Event.started()),
  child: const [Name]Page(),
)
```

### State Naming Format

- Always use freezed sealed classes
- Factory constructors: `const factory [Name]State.[stateName](...) = [StateName];`
- Standard states: `initial`, `loading`, `loaded`, `error`
- Pattern match with `.when()` or `.map()`

### Where State Lives

- BLoC files: `lib/features/[name]/presentation/bloc/`
- Always 3 files: `_bloc.dart`, `_event.dart`, `_state.dart`
- Never mix BLoC with UI code

### Anti-Patterns to AVOID

- **NEVER** call use cases directly from widgets — always go through BLoC
- **NEVER** use Cubit — we use Bloc with events for everything
- **NEVER** put business logic in widgets or BLoC — it belongs in use cases
- **NEVER** emit states outside of event handlers
- **NEVER** mix state management approaches (no Provider, no Riverpod alongside BLoC)
- **NEVER** store derived data in state — compute it in the widget

---

## 4. Navigation Rules

### Router: auto_route (codegen)

### Router Setup

The router is configured in `lib/core/router/app_router.dart` with `@AutoRouterConfig`. It is registered as a `@lazySingleton` in DI.

### Adding a New Route (Step-by-Step)

1. Create the page with `@RoutePage()` annotation:
```dart
@RoutePage()
class [Name]Page extends StatelessWidget {
  const [Name]Page({super.key});
  // ...
}
```

2. Add the route to `app_router.dart`:
```dart
@override
List<AutoRoute> get routes => [
  // ... existing routes
  AutoRoute(page: [Name]Route.page),
];
```

3. Run `make gen` to regenerate `app_router.gr.dart`.

4. Navigate to the route:
```dart
context.router.push(const [Name]Route());
// or with parameters:
context.router.push([Name]Route(id: someId));
```

### Parameter Passing

- Path params for IDs: `AutoRoute(page: DetailRoute.page, path: '/detail/:id')`
- Query params: annotate with `@queryParam`
- Complex objects: use typed extras or pass via constructor

### Auth Guard Pattern

Routes that require authentication use the `AuthGuard`:
```dart
AutoRoute(
  page: [Name]Route.page,
  guards: [_authGuard],
),
```

### Modal/Sheet Routing

```dart
CustomRoute(
  page: [Name]Route.page,
  fullscreenDialog: true,  // for modals
  transitionsBuilder: TransitionsBuilders.slideBottom,  // for bottom sheets
)
```

---

## 5. Data Layer Rules

### Repository Contract Pattern

```dart
// lib/features/[name]/domain/repositories/[name]_repository.dart
abstract class [Name]Repository {
  Future<Either<Failure, [Entity]>> get[Entity]({required String id});
  Future<Either<Failure, List<[Entity]>>> getAll[Entity]s();
  Future<Either<Failure, Unit>> create[Entity]([Entity] entity);
  Future<Either<Failure, Unit>> update[Entity]([Entity] entity);
  Future<Either<Failure, Unit>> delete[Entity]({required String id});
}
```

### Model/DTO Creation Pattern

```dart
// lib/features/[name]/data/models/[name]_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[name]_dto.freezed.dart';
part '[name]_dto.g.dart';

@freezed
class [Name]Dto with _$[Name]Dto {
  const factory [Name]Dto({
    required String id,
    required String name,
    // ... fields
  }) = _[Name]Dto;

  factory [Name]Dto.fromJson(Map<String, dynamic> json) =>
      _$[Name]DtoFromJson(json);
}
```

### Entity Creation Pattern

```dart
// lib/features/[name]/domain/entities/[name]_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[name]_entity.freezed.dart';

@freezed
class [Name]Entity with _$[Name]Entity {
  const factory [Name]Entity({
    required String id,
    required String name,
    // ... fields
  }) = _[Name]Entity;
}
```

### Mapper Pattern

```dart
// lib/features/[name]/data/mappers/[name]_mapper.dart
extension [Name]DtoToEntity on [Name]Dto {
  [Name]Entity toEntity() => [Name]Entity(
    id: id,
    name: name,
  );
}

extension [Name]EntityToDto on [Name]Entity {
  [Name]Dto toDto() => [Name]Dto(
    id: id,
    name: name,
  );
}
```

### API Call Pattern (Data Source)

```dart
// lib/features/[name]/data/datasources/[name]_remote_data_source.dart
abstract class [Name]RemoteDataSource {
  Future<[Name]Dto> get[Name]({required String id});
  Future<List<[Name]Dto>> getAll[Name]s();
}

@LazySingleton(as: [Name]RemoteDataSource)
class [Name]RemoteDataSourceImpl implements [Name]RemoteDataSource {
  [Name]RemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<[Name]Dto> get[Name]({required String id}) async {
    try {
      final response = await _dio.get('/[name]/$id');
      return [Name]Dto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch [name]',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
```

### Repository Implementation Pattern

```dart
// lib/features/[name]/data/repositories/[name]_repository_impl.dart
@LazySingleton(as: [Name]Repository)
class [Name]RepositoryImpl implements [Name]Repository {
  [Name]RepositoryImpl(this._remoteDataSource, this._localDataSource);

  final [Name]RemoteDataSource _remoteDataSource;
  final [Name]LocalDataSource _localDataSource;

  @override
  Future<Either<Failure, [Entity]>> get[Entity]({required String id}) async {
    try {
      final dto = await _remoteDataSource.get[Name](id: id);
      return Right(dto.toEntity());
    } on ServerException catch (e) {
      return Left(Failure.server(message: e.message, code: e.statusCode));
    } on CacheException catch (e) {
      return Left(Failure.cache(message: e.message));
    } catch (e) {
      return Left(Failure.unexpected(message: e.toString()));
    }
  }
}
```

### Error Handling in Data Layer

- Data sources THROW exceptions (`ServerException`, `CacheException`, `NetworkException`)
- Repository implementations CATCH exceptions and map them to `Failure` types
- Repositories return `Either<Failure, T>` — NEVER throw exceptions
- Use cases pass through the Either from repositories

### Offline-First Flow

```
User Action
    │
    ▼
BLoC → Use Case → Repository
                      │
                      ├─── Read from Drift (local first)
                      │         │
                      │         ├── Cache hit → Return data
                      │         └── Cache miss → Fetch remote
                      │
                      ├─── Write to Drift (always)
                      │
                      └─── Sync to remote (when online)
```

### Cache Strategy

- **Source of truth**: Drift (SQLite)
- **Remote sync**: Firebase for auth/push only (not primary data store)
- **Read**: Local first, remote fallback
- **Write**: Write locally immediately, sync to remote when connected
- **Conflict resolution**: Last-write-wins with timestamp comparison

---

## 6. Error Handling Rules

### Error Type Hierarchy

```dart
// Exceptions (thrown in data layer)
class ServerException implements Exception {
  final String message;
  final int? statusCode;
}

class CacheException implements Exception {
  final String message;
}

class NetworkException implements Exception {
  final String message;
}

// Failures (returned via Either in domain/presentation)
@freezed
sealed class Failure with _$Failure {
  const factory Failure.server({required String message, int? code}) = ServerFailure;
  const factory Failure.cache({required String message}) = CacheFailure;
  const factory Failure.network({required String message}) = NetworkFailure;
  const factory Failure.auth({required String message, String? code}) = AuthFailure;
  const factory Failure.unexpected({required String message}) = UnexpectedFailure;
}
```

### Error Propagation Between Layers

```
DATA LAYER          →    DOMAIN LAYER    →    PRESENTATION LAYER
Throws exceptions   →    Returns Either  →    Pattern matches state
ServerException     →    Left(Failure)   →    AuthState.error(failure)
CacheException      →    Left(Failure)   →    Show SnackBar / Error widget
```

### User-Facing Error Display

- **Transient errors** (network, timeout): SnackBar with retry action
- **Page-level errors** (failed to load data): `AppErrorWidget` with retry button
- **Auth errors** (wrong password): Inline form error or SnackBar
- **Fatal errors** (database corruption): Full error page with contact support

### Logging

- Use `Talker` for all logging
- Log levels: `debug` (dev only), `info` (state changes), `warning` (degraded), `error` (failures)
- Talker Dio interceptor logs all HTTP requests/responses automatically
- Talker BLoC observer logs all BLoC events/state transitions
- Non-fatal errors → log with `talker.error()` + send to Crashlytics
- Fatal errors → `FlutterError.onError` + `PlatformDispatcher.instance.onError` → Crashlytics

---

## 7. Dependency Injection Rules

### Solution: get_it + injectable (codegen)

### Registering a New Dependency (Step-by-Step)

1. **For your own classes**: Add the appropriate annotation:
   - `@injectable` — for classes created fresh each time (BLoCs)
   - `@lazySingleton` — for singletons created on first access (repositories, data sources, use cases)
   - `@singleton` — for singletons created eagerly at startup

2. **For abstract → implementation bindings**:
```dart
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository { ... }
```

3. **For third-party classes** (Dio, Talker, etc.): Use a `@module` abstract class:
```dart
@module
abstract class [Name]Module {
  @lazySingleton
  SomeThirdPartyClass get instance => SomeThirdPartyClass();
}
```

4. Run `make gen` to regenerate `injection.config.dart`.

### Scoping Rules

- **Global singletons** (`@lazySingleton`): Services, repositories, data sources, use cases, network clients
- **Per-instance** (`@injectable`): BLoCs (each screen gets its own instance)
- **Feature-scoped**: Achieved via BlocProvider in the widget tree, not DI scoping

### Environment Overrides

```dart
// Register different implementations per environment
@dev
@LazySingleton(as: ApiClient)
class DevApiClient implements ApiClient { ... }

@prod
@LazySingleton(as: ApiClient)
class ProdApiClient implements ApiClient { ... }
```

Environments are set in `main.dart` via `--dart-define=ENV=dev|prod`.

---

## 8. UI Rules

### Widget Composition Pattern

```dart
@RoutePage()
class [Name]Page extends StatelessWidget {
  const [Name]Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<[Name]Bloc>()..add(const [Name]Event.started()),
      child: const _[Name]View(),
    );
  }
}

class _[Name]View extends StatelessWidget {
  const _[Name]View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[Name]')),
      body: BlocBuilder<[Name]Bloc, [Name]State>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const AppLoadingIndicator(),
            loaded: (data) => _buildContent(context, data),
            error: (failure) => AppErrorWidget(
              message: failure.message,
              onRetry: () => context.read<[Name]Bloc>().add(
                const [Name]Event.started(),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### When to Extract a Widget

- When a widget subtree is **reused** in 2+ places
- When a build method exceeds **~100 lines**
- When a widget has **its own state** (StatefulWidget)
- Extract to the **same feature's widgets/** folder if feature-specific
- Extract to **core/widgets/** if shared across features

### Theme Access Pattern

```dart
// Use context extensions (from core/extensions/context_extensions.dart)
final theme = context.theme;
final colors = context.colorScheme;
final text = context.textTheme;

// Example usage
Text('Hello', style: context.textTheme.headlineMedium);
Container(color: context.colorScheme.primary);
```

### Responsive Breakpoints

```dart
// Phone: < 600dp width
// Tablet: >= 600dp width
final isTablet = context.screenWidth >= 600;

// Use LayoutBuilder for widget-level responsiveness
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= 600) {
      return _buildTabletLayout();
    }
    return _buildPhoneLayout();
  },
)
```

### Asset Usage Pattern

```dart
// Use flutter_gen type-safe references
// Images: Assets.images.[name]
// SVGs: Assets.icons.[name].svg(width: 24, height: 24)
```

---

## 9. Testing Rules

### What MUST Be Tested

- All use cases (input → output via Either)
- All repository implementations (exception → Failure mapping)
- All BLoC event → state flows (emit sequences)
- Complex utility functions / validators

### What CAN Be Skipped (for now)

- Simple widget rendering (no complex logic)
- Mapper extensions (trivial field mapping)
- Theme/styling code
- Generated code (freezed, json_serializable, auto_route)

### Test File Creation Checklist

1. Create test file mirroring lib path: `test/features/[name]/[layer]/[file]_test.dart`
2. Import `package:flutter_test/flutter_test.dart` and `package:mocktail/mocktail.dart`
3. Create mock classes at top of file
4. Group tests by method/event being tested
5. Follow Arrange-Act-Assert pattern
6. Use `bloc_test` for BLoC tests

### Mocking Pattern (Mocktail)

```dart
import 'package:mocktail/mocktail.dart';

// Define mocks
class MockAuthRepository extends Mock implements AuthRepository {}
class MockSignInWithEmail extends Mock implements SignInWithEmail {}

void main() {
  late AuthBloc bloc;
  late MockSignInWithEmail mockSignInWithEmail;

  setUp(() {
    mockSignInWithEmail = MockSignInWithEmail();
    bloc = AuthBloc(mockSignInWithEmail, ...);
  });

  // Register fallback values for custom types
  setUpAll(() {
    registerFallbackValue(SignInWithEmailParams(email: '', password: ''));
  });

  tearDown(() => bloc.close());
}
```

### BLoC Test Pattern

```dart
import 'package:bloc_test/bloc_test.dart';

blocTest<AuthBloc, AuthState>(
  'emits [loading, authenticated] when sign in succeeds',
  build: () {
    when(() => mockSignInWithEmail(any()))
        .thenAnswer((_) async => Right(testUser));
    return bloc;
  },
  act: (bloc) => bloc.add(
    const AuthEvent.signInWithEmailRequested(
      email: 'test@test.com',
      password: 'password',
    ),
  ),
  expect: () => [
    const AuthState.loading(),
    AuthState.authenticated(user: testUser),
  ],
);
```

---

## 10. File Templates

### New Feature Checklist

When creating a new feature `[name]`, create these files in order:

1. `lib/features/[name]/domain/entities/[name]_entity.dart`
2. `lib/features/[name]/domain/repositories/[name]_repository.dart`
3. `lib/features/[name]/domain/usecases/[verb]_[name].dart` (one per action)
4. `lib/features/[name]/data/models/[name]_dto.dart`
5. `lib/features/[name]/data/mappers/[name]_mapper.dart`
6. `lib/features/[name]/data/datasources/[name]_remote_data_source.dart`
7. `lib/features/[name]/data/datasources/[name]_local_data_source.dart` (if offline)
8. `lib/features/[name]/data/repositories/[name]_repository_impl.dart`
9. `lib/features/[name]/presentation/bloc/[name]_event.dart`
10. `lib/features/[name]/presentation/bloc/[name]_state.dart`
11. `lib/features/[name]/presentation/bloc/[name]_bloc.dart`
12. `lib/features/[name]/presentation/pages/[name]_page.dart`
13. Add route to `app_router.dart`
14. Run `make gen`
15. Create tests in `test/features/[name]/`

### Use Case Template

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';

@lazySingleton
class [VerbNoun] implements UseCase<[ReturnType], [Params]> {
  [VerbNoun](this._repository);

  final [Name]Repository _repository;

  @override
  Future<Either<Failure, [ReturnType]>> call([Params] params) =>
      _repository.[method](/* params */);
}
```

### Page Template (with BLoC)

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:track/core/widgets/app_error_widget.dart';
import 'package:track/core/widgets/app_loading_indicator.dart';

@RoutePage()
class [Name]Page extends StatelessWidget {
  const [Name]Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<[Name]Bloc>()
        ..add(const [Name]Event.started()),
      child: const _[Name]View(),
    );
  }
}

class _[Name]View extends StatelessWidget {
  const _[Name]View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[Title]')),
      body: BlocBuilder<[Name]Bloc, [Name]State>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: AppLoadingIndicator.new,
            loaded: (data) => _[Name]Content(data: data),
            error: (failure) => AppErrorWidget(
              message: failure.message,
              onRetry: () => context.read<[Name]Bloc>().add(
                    const [Name]Event.started(),
                  ),
            ),
          );
        },
      ),
    );
  }
}
```

### BLoC Test Template

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:track/core/error/failures.dart';

class Mock[UseCase] extends Mock implements [UseCase] {}

void main() {
  late [Name]Bloc bloc;
  late Mock[UseCase] mock[UseCase];

  setUp(() {
    mock[UseCase] = Mock[UseCase]();
    bloc = [Name]Bloc(mock[UseCase]);
  });

  tearDown(() => bloc.close());

  test('initial state is [Name]Initial', () {
    expect(bloc.state, equals(const [Name]State.initial()));
  });

  blocTest<[Name]Bloc, [Name]State>(
    'emits [loading, loaded] when [event] succeeds',
    build: () {
      when(() => mock[UseCase](any()))
          .thenAnswer((_) async => const Right(/* data */));
      return bloc;
    },
    act: (bloc) => bloc.add(const [Name]Event.started()),
    expect: () => [
      const [Name]State.loading(),
      const [Name]State.loaded(data: /* data */),
    ],
  );

  blocTest<[Name]Bloc, [Name]State>(
    'emits [loading, error] when [event] fails',
    build: () {
      when(() => mock[UseCase](any()))
          .thenAnswer((_) async => const Left(
                Failure.server(message: 'Error'),
              ));
      return bloc;
    },
    act: (bloc) => bloc.add(const [Name]Event.started()),
    expect: () => [
      const [Name]State.loading(),
      const [Name]State.error(
        failure: Failure.server(message: 'Error'),
      ),
    ],
  );
}
```

---

## 11. Do's and Don'ts

### DO

- Always use `Either<Failure, T>` for repository return types
- Always create separate DTOs and Entities (even if they look identical now)
- Always use freezed for Events, States, Entities, DTOs, Failures, and Params
- Always use `@injectable` for BLoCs and `@lazySingleton` for everything else
- Always run `make gen` after creating/modifying freezed or auto_route files
- Always handle all Failure variants in the UI (at least show error message)
- Always use context extensions for theme access
- Always mirror lib/ structure in test/
- Always use `const` constructors where possible
- Always import with package syntax: `import 'package:track/...'`

### DON'T

- Don't call repositories directly from BLoCs — always go through use cases
- Don't throw exceptions from repositories — return Left(Failure)
- Don't put business logic in widgets — it belongs in use cases
- Don't use `setState` for anything that BLoC should manage
- Don't create god-BLoCs that manage unrelated state — one BLoC per feature concern
- Don't use `dynamic` types — always type your variables and parameters
- Don't import dart:io directly in shared code — use abstractions for platform checks
- Don't hardcode strings — use constants files
- Don't skip the mapper layer — even for trivial conversions (allows future divergence)
- Don't use relative imports — always use `package:track/...`
- Don't mix async patterns — stick to `async/await` (avoid `.then()` chains)

### Common Mistakes This AI Should Watch For

1. **Forgetting `part` directives** for freezed/json_serializable files
2. **Missing `@RoutePage()` annotation** on new pages
3. **Not registering new routes** in `app_router.dart`
4. **Forgetting to run `make gen`** after adding freezed classes
5. **Using `Cubit` instead of `Bloc`** — we always use Bloc with events
6. **Returning exceptions instead of Failures** from repositories
7. **Importing implementation classes** instead of abstractions in domain layer
8. **Creating circular dependencies** between features — use shared core/ instead
9. **Not handling the `error` state** in BlocBuilder/BlocListener
10. **Putting Firebase-specific code** in domain layer — it belongs in data layer only

---

## 12. Decision Log

| # | Decision | Choice | Rationale |
|---|---|---|---|
| 1 | App Name | Track | Life-tracking app |
| 2 | Package ID | com.abey.track | Personal brand |
| 3 | Platforms | iOS + Android only | Mobile-first, simplest setup |
| 4 | Min SDKs | iOS 15+ / Android API 24 | ~95% device coverage |
| 5 | Localization | English only | Add i18n later if needed |
| 6 | Accessibility | Standard | Semantic labels, font scaling, good contrast |
| 7 | Architecture | Pure Clean Architecture | User chose strict layer separation for consistency |
| 8 | Use Cases | Always | All business logic through use case classes |
| 9 | Modularization | Mono-package, feature folders | No Melos overhead |
| 10 | Codegen | freezed + json_serializable + auto_route + injectable + drift + flutter_gen | Maximum automation |
| 11 | State Management | Bloc (flutter_bloc) | Predictable, testable, AI-friendly |
| 12 | Bloc vs Cubit | Bloc for everything | 100% consistent event-driven pattern |
| 13 | State Shape | Freezed sealed classes | Type-safe pattern matching |
| 14 | Navigation | auto_route | Type-safe codegen routing |
| 15 | Deep Linking | Deferred | Can add later without refactoring |
| 16 | DI | get_it + injectable | Lazy singletons, codegen registration |
| 17 | Environments | Dev + Prod (--dart-define) | Simple, no staging for solo dev |
| 18 | Backend | Firebase | Auth, FCM, Crashlytics — NOT primary data store |
| 19 | Auth Providers | Google, Apple, Email, Anonymous | Full auth coverage |
| 20 | Data Strategy | Drift-primary | SQLite as source of truth, Firebase for auth/push only |
| 21 | HTTP Client | Dio | Interceptors, cancellation, most popular |
| 22 | Result Type | Either (fpdart) | Forces explicit error handling |
| 23 | Local Database | Drift (SQLite) | Powerful queries, relational data, offline-first |
| 24 | Models | Separate DTOs and Entities | Clean layer separation |
| 25 | Crash Reporting | Firebase Crashlytics | Already using Firebase |
| 26 | Logging | Talker | Dio + BLoC interceptors, UI viewer |
| 27 | Analytics | Deferred | Focus on features first |
| 28 | Design System | Material 3 | Best widget ecosystem, AI familiarity |
| 29 | Dark Mode | Yes, from day one | Easier now than retrofit |
| 30 | Charts | fl_chart | Most popular, highly customizable |
| 31 | Responsive | LayoutBuilder + MediaQuery | No extra package for mobile-only |
| 32 | Assets | flutter_gen | Type-safe codegen |
| 33 | Fonts | Google Fonts package | On-demand loading, massive selection |
| 34 | Mocking | Mocktail | No codegen, null-safe |
| 35 | Test Coverage | Core logic (~60%) | Pragmatic for solo dev |
| 36 | E2E Testing | Patrol | Native automation, deferred |
| 37 | Linter | very_good_analysis | Strict, industry standard |
| 38 | Pre-commit Hooks | None | Solo dev, no friction needed |
| 39 | CI/CD | GitHub Actions | Free, good Flutter support |
| 40 | Distribution | Firebase App Distribution | Already using Firebase |
| 41 | Permissions | permission_handler | Standard approach |
| 42 | Secure Storage | flutter_secure_storage | Encrypted key-value store |
| 43 | Background Tasks | workmanager | Data sync when app closed |
| 44 | Local Notifications | flutter_local_notifications | Reminders, nudges |
| 45 | IAP/Subscriptions | Deferred | Maybe later |
