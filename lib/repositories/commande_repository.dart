import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/commande.dart';
import '../models/ligne_commande.dart';
import '../models/plat.dart';
import '../models/livraison.dart';
import '../models/enums.dart';
import 'firebase_repository.dart';

/// Repository for managing Commande documents in Firestore
class CommandeRepository extends FirebaseRepository<Commande> {
  @override
  String get collectionName => 'commandes';

  /// Get commands by status
  Future<List<Commande>> getByStatus(StatusCommande status) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('statut', isEqualTo: status.name)
          .get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching commands by status: $e');
    }
  }

  /// Get commands by date range
  Future<List<Commande>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where(
            'dateCreation',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('dateCreation', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching commands by date range: $e');
    }
  }

  /// Update command status
  Future<void> updateStatus(String id, StatusCommande newStatus) async {
    try {
      await firestore.collection(collectionName).doc(id).update({
        'statut': newStatus.name,
      });
    } catch (e) {
      throw Exception('Error updating command status: $e');
    }
  }

  @override
  Commande fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse status
    final statusString = data['statut'] as String? ?? 'cree';
    final status = StatusCommande.values.firstWhere(
      (s) => s.name == statusString,
      orElse: () => StatusCommande.cree,
    );

    // Parse line items
    final lignesData = data['lignes'] as List<dynamic>? ?? [];
    final lignes = lignesData.map((l) {
      final ligneMap = l as Map<String, dynamic>;
      return LigneCommande(
        id: ligneMap['id'] as int? ?? 0,
        quantite: ligneMap['quantite'] as int? ?? 0,
        prixUnitaire: (ligneMap['prixUnitaire'] as num?)?.toDouble() ?? 0.0,
        sousTotal: (ligneMap['sousTotal'] as num?)?.toDouble() ?? 0.0,
        plat: Plat(
          id: ligneMap['plat']['id'] as int? ?? 0,
          nom: ligneMap['plat']['nom'] as String? ?? '',
          description: ligneMap['plat']['description'] as String? ?? '',
          prix: (ligneMap['plat']['prix'] as num?)?.toDouble() ?? 0.0,
          categorie: ligneMap['plat']['categorie'] as String? ?? '',
          disponible: ligneMap['plat']['disponible'] as bool? ?? false,
        ),
      );
    }).toList();

    // Parse delivery if exists
    Livraison? livraison;
    if (data['livraison'] != null) {
      final livraisonData = data['livraison'] as Map<String, dynamic>;
      livraison = Livraison(
        id: livraisonData['id'] as int? ?? 0,
        adresseLivraison: livraisonData['adresseLivraison'] as String? ?? '',
        dateHeureEstimee:
            (livraisonData['dateHeureEstimee'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        notes: livraisonData['notes'] as String?,
      );
    }

    return Commande(
      id: data['id'] as int? ?? 0,
      dateCreation:
          (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      statut: status,
      lignes: lignes,
      livraison: livraison,
    );
  }

  @override
  Map<String, dynamic> toFirestore(Commande commande) {
    return {
      'id': commande.id,
      'dateCreation': Timestamp.fromDate(commande.dateCreation),
      'total': commande.total,
      'statut': commande.statut.name,
      'lignes': commande.lignes
          .map(
            (l) => {
              'id': l.id,
              'quantite': l.quantite,
              'prixUnitaire': l.prixUnitaire,
              'sousTotal': l.sousTotal,
              'plat': {
                'id': l.plat.id,
                'nom': l.plat.nom,
                'description': l.plat.description,
                'prix': l.plat.prix,
                'categorie': l.plat.categorie,
                'disponible': l.plat.disponible,
              },
            },
          )
          .toList(),
      'livraison': commande.livraison != null
          ? {
              'id': commande.livraison!.id,
              'adresseLivraison': commande.livraison!.adresseLivraison,
              'dateHeureEstimee': Timestamp.fromDate(
                commande.livraison!.dateHeureEstimee,
              ),
              'notes': commande.livraison!.notes,
            }
          : null,
    };
  }
}
