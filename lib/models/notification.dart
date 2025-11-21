import 'enums.dart';

/// Notification model for system notifications
class Notification {
  final int id;
  final String message;
  final DateTime dateEnvoi;
  final bool lu;
  final NotificationType type;

  Notification({
    required this.id,
    required this.message,
    required this.dateEnvoi,
    required this.lu,
    required this.type,
  });

  /// Send notification
  void envoyer() {
    // Implementation for sending notification
  }

  @override
  String toString() =>
      'Notification(id: $id, message: $message, type: $type, lu: $lu)';
}
