import 'utilisateur.dart';
import 'enums.dart';

/// Visitor user model
class Visiteur extends Utilisateur {
  Visiteur({
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
  }) : super(role: Role.visiteur);

  @override
  String toString() =>
      'Visiteur(id: $id, nom: $nom, prenom: $prenom, email: $email)';
}
