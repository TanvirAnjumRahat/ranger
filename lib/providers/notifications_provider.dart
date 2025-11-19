import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationService _service;
  String? _error;
  String? get error => _error;
  bool _motivationSubscribed = true;
  bool get motivationSubscribed => _motivationSubscribed;

  NotificationsProvider({NotificationService? service})
    : _service = service ?? NotificationService();

  Future<void> initialize() async {
    try {
      await _service.initialize();
      // Request notification permissions immediately after initialization
      await _service.requestPermissions();
    } catch (e) {
      _error = 'Notifications init failed: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> requestPermissions() async {
    await _service.requestPermissions();
  }

  Future<void> initializeFCM({bool subscribeMotivation = true}) async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission(alert: true, badge: true, sound: true);
    await fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _motivationSubscribed = subscribeMotivation;
    if (_motivationSubscribed) {
      await FirebaseMessaging.instance.subscribeToTopic('motivation');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('motivation');
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Surface a simple in-app indicator; app-specific UI can be added.
      // For now, we no-op to avoid tight UI coupling here.
    });
    notifyListeners();
  }

  Future<void> setMotivationSubscribed(bool value) async {
    _motivationSubscribed = value;
    if (value) {
      await FirebaseMessaging.instance.subscribeToTopic('motivation');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('motivation');
    }
    notifyListeners();
  }
}
