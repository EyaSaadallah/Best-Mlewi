/// Delivery model
class Livraison {
  final int id;
  final String adresseLivraison;
  final DateTime dateHeureEstimee;
  final String? notes;

  Livraison({
    required this.id,
    required this.adresseLivraison,
    required this.dateHeureEstimee,
    this.notes,
  });

  /// Modify delivery address
  void modifierEmplacement(String nouvelleAdresse) {
    // Implementation for modifying address
  }

  /// Track delivery position
  void suivrePosistions() {
    // Implementation for tracking positions
  }

  @override
  String toString() =>
      'Livraison(id: $id, adresse: $adresseLivraison, dateEstimee: $dateHeureEstimee)';
}
