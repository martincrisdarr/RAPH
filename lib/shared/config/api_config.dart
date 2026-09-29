class ApiConfig {
  static const String baseUrl = 'http://localhost/RAPH/web';
  // Cambiar a false cuando el endpoint esté disponible en producción
  static const bool useLocalSocket = true;
  static const String socketUrlProd = 'https://emergenciasyriesgos.neuquen.gov.ar/giro';
  static const String socketUrlLocal = 'http://localhost:3001';

  // Endpoint para servicios externos de Giro (Vehículos, Unidades, etc.)
  static const String giroApiBaseUrl = 'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web';
  static const String unidadesVehicularesUrl =
      '$giroApiBaseUrl/ser_veh_vie_unidad_despacho?filter[id_tipo_unidad]=11';

  static String get socketUrl => useLocalSocket ? socketUrlLocal : socketUrlProd;

  ApiConfig._();
}

