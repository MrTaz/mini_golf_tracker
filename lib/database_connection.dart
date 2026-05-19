import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

class DatabaseConnection {
  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        if (!e.toString().contains('duplicate-app')) {
          rethrow;
        }
      }
    }

    // Connect to the local emulator only if explicitly configured via dart-define!
    if (const bool.fromEnvironment('USE_EMULATOR', defaultValue: false)) {
      try {
        // Android emulators require '10.0.2.2' to access the host machine's localhost.
        // iOS emulators and desktop runs can use standard 'localhost'.
        final String host = defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost';
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        debugPrint('🔌 Connected to local Firestore Emulator at $host:8080');

        FirebaseAuth.instance.useAuthEmulator(host, 9099);
        debugPrint('🔌 Connected to local Auth Emulator at $host:9099');
      } catch (e) {
        debugPrint('⚠️ Failed to connect to Emulators: $e');
      }
    }
  }

  static FirebaseFirestore? _firestoreInstance;

  static void setFirestoreInstanceForTesting(FirebaseFirestore? instance) {
    _firestoreInstance = instance;
  }

  static FirebaseFirestore get client =>
      _firestoreInstance ?? FirebaseFirestore.instance;
  static FirebaseFirestore getFirestore() => client;
}
