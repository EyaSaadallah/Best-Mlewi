import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug utility to check gerant account status
class DebugGerant {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if gerant account exists
  static Future<void> checkGerantStatus(String email) async {
    print('\n=== Checking Gerant Account Status ===');
    print('Email: $email\n');

    try {
      // Check Firebase Auth
      print('1. Checking Firebase Authentication...');
      final authUsers = await _auth.fetchSignInMethodsForEmail(email);
      if (authUsers.isNotEmpty) {
        print('   ✓ Found in Firebase Auth');
        print('   Sign-in methods: $authUsers');
      } else {
        print('   ✗ NOT found in Firebase Auth');
      }

      // Check Firestore
      print('\n2. Checking Firestore...');
      final snapshot = await _firestore
          .collection('utilisateurs')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('   ✓ Found in Firestore');
        final doc = snapshot.docs.first;
        final data = doc.data();
        print('   Document ID: ${doc.id}');
        print('   Data:');
        data.forEach((key, value) {
          if (key == 'dateInscription' && value is Timestamp) {
            print('     - $key: ${value.toDate()}');
          } else {
            print('     - $key: $value');
          }
        });

        // Check role
        final role = data['role'] as String?;
        if (role == 'gerant') {
          print('\n   ✓ Role is correctly set to "gerant"');
        } else {
          print('\n   ✗ Role is "$role" (should be "gerant")');
        }
      } else {
        print('   ✗ NOT found in Firestore');
      }

      print('\n=== Status Check Complete ===\n');
    } catch (e) {
      print('✗ Error checking status: $e\n');
    }
  }

  /// Delete gerant account (for testing)
  static Future<void> deleteGerantAccount(String email) async {
    print('\n=== Deleting Gerant Account ===');
    print('Email: $email\n');

    try {
      // Delete from Firestore
      print('1. Deleting from Firestore...');
      final snapshot = await _firestore
          .collection('utilisateurs')
          .where('email', isEqualTo: email)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print('   ✓ Deleted document: ${doc.id}');
      }

      if (snapshot.docs.isEmpty) {
        print('   ℹ No documents found in Firestore');
      }

      // Delete from Firebase Auth
      print('\n2. Deleting from Firebase Auth...');
      print('   ℹ Cannot delete from Auth via app');
      print('   ℹ Please delete manually from Firebase Console:');
      print('   ℹ Authentication → Users → Find and delete user');

      print('\n=== Deletion Complete ===\n');
    } catch (e) {
      print('✗ Error deleting account: $e\n');
    }
  }

  /// List all gerant accounts
  static Future<void> listAllGerants() async {
    print('\n=== Listing All Gerant Accounts ===\n');

    try {
      final snapshot = await _firestore
          .collection('utilisateurs')
          .where('role', isEqualTo: 'gerant')
          .get();

      if (snapshot.docs.isEmpty) {
        print('No gerant accounts found.\n');
        return;
      }

      print('Found ${snapshot.docs.length} gerant account(s):\n');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('- ${data['prenom']} ${data['nom']} (${data['email']})');
      }

      print('\n=== List Complete ===\n');
    } catch (e) {
      print('✗ Error listing gerants: $e\n');
    }
  }

  /// Test Firestore connection
  static Future<void> testFirestoreConnection() async {
    print('\n=== Testing Firestore Connection ===\n');

    try {
      print('1. Testing read access...');
      final snapshot = await _firestore
          .collection('utilisateurs')
          .limit(1)
          .get();
      print('   ✓ Read successful (${snapshot.docs.length} documents)');

      print('\n2. Testing write access...');
      final testDoc = _firestore.collection('_test').doc('connection_test');
      await testDoc.set({'timestamp': FieldValue.serverTimestamp()});
      print('   ✓ Write successful');

      await testDoc.delete();
      print('   ✓ Delete successful');

      print('\n=== Connection Test Complete ===\n');
    } catch (e) {
      print('✗ Connection test failed: $e\n');
    }
  }
}
