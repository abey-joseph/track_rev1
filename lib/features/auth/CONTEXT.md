# auth — CONTEXT

Firebase-backed authentication with email/password, Google, and anonymous sign-in. Gate for every other feature via `AuthGuard` on the app shell.

## Key files
- `domain/entities/user_entity.dart` — `UserEntity { uid, email, isAnonymous, displayName?, photoUrl? }`.
- `domain/repositories/auth_repository.dart` — abstract repo (see surface below).
- `domain/usecases/` — `SignInWithEmail`, `CreateAccountWithEmail`, `SignInWithGoogle`, `SignInAnonymously`, `SignOut`, `GetCurrentUser` (sync, no `Either`).
- `data/datasources/` — `AuthRemoteDataSource` (Firebase), `AuthLocalDataSource` (secure storage).
- `data/models/user_dto.dart`, `data/mappers/user_mapper.dart`.
- `data/repositories/auth_repository_impl.dart` — `@LazySingleton(as: AuthRepository)`.
- `presentation/bloc/auth_bloc.dart`, `auth_event.dart`, `auth_state.dart`.
- `presentation/pages/splash_page.dart`, `login_page.dart`.
- `presentation/widgets/email_sign_in_form.dart`, `social_sign_in_button.dart`.

## Public surface — `AuthRepository`
- `UserEntity? get currentUser` — sync.
- `Stream<UserEntity?> get authStateChanges`.
- `signInWithEmail({email, password}) → Either<Failure, UserEntity>`
- `signInWithGoogle() → Either<Failure, UserEntity>`
- `signInAnonymously() → Either<Failure, UserEntity>`
- `signOut() → Either<Failure, Unit>`
- `createAccountWithEmail({email, password}) → Either<Failure, UserEntity>`

## State — `AuthState` (sealed)
`initial` | `loading` | `authenticated(user)` | `unauthenticated` | `error(failure)`

## Events — `AuthEvent` (sealed)
`signInWithEmailRequested` | `signInWithGoogleRequested` | `signInAnonymouslyRequested` | `signOutRequested` | `authCheckRequested` | `createAccountWithEmailRequested`

## Wiring
- `AuthBloc` is registered in the root `BlocProvider` inside `TrackApp` (`main.dart`) so it's reachable from every route.
- `AuthGuard` (in `core/router/`) calls `authRepository.currentUser` synchronously — it does **not** wait for the `authStateChanges` stream.
- `main.dart` subscribes to `authStateChanges.where(user != null).take(1)` in mock mode to trigger `DatabaseSeeder.seedIfNeeded(uid)`.

## Gotchas
- `GetCurrentUser` does not return `Either` — it's a plain getter. Do not wrap its call in `.fold`.
- `AuthState` is emitted fresh per request; there's no `buildWhen`-style filtering, since auth is a global gate.
- After `signOutRequested`, `AppShellPage` and `HomePage` both listen for `unauthenticated` and call `router.replaceAll([const LoginRoute()])`.
- Anonymous users still get a valid `uid`; `isAnonymous: true` is the only distinguishing signal.
