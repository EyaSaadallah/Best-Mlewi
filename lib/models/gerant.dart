import 'utilisateur.dart';
import 'enums.dart';

/// Manager/Gerant user model
class Gerant extends Utilisateur {
  Gerant({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.motDePasse,
    required super.telephone,
    required super.dateInscription,
    super.isActive = true,
    super.isAffected = false,
    super.isAvailable = true,
  }) : super(role: Role.gerant);

  /// Consult system information
  void consulterSysteme() {
    // Implementation for consulting system
  }

  /// Affect a command
  void affecterCommande() {
    // Implementation for affecting command
  }

  /// Get sales points
  void obtenirPointsDeVente() {
    // Implementation for getting sales points
  }

  /// Get collaborators
  void obtenirCollaborateurs() {
    // Implementation for getting collaborators
  }

  @override
  String toString() =>
      'Gerant(id: $id, nom: $nom, prenom: $prenom, email: $email)';
}
