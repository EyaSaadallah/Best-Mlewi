import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'notifications',
  );

  /// Create a new notification
  Future<void> create(Notification notification) async {
    await _collection.doc(notification.id.toString()).set(notification.toMap());
  }

  /// Get notifications for a specific user
  Stream<List<Notification>> getUserNotifications(int userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('dateEnvoi', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Notification.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    await _collection.doc(notificationId.toString()).update({'lu': true});
  }

  /// Delete a notification
  Future<void> delete(int notificationId) async {
    await _collection.doc(notificationId.toString()).delete();
  }

  /// Get unread count stream
  Stream<int> getUnreadCount(int userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('lu', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete all notifications for a user
  Future<void> deleteAll(int userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await _collection.where('userId', isEqualTo: userId).get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
