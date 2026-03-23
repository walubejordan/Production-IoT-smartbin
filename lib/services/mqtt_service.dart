// Facade that exports the right MQTT implementation per platform.
//
// On native (Android/iOS/desktop) we use `mqtt_service_io.dart` which relies on
// `mqtt_client` and dart:io. On web we export `mqtt_service_stub.dart`, which
// is a no-op implementation and does NOT touch dart:io or SecurityContext, so
// it is safe for Flutter web builds.
//
// Usage everywhere else:
//   import 'services/mqtt_service.dart';
//
// and then depend on the `MqttService` API; the correct implementation will
// be selected at compile time.
export 'mqtt_service_stub.dart' if (dart.library.io) 'mqtt_service_io.dart';

