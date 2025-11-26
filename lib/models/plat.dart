/// Dish/Plate model
class Plat {
  final int id;
  final String nom;
  final String description;
  final double prix;
  final String categorie;
  final bool disponible;
  final String imageUrl;

  Plat({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.categorie,
    required this.disponible,
    required this.imageUrl,
  });

  /// Change availability status
  void changerDisponibilite(bool disponible) {
    // Implementation for changing availability
  }

  /// Update price
  void mettreAJourPrix(double prix) {
    // Implementation for updating price
  }

  @override
  String toString() =>
      'Plat(id: $id, nom: $nom, prix: $prix, disponible: $disponible)';
}
