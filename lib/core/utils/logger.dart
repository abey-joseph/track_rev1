import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

@module
abstract class LoggerModule {
  @lazySingleton
  Talker get talker => Talker();

  @lazySingleton
  TalkerDioLogger talkerDioLogger(Talker talker) => TalkerDioLogger(
    talker: talker,
    settings: const TalkerDioLoggerSettings(printRequestHeaders: true),
  );
}
