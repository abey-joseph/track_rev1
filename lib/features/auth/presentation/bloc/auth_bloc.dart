import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/auth/domain/usecases/create_account_with_email.dart';
import 'package:track/features/auth/domain/usecases/get_current_user.dart';
import 'package:track/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:track/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:track/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:track/features/auth/domain/usecases/sign_out.dart';
import 'package:track/features/auth/presentation/bloc/auth_event.dart';
import 'package:track/features/auth/presentation/bloc/auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._signInWithEmail,
    this._createAccountWithEmail,
    this._signInWithGoogle,
    this._signInAnonymously,
    this._signOut,
    this._getCurrentUser,
  ) : super(const AuthState.initial()) {
    on<SignInWithEmailRequested>(_onSignInWithEmail);
    on<SignInWithGoogleRequested>(_onSignInWithGoogle);
    on<SignInAnonymouslyRequested>(_onSignInAnonymously);
    on<SignOutRequested>(_onSignOut);
    on<AuthCheckRequested>(_onAuthCheck);
    on<CreateAccountWithEmailRequested>(_onCreateAccountWithEmail);
  }

  final SignInWithEmail _signInWithEmail;
  final CreateAccountWithEmail _createAccountWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignInAnonymously _signInAnonymously;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;

  Future<void> _onSignInWithEmail(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInWithEmail(
      SignInWithEmailParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) => emit(AuthState.authenticated(user: user)),
    );
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInWithGoogle(NoParams());
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) => emit(AuthState.authenticated(user: user)),
    );
  }

  Future<void> _onSignInAnonymously(
    SignInAnonymouslyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signInAnonymously(NoParams());
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) => emit(AuthState.authenticated(user: user)),
    );
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _signOut(NoParams());
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  void _onAuthCheck(AuthCheckRequested event, Emitter<AuthState> emit) {
    final user = _getCurrentUser();
    if (user != null) {
      emit(AuthState.authenticated(user: user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onCreateAccountWithEmail(
    CreateAccountWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _createAccountWithEmail(
      SignInWithEmailParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthState.error(failure: failure)),
      (user) => emit(AuthState.authenticated(user: user)),
    );
  }
}
