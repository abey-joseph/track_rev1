import 'dart:io';

import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:track/core/database/app_database.dart';

@module
abstract class DatabaseModule {
  @preResolve
  @lazySingleton
  Future<AppDatabase> get database async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'track.db'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }
}
