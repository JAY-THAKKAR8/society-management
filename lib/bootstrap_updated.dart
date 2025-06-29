import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:society_management/ads/service/ad_service.dart';
import 'package:society_management/auth/repository/auth_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/injector/update_injector.dart';
import 'package:society_management/maintenance/service/maintenance_background_service.dart';
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

    // Initialize AdMob
    try {
      await AdService.initialize();
      log('AdMob initialized successfully');
    } catch (e) {
      log('Error initializing AdMob: $e');
      // Continue with app initialization even if AdMob fails
    }

    // Create default admin user if it doesn't exist
    final authRepository = AuthRepository();
    await authRepository.createDefaultAdminIfNotExists();

    // Initialize maintenance background service
    try {
      MaintenanceBackgroundService().initialize();
      log('Maintenance background service initialized');
    } catch (e) {
      log('Error initializing maintenance background service: $e');
      // Continue with app initialization even if service initialization fails
    }

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
