import 'enums.dart';
import 'ligne_commande.dart';
import 'livraison.dart';

/// Command/Order model
class Commande {
  final int id;
  final DateTime dateCreation;
  final double total;
  final StatusCommande statut;
  final List<LigneCommande> lignes;
  final Livraison? livraison;

  Commande({
    required this.id,
    required this.dateCreation,
    required this.total,
    required this.statut,
    required this.lignes,
    this.livraison,
  });

  /// Add line item to command
  void ajouterLigne(LigneCommande ligne) {
    lignes.add(ligne);
  }

  /// Remove line item from command
  void supprimerLigne(LigneCommande ligne) {
    lignes.remove(ligne);
  }

  /// Change command status
  void changerStatut(StatusCommande nouveauStatut) {
    // Implementation for changing status
  }

  /// Calculate total
  double calculerTotal() {
    return lignes.fold(0, (sum, ligne) => sum + ligne.sousTotal);
  }

  @override
  String toString() =>
      'Commande(id: $id, dateCreation: $dateCreation, total: $total, statut: $statut)';
}
