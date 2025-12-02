import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/firebase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/home_screen.dart';
import 'screens/visitor_screen.dart';
import 'services/notification_service.dart';
import 'constants/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseConfig.initialize();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseConfig.initialize();
    await dotenv.load(fileName: ".env");

    // Set up FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BestMlewi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const VisitorScreen(),
      routes: {
        '/visitor': (context) => const VisitorScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/setup': (context) => const SetupScreen(),
        '/debug': (context) => const DebugScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
