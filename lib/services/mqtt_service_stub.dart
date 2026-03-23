import 'dart:async';

// Web-safe stub implementation of MqttService. The app can call the same
// methods but on web these are no-ops to avoid dart:io / SecurityContext errors.

class MqttService {
  // Keep the same public API as the io implementation
  String? userId;
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(String, Map<String, dynamic>)? onBinStatusUpdate;

  Future<void> connect(String userId) async {
    this.userId = userId;
    // No-op on web. If you need web MQTT, replace this with a web-compatible
    // client (e.g., MQTT over WebSockets) and implement accordingly.
    print('MQTT stub: connect called on web for user $userId — no-op');
    return Future.value();
  }

  void disconnect() {
    print('MQTT stub: disconnect called on web — no-op');
  }

  void publish(String topic, Map<String, dynamic> message) {
    print('MQTT stub: publish to $topic on web — no-op');
  }
}
