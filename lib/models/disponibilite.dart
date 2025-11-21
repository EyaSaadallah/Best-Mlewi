/// Availability model for collaborators
class Disponibilite {
  final int id;
  final String titre;
  final DateTime dateDebut;
  final DateTime dateFin;
  final bool actif;

  Disponibilite({
    required this.id,
    required this.titre,
    required this.dateDebut,
    required this.dateFin,
    required this.actif,
  });

  /// Activate availability
  void activer() {
    // Implementation for activation
  }

  /// Deactivate availability
  void desactiver() {
    // Implementation for deactivation
  }

  @override
  String toString() => 'Disponibilite(id: $id, titre: $titre, actif: $actif)';
}
