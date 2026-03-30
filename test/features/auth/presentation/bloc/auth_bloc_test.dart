import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';
import 'package:track/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_event.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late AuthBloc bloc;
  late MockSignInWithEmail mockSignInWithEmail;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignInWithApple mockSignInWithApple;
  late MockSignInAnonymously mockSignInAnonymously;
  late MockSignOut mockSignOut;
  late MockGetCurrentUser mockGetCurrentUser;

  const testUser = UserEntity(
    uid: 'test-uid',
    email: 'test@test.com',
    isAnonymous: false,
  );

  setUp(() {
    mockSignInWithEmail = MockSignInWithEmail();
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignInWithApple = MockSignInWithApple();
    mockSignInAnonymously = MockSignInAnonymously();
    mockSignOut = MockSignOut();
    mockGetCurrentUser = MockGetCurrentUser();

    bloc = AuthBloc(
      mockSignInWithEmail,
      mockSignInWithGoogle,
      mockSignInWithApple,
      mockSignInAnonymously,
      mockSignOut,
      mockGetCurrentUser,
    );
  });

  setUpAll(() {
    registerFallbackValue(const SignInWithEmailParams(email: '', password: ''));
    registerFallbackValue(NoParams());
  });

  tearDown(() => bloc.close());

  test('initial state is AuthInitial', () {
    expect(bloc.state, equals(const AuthState.initial()));
  });

  group('SignInWithEmailRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, authenticated] when sign in succeeds',
      build: () {
        when(
          () => mockSignInWithEmail(any()),
        ).thenAnswer((_) async => const Right(testUser));
        return bloc;
      },
      act:
          (bloc) => bloc.add(
            const AuthEvent.signInWithEmailRequested(
              email: 'test@test.com',
              password: 'password123',
            ),
          ),
      expect:
          () => [
            const AuthState.loading(),
            const AuthState.authenticated(user: testUser),
          ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [loading, error] when sign in fails',
      build: () {
        when(() => mockSignInWithEmail(any())).thenAnswer(
          (_) async => const Left(Failure.auth(message: 'Invalid credentials')),
        );
        return bloc;
      },
      act:
          (bloc) => bloc.add(
            const AuthEvent.signInWithEmailRequested(
              email: 'test@test.com',
              password: 'wrong',
            ),
          ),
      expect:
          () => [
            const AuthState.loading(),
            const AuthState.error(
              failure: Failure.auth(message: 'Invalid credentials'),
            ),
          ],
    );
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [authenticated] when user is logged in',
      build: () {
        when(() => mockGetCurrentUser()).thenReturn(testUser);
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.authCheckRequested()),
      expect: () => [const AuthState.authenticated(user: testUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [unauthenticated] when no user',
      build: () {
        when(() => mockGetCurrentUser()).thenReturn(null);
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.authCheckRequested()),
      expect: () => [const AuthState.unauthenticated()],
    );
  });

  group('SignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [loading, unauthenticated] when sign out succeeds',
      build: () {
        when(
          () => mockSignOut(any()),
        ).thenAnswer((_) async => const Right(unit));
        return bloc;
      },
      act: (bloc) => bloc.add(const AuthEvent.signOutRequested()),
      expect:
          () => [const AuthState.loading(), const AuthState.unauthenticated()],
    );
  });
}
