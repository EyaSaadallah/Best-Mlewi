import 'plat.dart';

/// Menu model containing dishes
class Menu {
  final int id;
  final String titre;
  final List<Plat> plats;

  Menu({required this.id, required this.titre, required this.plats});

  /// Add a dish to menu
  void ajouterPlat(Plat plat) {
    plats.add(plat);
  }

  /// Remove a dish from menu
  void supprimerPlat(Plat plat) {
    plats.remove(plat);
  }

  /// Get available dishes
  List<Plat> getPlatDisponibles() {
    return plats.where((p) => p.disponible).toList();
  }

  @override
  String toString() => 'Menu(id: $id, titre: $titre, plats: ${plats.length})';
}
