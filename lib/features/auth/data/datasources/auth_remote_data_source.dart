import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:track/core/error/exceptions.dart';
import 'package:track/features/auth/data/models/user_dto.dart';

abstract class AuthRemoteDataSource {
  UserDto? get currentUser;

  Stream<UserDto?> get authStateChanges;

  Future<UserDto> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserDto> createAccountWithEmail({
    required String email,
    required String password,
  });

  Future<UserDto> signInWithGoogle();

  Future<UserDto> signInWithApple();

  Future<UserDto> signInAnonymously();

  Future<void> signOut();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._firebaseAuth, this._googleSignIn);

  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  UserDto? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? _mapFirebaseUser(user) : null;
  }

  @override
  Stream<UserDto?> get authStateChanges => _firebaseAuth.authStateChanges().map(
    (user) => user != null ? _mapFirebaseUser(user) : null,
  );

  @override
  Future<UserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user!);
    } on firebase.FirebaseAuthException catch (e) {
      throw ServerException(
        message: e.message ?? 'Authentication failed',
        statusCode: _mapAuthErrorCode(e.code),
      );
    }
  }

  @override
  Future<UserDto> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user!);
    } on firebase.FirebaseAuthException catch (e) {
      throw ServerException(
        message: e.message ?? 'Account creation failed',
        statusCode: _mapAuthErrorCode(e.code),
      );
    }
  }

  @override
  Future<UserDto> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const ServerException(message: 'Google sign-in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return _mapFirebaseUser(userCredential.user!);
    } on firebase.FirebaseAuthException catch (e) {
      throw ServerException(
        message: e.message ?? 'Google sign-in failed',
        statusCode: _mapAuthErrorCode(e.code),
      );
    }
  }

  @override
  Future<UserDto> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = firebase.OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return _mapFirebaseUser(userCredential.user!);
    } on firebase.FirebaseAuthException catch (e) {
      throw ServerException(
        message: e.message ?? 'Apple sign-in failed',
        statusCode: _mapAuthErrorCode(e.code),
      );
    }
  }

  @override
  Future<UserDto> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      return _mapFirebaseUser(credential.user!);
    } on firebase.FirebaseAuthException catch (e) {
      throw ServerException(
        message: e.message ?? 'Anonymous sign-in failed',
        statusCode: _mapAuthErrorCode(e.code),
      );
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  UserDto _mapFirebaseUser(firebase.User user) => UserDto(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
    isAnonymous: user.isAnonymous,
  );

  int _mapAuthErrorCode(String code) => switch (code) {
    'user-not-found' => 404,
    'wrong-password' => 401,
    'email-already-in-use' => 409,
    'weak-password' => 400,
    'invalid-email' => 422,
    _ => 500,
  };
}
