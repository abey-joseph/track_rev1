import 'package:mocktail/mocktail.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';
import 'package:track/features/auth/domain/usecases/get_current_user.dart';
import 'package:track/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:track/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:track/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:track/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:track/features/auth/domain/usecases/sign_out.dart';

// Repository Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

// Use Case Mocks
class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockSignInWithApple extends Mock implements SignInWithApple {}

class MockSignInAnonymously extends Mock implements SignInAnonymously {}

class MockSignOut extends Mock implements SignOut {}

class MockGetCurrentUser extends Mock implements GetCurrentUser {}
