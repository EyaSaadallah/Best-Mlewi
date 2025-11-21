import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/utilisateur.dart';
import '../models/client.dart';
import '../models/gerant.dart';
import '../models/coordinateur.dart';
import '../models/livreur.dart';
import '../models/collaborateur.dart';
import '../models/visiteur.dart';
import '../models/enums.dart';
import 'firebase_repository.dart';

/// Repository for managing Utilisateur documents in Firestore
class UtilisateurRepository extends FirebaseRepository<Utilisateur> {
  @override
  String get collectionName => 'utilisateurs';

  /// Get user by email
  Future<Utilisateur?> getByEmail(String email) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user by email: $e');
    }
  }

  /// Create user with specific role
  Future<String> createWithRole(Utilisateur user, Role role) async {
    try {
      final userData = toFirestore(user);
      userData['role'] = role.name;
      final doc = await firestore.collection(collectionName).add(userData);
      return doc.id;
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Get users by role
  Future<List<Utilisateur>> getByRole(Role role) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('role', isEqualTo: role.name)
          .get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching users by role: $e');
    }
  }

  @override
  Utilisateur fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final roleString = data['role'] as String? ?? 'visiteur';
    final role = Role.values.firstWhere(
      (r) => r.name == roleString,
      orElse: () => Role.visiteur,
    );

    final baseUser = Utilisateur(
      id: data['id'] as int? ?? 0,
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      email: data['email'] as String? ?? '',
      motDePasse: data['motDePasse'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      dateInscription:
          (data['dateInscription'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: role,
    );

    // Return appropriate user type based on role
    switch (role) {
      case Role.client:
        return Client(
          id: baseUser.id,
          nom: baseUser.nom,
          prenom: baseUser.prenom,
          email: baseUser.email,
          motDePasse: baseUser.motDePasse,
          telephone: baseUser.telephone,
          dateInscription: baseUser.dateInscription,
        );
      case Role.gerant:
        return Gerant(
          id: baseUser.id,
          nom: baseUser.nom,
          prenom: baseUser.prenom,
          email: baseUser.email,
          motDePasse: baseUser.motDePasse,
          telephone: baseUser.telephone,
          dateInscription: baseUser.dateInscription,
        );
      case Role.coordinateur:
        return Coordinateur(
          id: baseUser.id,
          nom: baseUser.nom,
          prenom: baseUser.prenom,
          email: baseUser.email,
          motDePasse: baseUser.motDePasse,
          telephone: baseUser.telephone,
          dateInscription: baseUser.dateInscription,
        );
      case Role.livreur:
        return Livreur(
          id: baseUser.id,
          nom: baseUser.nom,
          prenom: baseUser.prenom,
          email: baseUser.email,
          motDePasse: baseUser.motDePasse,
          telephone: baseUser.telephone,
          dateInscription: baseUser.dateInscription,
        );
      case Role.collaborateur:
        return Collaborateur(
          id: baseUser.id,
          nom: baseUser.nom,
          prenom: baseUser.prenom,
          email: baseUser.email,
          motDePasse: baseUser.motDePasse,
          telephone: baseUser.telephone,
          dateInscription: baseUser.dateInscription,
        );
      case Role.visiteur:
        return Visiteur(
          id: baseUser.id,
          nom: baseUser.nom,
          prenom: baseUser.prenom,
          email: baseUser.email,
          motDePasse: baseUser.motDePasse,
          telephone: baseUser.telephone,
          dateInscription: baseUser.dateInscription,
        );
    }
  }

  @override
  Map<String, dynamic> toFirestore(Utilisateur user) {
    return {
      'id': user.id,
      'nom': user.nom,
      'prenom': user.prenom,
      'email': user.email,
      'motDePasse': user.motDePasse,
      'telephone': user.telephone,
      'dateInscription': Timestamp.fromDate(user.dateInscription),
      'role': user.role.name,
    };
  }
}
