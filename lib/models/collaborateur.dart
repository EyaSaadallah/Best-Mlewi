import 'utilisateur.dart';
import 'enums.dart';

/// Collaborator/Staff member model
class Collaborateur extends Utilisateur {
  Collaborateur({
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
         role: Role.collaborateur,
         isActive: isActive,
         isAffected: isAffected,
         isAvailable: isAvailable,
       );

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
