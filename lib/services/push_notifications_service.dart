import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep this function top-level so it can be invoked by the runtime.
  debugPrint('FCM background message: ${message.messageId}');
}

class PushNotificationsService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // iOS/macOS permission prompt (safe to call on all platforms)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
    });

    // App opened from terminated/background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM opened from notification: ${message.messageId}');
    });
  }

  Future<String?> getToken() async {
    try {
      const vapidKey = kIsWeb
          ? const String.fromEnvironment('FCM_VAPID_KEY', defaultValue: '')
          : null;

      if (kIsWeb && (vapidKey == null || vapidKey.isEmpty)) {
        debugPrint(
            '⚠️ FCM VAPID key not set. Pass --dart-define=FCM_VAPID_KEY=<your_key> when running web.');
      }

      return await _messaging.getToken(vapidKey: kIsWeb ? vapidKey : null);
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }
}
