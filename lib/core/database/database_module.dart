import 'dart:io';

import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:track/core/constants/app_constants.dart';
import 'package:track/core/database/app_database.dart';

@module
abstract class DatabaseModule {
  @preResolve
  @lazySingleton
  Future<AppDatabase> get database async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbName = AppEnvironment.isMock ? 'track_mock.db' : 'track.db';
    final file = File(p.join(dbFolder.path, dbName));
    return AppDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
  }
}
