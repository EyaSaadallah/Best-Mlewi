import '../models/utilisateur.dart';
import '../models/client.dart';

/// Authentication service for user login/logout
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Utilisateur? _currentUser;

  Utilisateur? get currentUser => _currentUser;

  /// Login user with email and password
  Future<bool> login(String email, String password) async {
    try {
      // TODO: Implement actual authentication logic with backend
      // This is a placeholder implementation
      _currentUser = Client(
        id: 1,
        nom: 'Test',
        prenom: 'User',
        email: email,
        motDePasse: password,
        telephone: '1234567890',
        dateInscription: DateTime.now(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout current user
  void logout() {
    _currentUser = null;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _currentUser != null;
  }
}
