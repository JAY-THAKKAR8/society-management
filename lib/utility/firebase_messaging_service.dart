import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _onBackgroundMessageHandler(RemoteMessage message) async {
  log('on background message handler $message');
  log(message.data['data'].toString());
}

class FirebaseMessagingService {
  factory FirebaseMessagingService() {
    return _singleton;
  }

  FirebaseMessagingService._internal();

  static final FirebaseMessagingService _singleton = FirebaseMessagingService._internal();

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static String? token;

  // late AndroidNotificationChannel channel;

  late StreamSubscription<RemoteMessage> onFrontEndStream;
  late StreamSubscription<RemoteMessage> onOpenAppStream;
  late StreamSubscription<String> tokenStream;

  static Future<void> initializeMain() async {
    try {
      // Initialize Firebase with default options
      try {
        await Firebase.initializeApp();
      } catch (e) {
        log('Error initializing Firebase with default options: $e');
        // If default initialization fails, try with explicit options
        log('Attempting to initialize Firebase with explicit options');
        await Firebase.initializeApp(
          // These options are from your google-services.json file
          options: const FirebaseOptions(
            apiKey: 'AIzaSyDV_Lyn6WQUfkn6ARbF3jJLCEw2FVdjwVg',
            appId: '1:100215673817:android:7b5edeed15419529733fc8',
            messagingSenderId: '100215673817',
            projectId: 'society-management-46696',
            storageBucket: 'society-management-46696.firebasestorage.app',
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 1));
      try {
        token = await FirebaseMessaging.instance.getToken() ?? '';
        log('token::::: $token');
        FirebaseMessaging.onBackgroundMessage(_onBackgroundMessageHandler);
      } catch (e) {
        log('Error setting up Firebase Messaging: $e');
      }
    } catch (e) {
      log('Error initializing Firebase: $e');
      // Continue with app initialization even if Firebase fails
      // This prevents the app from crashing if Firebase setup fails
    }
  }

  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _firebaseMessaging.requestPermission(
        announcement: true,
        carPlay: true,
        criticalAlert: true,
      );
    } catch (e) {
      log('Error requesting notification permissions: $e');
      // Continue even if permission request fails
    }

    // if (accepted.authorizationStatus == AuthorizationStatus.denied ||
    //     accepted.authorizationStatus == AuthorizationStatus.notDetermined) return;

    //   await _onOpenedAppFromTerminateMessage();

    //   if (!kIsWeb) {
    //     channel = const AndroidNotificationChannel(
    //       'high_importance_channel', // id
    //       'High Importance Notifications', // title
    //       description: 'This channel is used for important notifications.', // description
    //       importance: Importance.high,
    //     );

    //     const initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_notification');
    //     // const initializationSettingsAndroid =
    //     //     AndroidInitializationSettings('@drawable/ic_notification');

    //     final initializationSettingsIOS = DarwinInitializationSettings(
    //       onDidReceiveLocalNotification: (_, __, ___, ____) async {
    //         log('IOS NOTIFICATION');
    //       },
    //     );

    //     final initializationSettings = InitializationSettings(
    //       android: initializationSettingsAndroid,
    //       iOS: initializationSettingsIOS,
    //     );

    //     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    //     await flutterLocalNotificationsPlugin.initialize(
    //       initializationSettings,
    //       onDidReceiveNotificationResponse: _onOpenedLocalNotification,
    //     );

    //     await flutterLocalNotificationsPlugin
    //         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    //         ?.createNotificationChannel(channel);

    //     await _firebaseMessaging.setForegroundNotificationPresentationOptions(
    //       alert: true,
    //       badge: true,
    //       sound: true,
    //     );

    //     _onFrontEndMessage(flutterLocalNotificationsPlugin);
    //   }

    //   await _setToken();

    //   _onOpenedAppMessage();
    //   log('::::::');
    // }

    // Future<void> _onOpenedAppFromTerminateMessage() async {
    //   final initialMessage = await _firebaseMessaging.getInitialMessage();
    //   if (initialMessage != null) {
    //     log('on teminated opended App message $initialMessage');
    //     final notification = AndriodNotificationModel.fromJson(jsonDecode(initialMessage.data['data']));
    //     if (notification.clickAction != null) {
    //       navigatorKey.currentState?.push(MaterialPageRoute(
    //         builder: (context) => const NotifiactionScreen(),
    //       ));
    //     }
    //   }
    // }

    // Future<void> _onOpenedLocalNotification(NotificationResponse? response) async {
    //   if (response?.payload != null) {
    //     final payload = response!.payload!;

    //     final notification = AndriodNotificationModel.fromJson(jsonDecode(jsonDecode(payload)['data']));
    //     if (notification.clickAction != null) {
    //       navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => const NotifiactionScreen()));
    //     }

    //     log('on opened local notification $payload');
    //   }
    // }

    // void _onOpenedAppMessage() {
    //   FirebaseMessaging.onMessageOpenedApp.listen((message) async {
    //     log('body - ${message.data}');
    //     log('on frontend opended App message $message');
    //     final notification = AndriodNotificationModel.fromJson(jsonDecode(message.data['data']));
    //     if (notification.clickAction != null) {
    //       navigatorKey.currentState?.push(MaterialPageRoute(
    //         builder: (context) => const NotifiactionScreen(),
    //       ));
    //     }
    //   });
    // }

    // void _onFrontEndMessage(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) {
    //   onFrontEndStream = FirebaseMessaging.onMessage.listen((message) {
    //     log('NOTIFICATION');
    //     log(message.notification?.title ?? '');
    //     log('aaaaaaaaa ${message.data} ');
    //     final notification = message.notification;
    //     final android = message.notification?.android;
    //     if (notification != null && android != null && !kIsWeb) {
    //       flutterLocalNotificationsPlugin.show(
    //         notification.hashCode,
    //         notification.title,
    //         null,
    //         NotificationDetails(
    //           android: AndroidNotificationDetails(channel.id, channel.name,
    //               channelDescription: channel.description,
    //               icon: '@drawable/ic_notification',
    //               styleInformation: BigTextStyleInformation(notification.body ?? "")),
    //         ),
    //         payload: jsonEncode(message.data),
    //       );
    //     }
    //   });
    // }

    // Future _setToken() async {
    //   token = await FirebaseMessaging.instance.getToken() ?? '';

    //   tokenStream = _firebaseMessaging.onTokenRefresh.listen((newToken) {
    //     token = newToken;
    //   });
    //   log("Token :::::::::  $token");
    // }

    // void dispose() {
    //   onFrontEndStream.cancel();
    //   onOpenAppStream.cancel();
    //   tokenStream.cancel();
    // }
  }
}
