import 'dart:convert';
import 'package:http/http.dart' as http;

class ListadosService {
  static const String _baseUrl =
      'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web';

  static const String _incidenteEndpoint =
      '$_baseUrl/ser_sien_dsp_incidente?expand=localidad,victimas,demanda_recibidas';

  static const String _demandaRecibidaEndpoint =
      '$_baseUrl/ser_sien_dsp_demanda_recibida?expand=estado,tipo_ingreso';

  static Future<List<Map<String, dynamic>>> obtenerIncidentes() async {
    final response = await http.get(Uri.parse(_incidenteEndpoint));

    if (response.statusCode != 200) {
      throw Exception('Error al cargar incidentes: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is List) {
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> obtenerDemandasRecibidas() async {
    final response = await http.get(Uri.parse(_demandaRecibidaEndpoint));

    if (response.statusCode != 200) {
      throw Exception('Error al cargar demandas recibidas: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is List) {
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> obtenerIncidentePorId(int idIncidente) async {
    final uri = Uri.parse(
      '$_baseUrl/ser_sien_dsp_incidente?filter%5Bidincidente%5D=$idIncidente',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error al cargar incidente $idIncidente: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, dynamic>.from(decoded.first as Map);
    }
    return null;
  }
}
