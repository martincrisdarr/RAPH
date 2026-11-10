import 'package:flutter/foundation.dart';

class ApiConfig {
  // En compilación de Producción (kReleaseMode == true) SIEMPRE usa baseUrlProd y socketUrlProd.
  // En Desarrollo (flutter run / debug), usa baseUrlLocal (http://localhost/RAPH/web).
  static const bool useLocalInDev = true;
  static const bool useLocalSocket = false;

  static const String baseUrlProd = 'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web';
  static const String baseUrlLocal = 'http://localhost/RAPH/web';

  static const String baseUrl = (!kReleaseMode && useLocalInDev)
      ? baseUrlLocal
      : baseUrlProd;

  static const String socketUrlProd = 'https://emergenciasyriesgos.neuquen.gov.ar/giro';
  static const String socketUrlLocal = 'http://localhost:3001';

  // Endpoint para servicios externos de Giro (Vehículos, Unidades, etc.)
  static const String giroApiBaseUrl = 'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web';
  static const String unidadesVehicularesUrl =
      '$giroApiBaseUrl/ser_veh_vie_unidad_despacho?filter[id_tipo_unidad]=11';

  static String get socketUrl => (!kReleaseMode && useLocalSocket)
      ? socketUrlLocal
      : socketUrlProd;

  ApiConfig._();
}
