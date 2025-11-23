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
          .where('isActive', isEqualTo: true)
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
      isActive: data['isActive'] as bool? ?? true,
      isAffected: data['isAffected'] as bool? ?? false,
      isAvailable: data['isAvailable'] as bool? ?? true,
      fcmToken: data['fcmToken'] as String?,
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
          isActive: baseUser.isActive,
          isAffected: baseUser.isAffected,
          isAvailable: baseUser.isAvailable,
          adresse: data['adresse'] as String?,
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
          isActive: baseUser.isActive,
          isAffected: baseUser.isAffected,
          isAvailable: baseUser.isAvailable,
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
          isActive: baseUser.isActive,
          isAffected: baseUser.isAffected,
          isAvailable: baseUser.isAvailable,
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
          isActive: baseUser.isActive,
          isAffected: baseUser.isAffected,
          isAvailable: baseUser.isAvailable,
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
          isActive: baseUser.isActive,
          isAffected: baseUser.isAffected,
          isAvailable: baseUser.isAvailable,
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
          isActive: baseUser.isActive,
          isAffected: baseUser.isAffected,
          isAvailable: baseUser.isAvailable,
        );
    }
  }

  @override
  Map<String, dynamic> toFirestore(Utilisateur user) {
    final data = {
      'id': user.id,
      'nom': user.nom,
      'prenom': user.prenom,
      'email': user.email,
      'motDePasse': user.motDePasse,
      'telephone': user.telephone,
      'dateInscription': Timestamp.fromDate(user.dateInscription),
      'role': user.role.name,
      'isActive': user.isActive,
      'isAffected': user.isAffected,
      'isAvailable': user.isAvailable,
      'fcmToken': user.fcmToken,
    };

    // Add address field if user is a Client
    if (user is Client) {
      data['adresse'] = user.adresse;
    }

    return data;
  }

  /// Update user by internal ID
  Future<void> updateUser(Utilisateur user) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('id', isEqualTo: user.id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update(toFirestore(user));
      } else {
        throw Exception('User not found with id: ${user.id}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// Delete user by internal ID
  Future<void> deleteUser(int id) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Soft delete: set isActive to false
        await snapshot.docs.first.reference.update({'isActive': false});
      } else {
        throw Exception('User not found with id: $id');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  /// Update user's isAffected status
  Future<void> updateIsAffected(int id, bool isAffected) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({'isAffected': isAffected});
      } else {
        throw Exception('User not found with id: $id');
      }
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  /// Update user's isAvailable status
  Future<void> updateIsAvailable(int id, bool isAvailable) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'isAvailable': isAvailable,
        });
      } else {
        throw Exception('User not found with id: $id');
      }
    } catch (e) {
      throw Exception('Error updating user availability: $e');
    }
  }

  /// Update user's FCM token
  Future<void> updateFcmToken(int id, String? token) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({'fcmToken': token});
      } else {
        throw Exception('User not found with id: $id');
      }
    } catch (e) {
      throw Exception('Error updating FCM token: $e');
    }
  }
}
