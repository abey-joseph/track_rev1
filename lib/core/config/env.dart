import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  // Firebase Android
  @EnviedField(varName: 'FIREBASE_ANDROID_API_KEY')
  static final String firebaseAndroidApiKey = _Env.firebaseAndroidApiKey;

  @EnviedField(varName: 'FIREBASE_ANDROID_APP_ID')
  static final String firebaseAndroidAppId = _Env.firebaseAndroidAppId;

  @EnviedField(varName: 'FIREBASE_ANDROID_MESSAGING_SENDER_ID')
  static final String firebaseAndroidMessagingSenderId =
      _Env.firebaseAndroidMessagingSenderId;

  @EnviedField(varName: 'FIREBASE_ANDROID_PROJECT_ID')
  static final String firebaseAndroidProjectId = _Env.firebaseAndroidProjectId;

  @EnviedField(varName: 'FIREBASE_ANDROID_STORAGE_BUCKET')
  static final String firebaseAndroidStorageBucket =
      _Env.firebaseAndroidStorageBucket;

  // Firebase iOS
  @EnviedField(varName: 'FIREBASE_IOS_API_KEY')
  static final String firebaseIosApiKey = _Env.firebaseIosApiKey;

  @EnviedField(varName: 'FIREBASE_IOS_APP_ID')
  static final String firebaseIosAppId = _Env.firebaseIosAppId;

  @EnviedField(varName: 'FIREBASE_IOS_MESSAGING_SENDER_ID')
  static final String firebaseIosMessagingSenderId =
      _Env.firebaseIosMessagingSenderId;

  @EnviedField(varName: 'FIREBASE_IOS_PROJECT_ID')
  static final String firebaseIosProjectId = _Env.firebaseIosProjectId;

  @EnviedField(varName: 'FIREBASE_IOS_STORAGE_BUCKET')
  static final String firebaseIosStorageBucket = _Env.firebaseIosStorageBucket;

  @EnviedField(varName: 'FIREBASE_IOS_BUNDLE_ID')
  static final String firebaseIosBundleId = _Env.firebaseIosBundleId;
}
