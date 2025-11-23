import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_de_vente.dart';
import '../models/collaborateur.dart';
import '../models/menu.dart';
import 'firebase_repository.dart';

class PointDeVenteRepository extends FirebaseRepository<PointDeVente> {
  @override
  String get collectionName => 'points_de_vente';

  @override
  PointDeVente fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle collaborateurs list - assuming stored as list of maps or IDs
    // For now, returning empty list as implementation details for sub-collections/references are not fully clear
    // TODO: Implement full hydration of collaborateurs
    final List<Collaborateur> collaborateurs = [];

    // Handle menu
    // TODO: Implement menu hydration
    final Menu? menu = null;

    return PointDeVente(
      id: data['id'] as int? ?? 0,
      nom: data['nom'] as String? ?? '',
      adresse: data['adresse'] as String? ?? '',
      horaires: data['horaires'] as String? ?? '',
      actif: data['actif'] as bool? ?? true,
      collaborateurs: collaborateurs,
      menu: menu,
      coordinateurId: data['coordinateurId'] as int?,
      collaborateurIds:
          (data['collaborateurIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toFirestore(PointDeVente item) {
    return {
      'id': item.id,
      'nom': item.nom,
      'adresse': item.adresse,
      'horaires': item.horaires,
      'actif': item.actif,
      'coordinateurId': item.coordinateurId,
      'collaborateurIds': item.collaborateurIds,
      // 'collaborateurs': item.collaborateurs.map((c) => c.id).toList(), // Example: storing IDs
      // 'menu': item.menu?.id, // Example: storing ID
    };
  }

  /// Update document by integer ID (field 'id')
  Future<void> updateByIntId(int id, PointDeVente item) async {
    final snapshot = await firestore
        .collection(collectionName)
        .where('id', isEqualTo: id)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;
      await update(docId, item);
    } else {
      throw Exception('PointDeVente with id $id not found');
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
