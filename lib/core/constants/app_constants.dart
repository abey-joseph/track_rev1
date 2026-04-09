abstract class AppConstants {
  static const String appName = 'Track';
  static const String envKey = 'ENV';
  static const String devEnv = 'dev';
  static const String prodEnv = 'prod';
  static const String mockEnv = 'mock';
  static const String mockUserId = 'mock-user-001';
}

/// Holds the current runtime environment so modules can read it.
///
/// Set once in `main()` before DI initialisation.
class AppEnvironment {
  AppEnvironment._();

  static String current = AppConstants.devEnv;

  static bool get isMock => current == AppConstants.mockEnv;
}
