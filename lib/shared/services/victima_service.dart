import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/victima.dart';
import '../../config/auth_controller.dart';

class VictimaService {
  static const String _baseUrl =
      '${ApiConfig.baseUrl}/ser_sien_dsp_victima';
  static const String _cierreUrl =
      '${ApiConfig.baseUrl}/ser_sien_dsp_victima_cierre';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Crea una nueva víctima (POST). Retorna la víctima con el idVictima asignado,
  /// o null si hubo un error.
  static Future<Victima?> crear(Victima victima) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: jsonEncode(victima.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Victima.fromJson(data);
      } else {
        print('Error al crear víctima: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepcion en crearVictima: $e');
      return null;
    }
  }

  /// Actualiza una víctima existente (PUT a /endpoint/{idVictima}).
  /// Retorna true si fue exitoso.
  static Future<bool> actualizar(Victima victima) async {
    if (victima.idVictima == null) return false;
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${victima.idVictima}'),
        headers: _getHeaders(),
        body: jsonEncode(victima.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        // Fallback sin ID en la URL
        final fallback = await http.put(
          Uri.parse(_baseUrl),
          headers: _getHeaders(),
          body: jsonEncode(victima.toJson()),
        );
        return fallback.statusCode == 200 || fallback.statusCode == 204;
      }
    } catch (e) {
      print('Excepcion en actualizarVictima: $e');
      return false;
    }
  }

  /// Registra el cierre individual de una víctima en la tabla ser_sien_dsp_victima_cierre.
  static Future<Map<String, dynamic>?> cerrarVictima({
    required int idVictima,
    required int idIncidente,
    required String reporte,
    String? usuario,
  }) async {
    try {
      final body = {
        'idvictima': idVictima,
        'idincidente': idIncidente,
        'reporte': reporte,
        'usuario_cierre': usuario ?? RaphAuthController.instance.currentUsername,
      };
      final response = await http.post(
        Uri.parse(_cierreUrl),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) return raw;
        if (raw is Map) return Map<String, dynamic>.from(raw);
      } else {
        print('[VictimaService] Error cerrarVictima ${response.statusCode}: ${response.body}');
      }
      return null;
    } catch (e) {
      print('[VictimaService] Excepcion en cerrarVictima: $e');
      return null;
    }
  }

  /// Obtiene todos los cierres de víctimas asociados a un incidente.
  static Future<List<Map<String, dynamic>>> obtenerCierresPorIncidente(int idIncidente) async {
    try {
      final response = await http.get(
        Uri.parse('$_cierreUrl?idincidente=$idIncidente'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        final list = raw is List
            ? raw
            : (raw is Map && raw['data'] is List ? raw['data'] as List : []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('[VictimaService] Excepcion en obtenerCierresPorIncidente: $e');
      return [];
    }
  }
}
