import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Base Firebase repository for common operations
abstract class FirebaseRepository<T> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get collectionName;

  /// Get all documents from collection
  Future<List<T>> getAll() async {
    try {
      final snapshot = await firestore.collection(collectionName).get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching $collectionName: $e');
    }
  }

  /// Get document by ID
  Future<T?> getById(String id) async {
    try {
      final doc = await firestore.collection(collectionName).doc(id).get();
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching $collectionName with id $id: $e');
    }
  }

  /// Create document
  Future<String> create(T item) async {
    try {
      final doc = await firestore
          .collection(collectionName)
          .add(toFirestore(item));
      return doc.id;
    } catch (e) {
      throw Exception('Error creating $collectionName: $e');
    }
  }

  /// Update document
  Future<void> update(String id, T item) async {
    try {
      await firestore
          .collection(collectionName)
          .doc(id)
          .update(toFirestore(item));
    } catch (e) {
      throw Exception('Error updating $collectionName: $e');
    }
  }

  /// Delete document
  Future<void> delete(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting $collectionName: $e');
    }
  }

  /// Query documents
  Future<List<T>> query(String field, dynamic value) async {
    try {
      final snapshot = await firestore
          .collection(collectionName)
          .where(field, isEqualTo: value)
          .get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error querying $collectionName: $e');
    }
  }

  /// Convert Firestore document to model
  T fromFirestore(DocumentSnapshot doc);

  /// Convert model to Firestore document
  Map<String, dynamic> toFirestore(T item);
}
