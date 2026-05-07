import 'dart:convert';
import 'package:http/http.dart' as http;

class ListadosService {
  static const String _baseUrl =
      'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web';

  static const String _demandaRecibidaEndpoint =
      '$_baseUrl/ser_sien_dsp_demanda_recibida?expand=estado,tipo_ingreso';

  static const String _llamadaEndpoint =
      '$_baseUrl/ser_sien_dsp_llamada';

  static Future<List<Map<String, dynamic>>> obtenerLlamadas() async {
    try {
      final response = await http.get(Uri.parse(_llamadaEndpoint));
      if (response.statusCode != 200) {
        throw Exception('Error al cargar llamadas: ${response.statusCode}');
      }
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error en obtenerLlamadas: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerDemandasRecibidas() async {
    try {
      final response = await http.get(Uri.parse(_demandaRecibidaEndpoint));

      if (response.statusCode != 200) {
        throw Exception('Error al cargar demandas recibidas: ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error en obtenerDemandasRecibidas: $e');
      rethrow;
    }
  }
}
