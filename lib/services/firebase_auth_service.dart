import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/utilisateur.dart';
import '../models/enums.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/firebase_options.dart';
import '../repositories/utilisateur_repository.dart';

/// Firebase authentication service
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UtilisateurRepository _userRepository = UtilisateurRepository();

  factory FirebaseAuthService() {
    return _instance;
  }

  FirebaseAuthService._internal();

  Utilisateur? _currentUser;

  Utilisateur? get currentUser => _currentUser;

  /// Register new user with email and password
  Future<bool> register(
    String email,
    String password,
    String nom,
    String prenom,
    String telephone, {
    Role role = Role.client,
  }) async {
    try {
      // Create Firebase auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create Firestore user document
        // Note: Password is NOT stored in Firestore - Firebase Auth manages it
        final utilisateur = Utilisateur(
          id: DateTime.now().millisecondsSinceEpoch,
          nom: nom,
          prenom: prenom,
          email: email,
          motDePasse: '', // Empty - password is managed by Firebase Auth
          telephone: telephone,
          dateInscription: DateTime.now(),
          role: role,
        );

        await _userRepository.create(utilisateur);
        _currentUser = utilisateur;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during registration: $e');
    }
  }

  /// Register a new user without signing out the current user (for admins/gerants)
  Future<bool> registerSecondary(
    String email,
    String password,
    String nom,
    String prenom,
    String telephone, {
    Role role = Role.collaborateur,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Initialize a secondary Firebase App
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create user in the secondary app (doesn't affect main auth state)
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create Firestore user document using the MAIN app's repository/firestore
        final utilisateur = Utilisateur(
          id: DateTime.now().millisecondsSinceEpoch,
          nom: nom,
          prenom: prenom,
          email: email,
          motDePasse: '', // Empty - password is managed by Firebase Auth
          telephone: telephone,
          dateInscription: DateTime.now(),
          role: role,
        );

        await _userRepository.create(utilisateur);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during registration: $e');
    } finally {
      // Clean up the secondary app
      await secondaryApp?.delete();
    }
  }

  /// Login user with email and password
  Future<bool> login(String email, String password) async {
    try {
      print('🔐 Attempting login for: $email');
      print('   Password length: ${password.length}');
      print('   Password chars: ${password.split('').join(', ')}');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✓ Firebase Auth successful for: $email');

      if (userCredential.user != null) {
        // Fetch user from Firestore
        print('📄 Fetching user profile from Firestore...');
        final utilisateur = await _userRepository.getByEmail(email);

        if (utilisateur != null) {
          print(
            '✓ User found in Firestore: ${utilisateur.prenom} ${utilisateur.nom}',
          );
          print('  Role: ${utilisateur.role.name}');

          if (!utilisateur.isActive) {
            print('✗ User account is disabled');
            await _auth.signOut();
            throw Exception('Account disabled. Please contact support.');
          }

          _currentUser = utilisateur;
          return true;
        } else {
          print('✗ User NOT found in Firestore for email: $email');
          print(
            '  This means the account exists in Firebase Auth but not in Firestore',
          );
          throw Exception(
            'User profile not found in database. Please contact support.',
          );
        }
      }
      print('✗ Firebase Auth user is null');
      return false;
    } on FirebaseAuthException catch (e) {
      print('✗ Firebase Auth error: ${e.code} - ${e.message}');
      print('   Full error: $e');
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('✗ Unexpected error: $e');
      throw Exception('Unexpected error during login: $e');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _currentUser != null && _auth.currentUser != null;
  }

  /// Get current Firebase user
  User? get firebaseUser => _auth.currentUser;

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update password in Firebase Auth with re-authentication
  /// Note: Password is managed by Firebase Authentication, not stored in Firestore
  Future<void> updatePasswordWithReauth(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user currently logged in');
      }

      final email = user.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: email,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password in Firebase Authentication
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('The old password provided is incorrect.');
      }
      throw Exception('Password update failed: ${e.message}');
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return false;
      }

      // Get Google authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final email = user.email ?? '';

        // Check if user exists in Firestore
        var utilisateur = await _userRepository.getByEmail(email);

        if (utilisateur == null) {
          // Create new user in Firestore
          utilisateur = Utilisateur(
            id: DateTime.now().millisecondsSinceEpoch,
            nom: user.displayName?.split(' ').last ?? 'User',
            prenom: user.displayName?.split(' ').first ?? '',
            email: email,
            motDePasse: '', // Google auth doesn't use password
            telephone: user.phoneNumber ?? '',
            dateInscription: DateTime.now(),
            role: Role.client,
          );

          await _userRepository.create(utilisateur);

          // Small delay to ensure Firestore write completes
          await Future.delayed(const Duration(milliseconds: 500));

          // Fetch the created user to ensure we have the latest data
          utilisateur = await _userRepository.getByEmail(email);
        }

        if (utilisateur != null) {
          if (!utilisateur.isActive) {
            await _auth.signOut();
            await _googleSignIn.signOut();
            throw Exception('Account disabled. Please contact support.');
          }
          _currentUser = utilisateur;
          return true;
        }
      }
      return false;
    } on FirebaseAuthException catch (e) {
      throw Exception('Google Sign-In failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during Google Sign-In: $e');
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }
}
