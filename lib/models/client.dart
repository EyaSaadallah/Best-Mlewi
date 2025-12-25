import 'utilisateur.dart';
import 'enums.dart';

/// Client user model
class Client extends Utilisateur {
  Client({
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
    super.adresse,
    super.latitude,
    super.longitude,
    super.imageUrl,
  }) : super(role: Role.client);

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
      'Client(id: $id, nom: $nom, prenom: $prenom, email: $email, adresse: $adresse, lat: $latitude, lng: $longitude)';
}
