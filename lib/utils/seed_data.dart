import 'package:firebase_auth/firebase_auth.dart';
import '../models/gerant.dart';
import '../models/enums.dart';
import '../repositories/utilisateur_repository.dart';

/// Utility to seed initial data (gerant account)
class SeedData {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final UtilisateurRepository _userRepository = UtilisateurRepository();

  /// Create gerant (super user) account
  static Future<void> createGerantAccount({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    try {
      // Check if account already exists in Firestore
      final existingUser = await _userRepository.getByEmail(email);
      if (existingUser != null && existingUser.role == Role.gerant) {
        throw Exception('Gerant account already exists: $email');
      }

      // Try to create Firebase Auth user
      print('🔐 Creating Firebase Auth user...');
      print('   Email: $email');
      print('   Password length: ${password.length}');
      print('   Password: $password');

      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✓ Firebase Auth user created successfully');
        print('   UID: ${userCredential.user?.uid}');
      } on FirebaseAuthException catch (authError) {
        print('✗ Firebase Auth error during creation: ${authError.code}');
        print('   Message: ${authError.message}');

        if (authError.code == 'email-already-in-use') {
          // Email exists in Firebase Auth but maybe not in Firestore
          // Try to create Firestore document anyway
          print(
            '⚠ Email exists in Firebase Auth, creating Firestore document...',
          );
          final gerant = Gerant(
            id: DateTime.now().millisecondsSinceEpoch,
            nom: nom,
            prenom: prenom,
            email: email,
            motDePasse: '',
            telephone: telephone,
            dateInscription: DateTime.now(),
          );
          await _userRepository.create(gerant);
          print('✓ Firestore document created for existing auth user');
          print('  Email: $email');
          print('  Name: $prenom $nom');
          return;
        } else if (authError.code == 'weak-password') {
          throw Exception(
            'Password is too weak. Use: uppercase, lowercase, digit, special char (@\$!%*?&)',
          );
        } else if (authError.code == 'invalid-email') {
          throw Exception('Invalid email format: $email');
        } else {
          throw Exception('Firebase Auth error: ${authError.message}');
        }
      }

      if (userCredential.user == null) {
        throw Exception('Failed to create Firebase Auth user');
      }

      print('✓ Firebase Auth user verified');

      // Create Firestore gerant document
      final gerant = Gerant(
        id: DateTime.now().millisecondsSinceEpoch,
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: '', // Empty - password managed by Firebase Auth
        telephone: telephone,
        dateInscription: DateTime.now(),
      );

      await _userRepository.create(gerant);
      print('✓ Gerant account created successfully!');
      print('  Email: $email');
      print('  Name: $prenom $nom');
    } catch (e) {
      throw Exception('Error creating gerant account: $e');
    }
  }
}
