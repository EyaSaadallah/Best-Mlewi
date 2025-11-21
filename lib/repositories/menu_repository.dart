import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu.dart';
import '../models/plat.dart';
import 'firebase_repository.dart';

/// Repository for managing Menu documents in Firestore
class MenuRepository extends FirebaseRepository<Menu> {
  @override
  String get collectionName => 'menus';

  /// Get menu by title
  Future<Menu?> getByTitle(String titre) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('titre', isEqualTo: titre)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching menu by title: $e');
    }
  }

  /// Get available dishes from menu
  Future<List<Plat>> getAvailableDishes(String menuId) async {
    try {
      final doc = await firestore.collection(collectionName).doc(menuId).get();
      if (doc.exists) {
        final menu = fromFirestore(doc);
        return menu.getPlatDisponibles();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching available dishes: $e');
    }
  }

  @override
  Menu fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final platsData = data['plats'] as List<dynamic>? ?? [];
    final plats = platsData.map((p) {
      final platMap = p as Map<String, dynamic>;
      return Plat(
        id: platMap['id'] as int? ?? 0,
        nom: platMap['nom'] as String? ?? '',
        description: platMap['description'] as String? ?? '',
        prix: (platMap['prix'] as num?)?.toDouble() ?? 0.0,
        categorie: platMap['categorie'] as String? ?? '',
        disponible: platMap['disponible'] as bool? ?? false,
      );
    }).toList();

    return Menu(
      id: data['id'] as int? ?? 0,
      titre: data['titre'] as String? ?? '',
      plats: plats,
    );
  }

  @override
  Map<String, dynamic> toFirestore(Menu menu) {
    return {
      'id': menu.id,
      'titre': menu.titre,
      'plats': menu.plats
          .map(
            (p) => {
              'id': p.id,
              'nom': p.nom,
              'description': p.description,
              'prix': p.prix,
              'categorie': p.categorie,
              'disponible': p.disponible,
            },
          )
          .toList(),
    };
  }

  /// Update document by integer ID (field 'id')
  Future<void> updateByIntId(int id, Menu item) async {
    final snapshot = await firestore
        .collection(collectionName)
        .where('id', isEqualTo: id)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;
      await update(docId, item);
    } else {
      throw Exception('Menu with id $id not found');
    }
  }

  /// Delete document by integer ID (field 'id')
  Future<void> deleteByIntId(int id) async {
    final snapshot = await firestore
        .collection(collectionName)
        .where('id', isEqualTo: id)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;
      await delete(docId);
    }
  }
}
