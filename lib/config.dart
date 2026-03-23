/// Application configuration values such as API keys, endpoints, etc.
///
/// **NOTE:** Never commit real API keys to a public repository. In a production
/// application these values should be supplied via secure build-time or
/// runtime configuration (flavors, environment variables, remote config,
/// etc.). For the purpose of this example we are keeping them in code.
library;

class AppConfig {
  /// Mapbox public access token (pk.*).
  /// TODO: Add your Mapbox API key from environment variables or secure config
  static const String mapboxApiKey = String.fromEnvironment(
    'MAPBOX_API_KEY',
    defaultValue: 'pk.YOUR_MAPBOX_KEY_HERE',
  );

  /// OpenRouteService API key.
  /// TODO: Add your OpenRouteService API key from environment variables or secure config
  static const String openRouteServiceKey = String.fromEnvironment(
    'OPENROUTE_SERVICE_KEY',
    defaultValue: 'YOUR_OPENROUTE_KEY_HERE',
  );
}
