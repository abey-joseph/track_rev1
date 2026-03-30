import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:track/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
Future<void> configureDependencies(String env) => getIt.init(environment: env);
