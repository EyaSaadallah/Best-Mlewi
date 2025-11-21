import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Firebase initialization configuration
class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
