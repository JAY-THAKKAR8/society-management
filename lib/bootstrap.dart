import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:society_management/injector/injector.dart';
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
    configureDependencies();
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
