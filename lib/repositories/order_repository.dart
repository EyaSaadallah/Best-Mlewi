import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/commande.dart';
import '../models/ligne_commande.dart';
import '../models/plat.dart';
import '../models/enums.dart';
import 'firebase_repository.dart';

/// Repository for managing Commande documents in Firestore
class OrderRepository extends FirebaseRepository<Commande> {
  @override
  String get collectionName => 'commandes';

  /// Create order with client ID
  Future<String> createOrderWithClientId(Commande order, int clientId) async {
    try {
      final orderData = toFirestore(order);
      orderData['clientId'] = clientId;
      orderData['createdAt'] = FieldValue.serverTimestamp();

      final doc = await firestore.collection(collectionName).add(orderData);
      return doc.id;
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  /// Get next order ID by counting existing orders for a specific client
  Future<int> getNextOrderId(int clientId) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('clientId', isEqualTo: clientId)
          .get();

      // The next order ID is simply the count of existing orders + 1
      // This ensures each client starts from 1 and increments properly
      return snapshot.docs.length + 1;
    } catch (e) {
      throw Exception('Error getting next order ID: $e');
    }
  }

  /// Get orders by client ID
  Future<List<Commande>> getOrdersByClientId(int clientId) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('clientId', isEqualTo: clientId)
          .get();

      // Sort in memory instead of in Firestore to avoid index requirement
      final orders = snapshot.docs.map((doc) => fromFirestore(doc)).toList();
      orders.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));

      return orders;
    } catch (e) {
      throw Exception('Error fetching orders by client ID: $e');
    }
  }

  /// Get orders by status
  Future<List<Commande>> getByStatus(StatusCommande status) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('statut', isEqualTo: status.name)
          .orderBy('dateCreation', descending: true)
          .get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching orders by status: $e');
    }
  }

  /// Get orders by client ID and status
  Future<List<Commande>> getOrdersByClientIdAndStatus(
    int clientId,
    StatusCommande status,
  ) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('clientId', isEqualTo: clientId)
          .where('statut', isEqualTo: status.name)
          .orderBy('dateCreation', descending: true)
          .get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  /// Update order status
  Future<void> updateStatus(String id, StatusCommande newStatus) async {
    try {
      await firestore.collection(collectionName).doc(id).update({
        'statut': newStatus.name,
      });
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  /// Update order by internal ID
  Future<void> updateOrder(Commande order) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('id', isEqualTo: order.id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update(toFirestore(order));
      } else {
        throw Exception('Order not found with id: ${order.id}');
      }
    } catch (e) {
      throw Exception('Error updating order: $e');
    }
  }

  @override
  Commande fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse status
    final statusString = data['statut'] as String? ?? 'created';
    final status = StatusCommande.values.firstWhere(
      (s) => s.name == statusString,
      orElse: () => StatusCommande.created,
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
          imageUrl: ligneMap['plat']['imageUrl'] as String? ?? '',
        ),
      );
    }).toList();

    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
    final totalWithTax = (data['totalWithTax'] as num?)?.toDouble();

    // If totalWithTax is null, calculate it from total
    final finalTotalWithTax =
        totalWithTax ?? (total + (total * 0.05) + (total * 0.1));

    return Commande(
      id: data['id'] as int? ?? 0,
      dateCreation:
          (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: total,
      totalWithTax: finalTotalWithTax,
      statut: status,
      lignes: lignes,
      livreurId: data['livreurId'] as int?,
      posId: data['posId'] as int?,
    );
  }

  @override
  Map<String, dynamic> toFirestore(Commande order) {
    return {
      'id': order.id,
      'dateCreation': Timestamp.fromDate(order.dateCreation),
      'total': order.total,
      'totalWithTax': order.totalWithTax,
      'statut': order.statut.name,
      'lignes': order.lignes
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
                'imageUrl': l.plat.imageUrl,
              },
            },
          )
          .toList(),
      'livreurId': order.livreurId,
      'posId': order.posId,
    };
  }
}
