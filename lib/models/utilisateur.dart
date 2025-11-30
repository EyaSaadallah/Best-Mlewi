import 'enums.dart';

/// Base user class for all system users
class Utilisateur {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;
  final String telephone;
  final DateTime dateInscription;
  final Role role;
  final bool isActive;
  final bool isAffected;
  final bool isAvailable;
  final String? fcmToken;
  final String? imageUrl;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    required this.telephone,
    required this.dateInscription,
    required this.role,
    this.isActive = true,
    this.isAffected = false,
    this.isAvailable = true,
    this.fcmToken,
    this.imageUrl,
  });

  /// Login with email and password
  bool login(String email, String motDePasse) {
    return this.email == email && this.motDePasse == motDePasse;
  }

  /// Logout user
  void logout() {
    // Implementation for logout
  }

  /// Subscribe to notifications
  void sInscrire() {
    // Implementation for subscription
  }

  @override
  String toString() =>
      'Utilisateur(id: $id, nom: $nom, prenom: $prenom, email: $email, role: $role)';
}
