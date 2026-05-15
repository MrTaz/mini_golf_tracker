import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class DatabaseConnection {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static FirebaseFirestore? _firestoreInstance;

  static void setFirestoreInstanceForTesting(FirebaseFirestore? instance) {
    _firestoreInstance = instance;
  }

  static FirebaseFirestore get client => _firestoreInstance ?? FirebaseFirestore.instance;
  static FirebaseFirestore getFirestore() => client;
}
