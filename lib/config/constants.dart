class AppConstants {
  // Pasar la clave en tiempo de compilación:
  // flutter build web --dart-define=GOOGLE_MAPS_API_KEY=tu_clave_aqui
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');
}
