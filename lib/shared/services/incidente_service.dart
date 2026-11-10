import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/incidente.dart';
import '../../config/auth_controller.dart';

class IncidenteService {
  static const String _baseUrl = '${ApiConfig.baseUrl}/ser_sien_dsp_incidente';

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
      final body = jsonEncode(incidente.toJson());
      print('[IncidenteService] PUT ${incidente.idIncidente} -> $body');
      final response = await http.put(
        Uri.parse('$_baseUrl/${incidente.idIncidente}'),
        headers: _getHeaders(),
        body: body,
      );
      print('[IncidenteService] PUT response ${response.statusCode}: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Excepcion en actualizarIncidente: $e');
      return false;
    }
  }

  /// Cierra el incidente general guardando el reporte_cierre en ser_sien_dsp_incidente.
  static Future<bool> cerrarIncidente({
    required int idIncidente,
    required String reporte,
    String? usuario,
  }) async {
    try {
      final body = jsonEncode({
        'reporte_cierre': reporte,
        'reporte': reporte,
        'estado_cierre': 'cerrado',
        'usuario_cierre': usuario ?? RaphAuthController.instance.currentUsername,
      });
      final response = await http.post(
        Uri.parse('$_baseUrl/$idIncidente/cerrar'),
        headers: _getHeaders(),
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return true;
      }
      // Fallback via PUT al recurso del incidente
      final putResponse = await http.put(
        Uri.parse('$_baseUrl/$idIncidente'),
        headers: _getHeaders(),
        body: body,
      );
      if (putResponse.statusCode == 200 || putResponse.statusCode == 204) {
        return true;
      }
      print('[IncidenteService] Error en cerrarIncidente (${response.statusCode}): ${response.body}');
      return false;
    } catch (e) {
      print('[IncidenteService] Excepcion en cerrarIncidente: $e');
      return false;
    }
  }

  static Future<Incidente?> obtenerPorId(int idIncidente) async {
    try {
      final urlStr = '$_baseUrl/$idIncidente?expand=ultimoEstadoRel.estadoRel,victimas.persona,victimas.persona_sin_dni,victimas.despachos.movilunidad,victimas.cierre,novedades,despachos.movilunidad.movil';
      final response = await http.get(Uri.parse(urlStr), headers: _getHeaders());

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        final data = raw is Map && raw.containsKey('data') ? raw['data'] : raw;
        return Incidente.fromJson(data);
      }
      return null;
    } catch (e) {
      print('[IncidenteService] Error en obtenerPorId: $e');
      return null;
    }
  }
}
