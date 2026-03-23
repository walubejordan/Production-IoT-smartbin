import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class MqttService {
  MqttServerClient? client;
  String? userId;
  
  // Change this to your MQTT broker address.
  // In production, avoid localhost / 10.0.2.2 and point to your
  // internet‑reachable host instead.
  static const String broker = 'smartbin-backend-dng0.onrender.com';
  static const int port = 1883;
  
  // Callbacks
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(String, Map<String, dynamic>)? onBinStatusUpdate;
  
  Future<void> connect(String userId) async {
    this.userId = userId;
    client = MqttServerClient.withPort(broker, 'flutter_client_$userId', port);
    client!.logging(on: false);
    client!.keepAlivePeriod = 60;
    client!.onConnected = _onConnected;
    client!.onDisconnected = _onDisconnected;
    client!.onSubscribed = _onSubscribed;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_$userId')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    
    client!.connectionMessage = connMessage;
    
    try {
      await client!.connect();
    } catch (e) {
      print('MQTT Connection Error: $e');
      client!.disconnect();
    }
    
    // Subscribe to topics
    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      _subscribeToTopics();
      
      // Listen to messages
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage message = messages[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        final String topic = messages[0].topic;
        
        _handleMessage(topic, payload);
      });
    }
  }
  
  void _subscribeToTopics() {
    // Subscribe to user-specific notifications
    client!.subscribe('smartbin/notifications/$userId', MqttQos.atLeastOnce);
    
    // Subscribe to all bin status updates
    client!.subscribe('smartbin/bins/+/status', MqttQos.atLeastOnce);
    client!.subscribe('smartbin/bins/+/level', MqttQos.atLeastOnce);
  }
  
  void _handleMessage(String topic, String payload) {
    try {
      final Map<String, dynamic> data = json.decode(payload);
      
      if (topic.contains('notifications')) {
        if (onNotificationReceived != null) {
          onNotificationReceived!(data);
        }
      } else if (topic.contains('status') || topic.contains('level')) {
        if (onBinStatusUpdate != null) {
          onBinStatusUpdate!(topic, data);
        }
      }
    } catch (e) {
      print('Error parsing MQTT message: $e');
    }
  }
  
  void _onConnected() {
    print('MQTT Connected');
  }
  
  void _onDisconnected() {
    print('MQTT Disconnected');
  }
  
  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }
  
  void disconnect() {
    client?.disconnect();
  }
  
  void publish(String topic, Map<String, dynamic> message) {
    if (client == null || client!.connectionStatus!.state != MqttConnectionState.connected) {
      print('MQTT client not connected');
      return;
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(json.encode(message));
    client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}
