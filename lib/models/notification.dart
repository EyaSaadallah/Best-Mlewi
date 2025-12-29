import 'enums.dart';

/// Notification model for system notifications
class Notification {
  final int id;
  final int userId;
  final String message;
  final DateTime dateEnvoi;
  final bool lu;
  final NotificationType type;

  final double? latitude;
  final double? longitude;

  Notification({
    required this.id,
    required this.userId,
    required this.message,
    required this.dateEnvoi,
    required this.lu,
    required this.type,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'message': message,
      'dateEnvoi': dateEnvoi.toIso8601String(),
      'lu': lu,
      'type': type.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? 0,
      userId: map['userId'] ?? 0,
      message: map['message'] ?? '',
      dateEnvoi: DateTime.parse(map['dateEnvoi']),
      lu: map['lu'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NotificationType.info,
      ),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  @override
  String toString() =>
      'Notification(id: $id, userId: $userId, message: $message, type: $type, lu: $lu)';
}
