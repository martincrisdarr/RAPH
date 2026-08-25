import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';

class ListadosService {
  static const String _baseUrl = ApiConfig.baseUrl;

  static const String _incidenteEndpoint =
      '$_baseUrl/ser_sien_dsp_incidente/recientes?expand=ultimoEstadoRel.estadoRel,victimas.persona,victimas.persona_sin_dni,victimas.despachos.movilunidad.movil,novedades';

  static const String _demandaRecibidaEndpoint =
      '$_baseUrl/ser_sien_dsp_demanda_recibida?expand=estado,tipo_ingreso,incidente';

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
      // 1. Intentar obtener incidentes recientes (/recientes)
      final responseRecientes = await http.get(
        Uri.parse(_incidenteEndpoint),
        headers: _getHeaders(),
      );

      if (responseRecientes.statusCode == 200) {
        final decoded = json.decode(responseRecientes.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      // 2. Si /recientes no devuelve o tiene filtro de 24h, consultar index general de incidentes (/ser_sien_dsp_incidente)
      final responseIndex = await http.get(
        Uri.parse('$_baseUrl/ser_sien_dsp_incidente?per-page=100&expand=ultimoEstadoRel.estadoRel,victimas.persona,victimas.persona_sin_dni,victimas.despachos.movilunidad.movil,novedades'),
        headers: _getHeaders(),
      );

      if (responseIndex.statusCode == 200) {
        final decoded = json.decode(responseIndex.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      // 3. Fallback a demandas recibidas
      final responseDemanda = await http.get(
        Uri.parse(_demandaRecibidaEndpoint),
        headers: _getHeaders(),
      );

      if (responseDemanda.statusCode == 200) {
        final decoded = json.decode(responseDemanda.body);
        if (decoded is List) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error en obtenerDemandasRecibidas: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerIncidentesParaDespacho() async {
    try {
      // 1. Intentar obtener incidentes recientes con victimas y despachos para la asignación de móviles en Despacho
      final responseRecientes = await http.get(
        Uri.parse('$_baseUrl/ser_sien_dsp_incidente/recientes?expand=ultimoEstadoRel.estadoRel,victimas.persona,victimas.persona_sin_dni,victimas.despachos.movilunidad,novedades'),
        headers: _getHeaders(),
      );

      if (responseRecientes.statusCode == 200) {
        final decoded = json.decode(responseRecientes.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      // 2. Si /recientes no devuelve o tiene filtro, consultar index general de incidentes
      final responseIndex = await http.get(
        Uri.parse('$_baseUrl/ser_sien_dsp_incidente?per-page=100&expand=ultimoEstadoRel.estadoRel,victimas.persona,victimas.persona_sin_dni,victimas.despachos.movilunidad,novedades'),
        headers: _getHeaders(),
      );

      if (responseIndex.statusCode == 200) {
        final decoded = json.decode(responseIndex.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      // 3. Fallback a demandas recibidas con expansiones
      final responseDemanda = await http.get(
        Uri.parse('$_baseUrl/ser_sien_dsp_demanda_recibida?expand=estado,tipo_ingreso,incidente,incidente.victimas.persona,incidente.victimas.persona_sin_dni,incidente.victimas.despachos.movilunidad'),
        headers: _getHeaders(),
      );

      if (responseDemanda.statusCode == 200) {
        final decoded = json.decode(responseDemanda.body);
        if (decoded is List) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error en obtenerIncidentesParaDespacho: $e');
      return [];
    }
  }

}
