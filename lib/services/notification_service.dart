import '../models/notification.dart' as notif_model;
import '../models/enums.dart';

/// Service for managing notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final List<notif_model.Notification> _notifications = [];

  /// Get all notifications
  List<notif_model.Notification> getNotifications() {
    return _notifications;
  }

  /// Get unread notifications
  List<notif_model.Notification> getUnreadNotifications() {
    return _notifications.where((n) => !n.lu).toList();
  }

  /// Create new notification
  void createNotification(int id, String message, NotificationType type) {
    final notification = notif_model.Notification(
      id: id,
      message: message,
      dateEnvoi: DateTime.now(),
      lu: false,
      type: type,
    );
    _notifications.add(notification);
    notification.envoyer();
  }

  /// Mark notification as read
  void markAsRead(int id) {
    try {
      final notification = _notifications.firstWhere((n) => n.id == id);
      // Create new notification with lu=true since it's final
      _notifications.remove(notification);
      _notifications.add(
        notif_model.Notification(
          id: notification.id,
          message: notification.message,
          dateEnvoi: notification.dateEnvoi,
          lu: true,
          type: notification.type,
        ),
      );
    } catch (e) {
      // Notification not found
    }
  }

  /// Delete notification
  void deleteNotification(int id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
  }
}
