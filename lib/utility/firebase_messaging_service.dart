import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  static FirebaseMessagingService? _instance;

  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

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
      // Set instance for static access
      _instance = this;

      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        announcement: true,
        carPlay: true,
        criticalAlert: true,
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        log('Notification permissions denied');
        return;
      }

      log('Notification permissions granted');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up message handlers
      await _setupMessageHandlers();

      // Get and set token
      await _setToken();
    } catch (e) {
      log('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) return;

    // Create notification channel for Android
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize settings
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Set foreground notification options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
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

  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Handle messages when app is opened from terminated state
    await _handleInitialMessage();
  }

  Future<void> _setToken() async {
    try {
      token = await _firebaseMessaging.getToken();
      log('FCM Token: $token');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        token = newToken;
        log('FCM Token refreshed: $newToken');
        // TODO: Send token to server
      });
    } catch (e) {
      log('Error getting FCM token: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    log('Foreground message received: ${message.notification?.title}');

    if (!kIsWeb && message.notification != null) {
      _showLocalNotification(message);
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    log('Message opened app: ${message.notification?.title}');
    _handleNotificationTap(message.data);
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      log('App opened from terminated state: ${initialMessage.notification?.title}');
      _handleNotificationTap(initialMessage.data);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    log('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        log('Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    log('Handling notification tap with data: $data');
    // TODO: Navigate to appropriate screen based on notification data
    // Example: Navigate to meeting details, maintenance page, etc.
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    try {
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? 'Society Management',
        message.notification?.body ?? 'You have a new notification',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(
              message.notification?.body ?? '',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      log('Error showing local notification: $e');
    }
  }

  // Public static methods for sending notifications
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // TODO: Implement server-side notification sending
    // This would typically call a Cloud Function or your backend API
    log('Sending notification to user $userId: $title - $body');
  }

  static Future<void> sendNotificationToLine({
    required String lineNumber,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // TODO: Implement server-side notification sending for line
    log('Sending notification to line $lineNumber: $title - $body');
  }

  static Future<void> sendNotificationToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // TODO: Implement server-side notification sending to all users
    log('Sending notification to all users: $title - $body');
  }

  /// Get current instance for local notifications
  static FirebaseMessagingService? get instance => _instance;

  /// Show local notification directly (for testing or immediate notifications)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (_instance != null && !kIsWeb) {
      try {
        await _instance!.flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _instance!.channel.id,
              _instance!.channel.name,
              channelDescription: _instance!.channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(body),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: data != null ? jsonEncode(data) : null,
        );
      } catch (e) {
        log('Error showing local notification: $e');
      }
    }
  }

  void dispose() {
    // Clean up streams if needed
  }
}
