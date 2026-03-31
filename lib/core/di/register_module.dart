import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn(
    // iOS uses REVERSED_CLIENT_ID from Info.plist URL scheme.
    // Android uses the SHA-1 fingerprint registered in Firebase Console.
    // clientId is only needed on iOS to match the CLIENT_ID in GoogleService-Info.plist.
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? '352516631245-gart4k6fpsca23naabpos7d1tse8i7o2.apps.googleusercontent.com'
        : null,
  );

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  Connectivity get connectivity => Connectivity();
}
