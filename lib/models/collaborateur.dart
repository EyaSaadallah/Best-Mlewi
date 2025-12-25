import 'utilisateur.dart';
import 'enums.dart';

/// Collaborator/Staff member model
class Collaborateur extends Utilisateur {
  Collaborateur({
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
  }) : super(role: Role.collaborateur);

  /// Activate availability
  void activerDisponibilite() {
    // Implementation for activating availability
  }

  /// Deactivate availability
  void desactiverDisponibilite() {
    // Implementation for deactivating availability
  }

  @override
  String toString() =>
      'Collaborateur(id: $id, nom: $nom, prenom: $prenom, email: $email)';
}
