import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'models/user.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

final FlutterLocalNotificationsPlugin
    flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
  'on_time_high_importance',
  'On Time-notiser',
  description:
      'Viktiga notiser för träffar och inbjudningar.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
}

Future<void> _setupNotifications() async {
  const androidSettings =
      AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const initializationSettings =
      InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  final androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(
    highImportanceChannel,
  );
}

Future<void> _showNotification(
  RemoteMessage message,
) async {
  final notification = message.notification;

  if (notification == null) {
    return;
  }

  await flutterLocalNotificationsPlugin.show(
    id: notification.hashCode,
    title: notification.title ?? 'On Time',
    body: notification.body ?? '',
    notificationDetails:
        const NotificationDetails(
      android: AndroidNotificationDetails(
        'on_time_high_importance',
        'On Time-notiser',
        channelDescription:
            'Viktiga notiser för träffar och inbjudningar.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await _setupNotifications();

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  final messaging = FirebaseMessaging.instance;

  final permission =
      await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint(
    'NOTISBEHÖRIGHET: '
    '${permission.authorizationStatus}',
  );

  final fcmToken =
      await messaging.getToken();

  debugPrint(
    'FCM TOKEN: $fcmToken',
  );

  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {
      debugPrint(
        'FCM MEDDELANDE MOTTAGET!',
      );

      debugPrint(
        'Titel: ${message.notification?.title}',
      );

      debugPrint(
        'Text: ${message.notification?.body}',
      );

      await _showNotification(
        message,
      );
    },
  );

  final authService = AuthService();

  final savedUser =
      await authService.getSavedUser();

  if (savedUser != null) {
    await authService.registerDeviceToken();
  }

  runApp(
    OnTimeApp(
      savedUser: savedUser,
    ),
  );
}

class OnTimeApp extends StatelessWidget {
  final User? savedUser;

  const OnTimeApp({
    super.key,
    required this.savedUser,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'On Time',
      theme: AppTheme.lightTheme,
      home: savedUser == null
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}