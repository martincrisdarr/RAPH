import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/auth_controller.dart';

class ListadosService {
  static const String _baseUrl =
      'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web';

  static const String _demandaRecibidaEndpoint =
      '$_baseUrl/ser_sien_dsp_demanda_recibida?expand=estado,tipo_ingreso,incidente,incidente.victimas,incidente.novedades';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<Map<String, dynamic>>> obtenerDemandasRecibidas() async {
    try {
      final response = await http.get(
        Uri.parse(_demandaRecibidaEndpoint),
        headers: _getHeaders(),
      );

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
