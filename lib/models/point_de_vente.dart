import 'collaborateur.dart';
import 'menu.dart';

/// Sales point/Restaurant location model
class PointDeVente {
  final int id;
  final String nom;
  final String adresse;
  final String horaires;
  final bool actif;
  final List<Collaborateur> collaborateurs;
  final Menu? menu;
  final int? coordinateurId;
  final List<int> collaborateurIds;

  PointDeVente({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.horaires,
    required this.actif,
    required this.collaborateurs,
    this.menu,
    this.coordinateurId,
    this.collaborateurIds = const [],
  });

  /// Activate point of sale
  void activer() {
    // Implementation for activation
  }

  /// Deactivate point of sale
  void desactiver() {
    // Implementation for deactivation
  }

  @override
  String toString() =>
      'PointDeVente(id: $id, nom: $nom, adresse: $adresse, actif: $actif, coordinateurId: $coordinateurId)';
}
