abstract class ApiConstants {
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Add base URLs per environment as needed
  static const String devBaseUrl = 'https://api.example.com/dev';
  static const String prodBaseUrl = 'https://api.example.com';
}
