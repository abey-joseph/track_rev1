import 'package:flutter_test/flutter_test.dart';
import 'package:track/core/error/failures.dart';

void main() {
  group('Failure', () {
    test('ServerFailure should contain message and code', () {
      const failure = Failure.server(message: 'Server error', code: 500);
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).message, 'Server error');
      expect(failure.code, 500);
    });

    test('CacheFailure should contain message', () {
      const failure = Failure.cache(message: 'Cache error');
      expect(failure, isA<CacheFailure>());
      expect((failure as CacheFailure).message, 'Cache error');
    });

    test('AuthFailure should contain message and code', () {
      const failure = Failure.auth(
        message: 'Auth error',
        code: 'user-not-found',
      );
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).message, 'Auth error');
      expect(failure.code, 'user-not-found');
    });

    test('Failure equality works', () {
      const failure1 = Failure.server(message: 'error', code: 500);
      const failure2 = Failure.server(message: 'error', code: 500);
      expect(failure1, equals(failure2));
    });
  });
}
