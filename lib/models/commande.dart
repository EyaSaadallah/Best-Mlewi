import 'enums.dart';
import 'ligne_commande.dart';

/// Command/Order model
class Commande {
  final int id;
  final DateTime dateCreation;
  final double total;
  final double totalWithTax;
  final StatusCommande statut;
  final List<LigneCommande> lignes;
  final int? livreurId;
  final int? posId;
  final int? clientId;
  final int? estimationPreparation; // In minutes
  final String? adresse;
  final double? latitude;
  final double? longitude;

  Commande({
    required this.id,
    required this.dateCreation,
    required this.total,
    required this.totalWithTax,
    required this.statut,
    required this.lignes,
    this.livreurId,
    this.posId,
    this.clientId,
    this.estimationPreparation,
    this.adresse,
    this.latitude,
    this.longitude,
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

  Commande copyWith({
    int? id,
    DateTime? dateCreation,
    double? total,
    double? totalWithTax,
    StatusCommande? statut,
    List<LigneCommande>? lignes,
    int? livreurId,
    int? posId,
    int? clientId,
    int? estimationPreparation,
    String? adresse,
    double? latitude,
    double? longitude,
  }) {
    return Commande(
      id: id ?? this.id,
      dateCreation: dateCreation ?? this.dateCreation,
      total: total ?? this.total,
      totalWithTax: totalWithTax ?? this.totalWithTax,
      statut: statut ?? this.statut,
      lignes: lignes ?? this.lignes,
      livreurId: livreurId ?? this.livreurId,
      posId: posId ?? this.posId,
      clientId: clientId ?? this.clientId,
      estimationPreparation:
          estimationPreparation ?? this.estimationPreparation,
      adresse: adresse ?? this.adresse,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() =>
      'Commande(id: $id, dateCreation: $dateCreation, total: $total, statut: $statut)';
}
