import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/incidente.dart';
import '../../config/auth_controller.dart';

class IncidenteService {
  static const String _baseUrl = 'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/ser_sien_dsp_incidente';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Incidente?> crear(Incidente incidente) async {
    try {
      final body = jsonEncode(incidente.toJson());
      print('[IncidenteService] POST -> $body');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: body,
      );

      print('[IncidenteService] POST response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = jsonDecode(response.body);
        // Algunos backends envuelven la respuesta en { "data": {...} }
        final data = raw is Map && raw.containsKey('data') ? raw['data'] : raw;
        final creado = Incidente.fromJson(data);
        print('[IncidenteService] idIncidente recibido: ${creado.idIncidente}');
        return creado;
      } else {
        print('[IncidenteService] Error al crear incidente: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('[IncidenteService] Excepcion en crear: $e');
      return null;
    }
  }

  static Future<bool> actualizar(Incidente incidente) async {
    if (incidente.idIncidente == null) return false;
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${incidente.idIncidente}'),
        headers: _getHeaders(),
        body: jsonEncode(incidente.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        // Fallback
        final responseFallback = await http.put(
          Uri.parse(_baseUrl),
          headers: _getHeaders(),
          body: jsonEncode(incidente.toJson()),
        );
        return responseFallback.statusCode == 200 || responseFallback.statusCode == 204;
      }
    } catch (e) {
      print('Excepcion en actualizarIncidente: $e');
      return false;
    }
  }
}
