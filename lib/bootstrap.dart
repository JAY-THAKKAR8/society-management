import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:society_management/auth/repository/auth_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/injector/update_injector.dart';
import 'package:society_management/utility/firebase_messaging_service.dart';

Future<void> bootstrap(Widget builder) async {
  Zone.current.fork().runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Bloc.observer = AppBlocObserver();
    try {
      await FirebaseMessagingService.initializeMain();
      await FirebaseMessagingService().initialize();
    } catch (e) {
      log('Error initializing Firebase services: $e');
      // Continue with app initialization even if Firebase fails
    }
    await configureDependencies();
    // Manually register repositories that are not auto-generated
    updateInjector();

    // Create default admin user if it doesn't exist
    final authRepository = AuthRepository();
    await authRepository.createDefaultAdminIfNotExists();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
    );
    // Lock orientation to portrait mode
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(builder);

    FlutterError.onError = (details) {
      log(details.exceptionAsString(), stackTrace: details.stack);
    };
  });
}
