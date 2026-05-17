import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mini_golf_tracker/database_connection.dart';

void main() {
  group('DatabaseConnection', () {
    test('can set and get firestore instance for testing', () {
      final fake = FakeFirebaseFirestore();
      DatabaseConnection.setFirestoreInstanceForTesting(fake);
      expect(DatabaseConnection.client, fake);
      expect(DatabaseConnection.getFirestore(), fake);
      
      // Reset back to null
      DatabaseConnection.setFirestoreInstanceForTesting(null);
    });
  });
}
