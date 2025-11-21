import 'utilisateur.dart';
import 'enums.dart';

/// Coordinator user model
class Coordinateur extends Utilisateur {
  Coordinateur({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.motDePasse,
    required super.telephone,
    required super.dateInscription,
  }) : super(role: Role.coordinateur);

  /// Follow command preparation
  void suivrePreparationCommande() {
    // Implementation for following command preparation
  }

  @override
  String toString() =>
      'Coordinateur(id: $id, nom: $nom, prenom: $prenom, email: $email)';
}
