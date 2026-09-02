import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';

class DespachoService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _endpoint = '$_baseUrl/ser_sien_despacho';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    return headers;
  }

  /// Registrar un nuevo despacho en ser_sien_dsp_despacho
  static Future<Map<String, dynamic>?> registrarDespacho({
    int? idVictima,
    int? idIncidente,
    required int idMovilUnidad,
    String? observacion,
  }) async {
    try {
      final now = DateTime.now();
      final fechaFormatted = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      final bodyData = <String, dynamic>{
        if (idVictima != null) 'idvictima': idVictima,
        if (idIncidente != null) 'idincidente': idIncidente,
        'idmovilunidad': idMovilUnidad,
        'fechahoradespacho': fechaFormatted,
        'observacion': observacion ?? 'Despacho emitido desde RAPH Web',
        'enviado': 1,
        'recibido': 0,
        'confirmado': 0,
        'activo': 1,
      };

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: _getHeaders(),
        body: json.encode(bodyData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } else {
        print('[DespachoService] Error al crear despacho: status ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('[DespachoService] Excepción al crear despacho: $e');
      return null;
    }
  }

  /// Asignar idvictima a un despacho existente (PUT /ser_sien_despacho/$idDespacho)
  static Future<bool> asignarVictimaADespacho(int idDespacho, int idVictima) async {
    try {
      final response = await http.put(
        Uri.parse('$_endpoint/$idDespacho'),
        headers: _getHeaders(),
        body: json.encode({
          'idvictima': idVictima,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[DespachoService] Error al asignar víctima a despacho: $e');
      return false;
    }
  }

  /// Obtener despachos por idincidente
  static Future<List<Map<String, dynamic>>> obtenerPorIncidente(int idIncidente) async {
    try {
      final response = await http.get(
        Uri.parse('$_endpoint?filter%5Bidincidente%5D=$idIncidente'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('[DespachoService] Error al obtener despachos por incidente: $e');
      return [];
    }
  }

  /// Cancelar / Eliminar un despacho por iddespacho (DELETE)
  static Future<bool> cancelarDespacho(int idDespacho) async {
    try {
      final response = await http.delete(
        Uri.parse('$_endpoint/$idDespacho'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('[DespachoService] Despacho $idDespacho eliminado correctamente.');
        return true;
      } else {
        print('[DespachoService] Error al eliminar despacho $idDespacho: status ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('[DespachoService] Excepción al eliminar despacho: $e');
      return false;
    }
  }
}
