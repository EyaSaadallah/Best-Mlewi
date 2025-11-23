import 'utilisateur.dart';
import 'enums.dart';

/// Client user model
class Client extends Utilisateur {
  Client({
    required int id,
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String telephone,
    required DateTime dateInscription,
    bool isActive = true,
    bool isAffected = false,
    bool isAvailable = true,
  }) : super(
         id: id,
         nom: nom,
         prenom: prenom,
         email: email,
         motDePasse: motDePasse,
         telephone: telephone,
         dateInscription: dateInscription,
         role: Role.client,
         isActive: isActive,
         isAffected: isAffected,
         isAvailable: isAvailable,
       );

  /// Consult menu
  void consulterMenu() {
    // Implementation for consulting menu
  }

  /// Place a command
  void passerCommande() {
    // Implementation for placing command
  }

  /// Check command status
  void consulterEtatCommande() {
    // Implementation for checking command status
  }

  /// Cancel a command
  void annulerCommande() {
    // Implementation for canceling command
  }

  @override
  String toString() =>
      'Client(id: $id, nom: $nom, prenom: $prenom, email: $email)';
}
