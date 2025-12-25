import 'utilisateur.dart';
import 'enums.dart';

/// Delivery person model
class Livreur extends Utilisateur {
  Livreur({
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
    super.imageUrl,
    super.adresse,
    super.latitude,
    super.longitude,
  }) : super(role: Role.livreur);

  /// Follow delivery
  void suivreLivraisonCommande() {
    // Implementation for following delivery
  }

  /// Modify delivery location
  void modifierEmplacement() {
    // Implementation for modifying delivery location
  }

  @override
  String toString() =>
      'Livreur(id: $id, nom: $nom, prenom: $prenom, email: $email)';
}
