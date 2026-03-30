// Exceptions thrown in the data layer.
// Caught by repository implementations and mapped to Failure types.

class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ServerException(message: $message, statusCode: $statusCode)';
}

class CacheException implements Exception {
  const CacheException({required this.message});

  final String message;

  @override
  String toString() => 'CacheException(message: $message)';
}

class NetworkException implements Exception {
  const NetworkException({required this.message});

  final String message;

  @override
  String toString() => 'NetworkException(message: $message)';
}
