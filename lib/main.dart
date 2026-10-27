
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/welcome/welcome_screen.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const BloodDonationApp());
}

class BloodDonationApp extends StatefulWidget {
  const BloodDonationApp({super.key});

  @override
  State<BloodDonationApp> createState() =>
      _BloodDonationAppState();
}

class _BloodDonationAppState extends State<BloodDonationApp> {
  @override
  void initState() {
    super.initState();

    // Initialize the notification service only once.
    NotificationService.initialize();

    // Set up FCM message listeners.
    setupFirebaseMessageListeners();
  }

  void setupFirebaseMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Foreground title: ${message.notification?.title}',
      );
      debugPrint(
        'Foreground body: ${message.notification?.body}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {
        debugPrint('Notification opened: ${message.data}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Donation',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE31E24),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
