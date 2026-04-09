import 'package:drift/native.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/database/seeder/database_seeder.dart';

/// Default user ID used in mock database tests.
const mockUserId = 'test-user-001';

/// Creates an in-memory [AppDatabase] with all mock data seeded.
///
/// Use this helper in any test that needs a fully populated database
/// instead of mocking individual DAOs.
///
/// ```dart
/// late AppDatabase db;
/// setUp(() async {
///   db = await createSeededMockDatabase();
/// });
/// tearDown(() => db.close());
/// ```
Future<AppDatabase> createSeededMockDatabase({
  String userId = mockUserId,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  await DatabaseSeeder(db).seedIfNeeded(userId);
  return db;
}

/// Creates an empty in-memory [AppDatabase] (no seed data).
AppDatabase createEmptyMockDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
