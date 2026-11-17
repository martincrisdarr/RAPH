class AppConstants {
  // Usa la clave definida acá por defecto, o permite sobreescribirla con --dart-define=GOOGLE_MAPS_API_KEY=...
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCqC_WkaTtG03jrH9XDy-B9Tzk5C_8stOw',
  );
}
