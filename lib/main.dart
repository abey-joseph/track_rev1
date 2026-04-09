import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:track/core/constants/app_constants.dart';
import 'package:track/core/database/app_database.dart';
import 'package:track/core/database/seeder/database_seeder.dart';
import 'package:track/core/router/app_router.dart';
import 'package:track/core/theme/app_theme.dart';
import 'package:track/features/auth/domain/repositories/auth_repository.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/firebase_options.dart';
import 'package:track/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const env = String.fromEnvironment(
    AppConstants.envKey,
    defaultValue: AppConstants.devEnv,
  );
  AppEnvironment.current = env;
  await configureDependencies(env);

  // Setup Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Setup BLoC observer with Talker
  Bloc.observer = TalkerBlocObserver(talker: getIt());

  // In mock mode, seed the database after the first successful auth.
  if (AppEnvironment.isMock) {
    _seedOnFirstAuth();
  }

  runApp(const TrackApp());
}

/// Listens for the first authenticated user and seeds mock data for
/// that user's UID. Runs once and cancels the subscription.
void _seedOnFirstAuth() {
  final authRepo = getIt<AuthRepository>();
  late final StreamSubscription<dynamic> sub;
  sub = authRepo.authStateChanges.where((user) => user != null).take(1).listen((
    user,
  ) async {
    final db = getIt<AppDatabase>();
    final seeded = await DatabaseSeeder(db).seedIfNeeded(user!.uid);
    if (seeded && kDebugMode) {
      debugPrint('[MockSeeder] Seeded mock data for ${user.uid}');
    }
    await sub.cancel();
  });
}

class TrackApp extends StatelessWidget {
  const TrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: appRouter.config(),
      ),
    );
  }
}
