import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateUsers() async {
    try {
      final collection = _firestore.collection('utilisateurs');
      final snapshot = await collection.get();

      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final Map<String, dynamic> updates = {};

        if (!data.containsKey('isAvailable')) {
          updates['isAvailable'] = true;
        }

        if (!data.containsKey('isAffected')) {
          updates['isAffected'] = false;
        }

        if (updates.isNotEmpty) {
          await doc.reference.update(updates);
          updatedCount++;
        }
      }

      print('Migration completed. Updated $updatedCount documents.');
    } catch (e) {
      print('Error during migration: $e');
      throw e;
    }
  }
}
