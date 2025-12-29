import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notification.dart' as notif_model;
import '../models/enums.dart';
import '../repositories/notification_repository.dart';
import '../repositories/utilisateur_repository.dart';

/// Service for managing notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final NotificationRepository _repository = NotificationRepository();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'show_map' && response.payload != null) {
          final parts = response.payload!.split(',');
          if (parts.length == 2) {
            final lat = parts[0];
            final lng = parts[1];
            final url =
                'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        }
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'bestmlewi_channel', // id
      'BestMlewi Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    double? latitude,
    double? longitude,
  }) async {
    final bool hasLocation = latitude != null && longitude != null;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'bestmlewi_channel',
          'BestMlewi Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          actions: hasLocation
              ? <AndroidNotificationAction>[
                  const AndroidNotificationAction(
                    'show_map',
                    'Show on Map 📍',
                    showsUserInterface: true,
                    cancelNotification: false,
                  ),
                ]
              : null,
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: hasLocation ? '$latitude,$longitude' : null,
    );
  }

  /// Initialize FCM
  Future<void> initialize({int? userId}) async {
    // Initialize local notifications first
    await _initializeLocalNotifications();

    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get token
      String? token = await _fcm.getToken();
      print('FCM Token: $token');

      // Save token to Firestore if userId is provided
      if (userId != null && token != null) {
        try {
          final userRepo = UtilisateurRepository();
          await userRepo.updateFcmToken(userId, token);
          print('FCM Token saved to Firestore for user $userId');
        } catch (e) {
          print('Error saving FCM token: $e');
        }
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        if (userId != null) {
          try {
            final userRepo = UtilisateurRepository();
            await userRepo.updateFcmToken(userId, newToken);
          } catch (e) {
            print('Error updating refreshed FCM token: $e');
          }
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification?.title}',
          );

          // Show local notification with action button if lat/lng present
          _showLocalNotification(
            title: message.notification?.title ?? 'New Notification',
            body: message.notification?.body ?? '',
            latitude: double.tryParse(message.data['latitude'] ?? ''),
            longitude: double.tryParse(message.data['longitude'] ?? ''),
          );
        }
      });
    }
  }

  /// Get notifications stream for a user
  Stream<List<notif_model.Notification>> getUserNotifications(int userId) {
    return _repository.getUserNotifications(userId);
  }

  /// Get unread count stream
  Stream<int> getUnreadCount(int userId) {
    return _repository.getUnreadCount(userId);
  }

  /// Create new notification
  Future<void> createNotification({
    required int userId,
    required String message,
    required NotificationType type,
    double? latitude,
    double? longitude,
  }) async {
    final notification = notif_model.Notification(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      message: message,
      dateEnvoi: DateTime.now(),
      lu: false,
      type: type,
      latitude: latitude,
      longitude: longitude,
    );
    await _repository.create(notification);
  }

  /// Mark notification as read
  Future<void> markAsRead(int id) async {
    await _repository.markAsRead(id);
  }

  /// Delete notification
  Future<void> deleteNotification(int id) async {
    await _repository.delete(id);
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(int userId) async {
    await _repository.deleteAll(userId);
  }
}
