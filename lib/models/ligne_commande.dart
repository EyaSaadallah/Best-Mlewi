import 'plat.dart';

/// Line item in a command
class LigneCommande {
  final int id;
  final int quantite;
  final double prixUnitaire;
  final double sousTotal;
  final Plat plat;

  LigneCommande({
    required this.id,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotal,
    required this.plat,
  });

  /// Calculate total for this line
  double calculerSousTotal() {
    return quantite * prixUnitaire;
  }

  @override
  String toString() =>
      'LigneCommande(id: $id, plat: ${plat.nom}, quantite: $quantite, sousTotal: $sousTotal)';
}
