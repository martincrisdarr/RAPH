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
    required int idVictima,
    required int idMovilUnidad,
    String? observacion,
  }) async {
    try {
      final now = DateTime.now();
      final fechaFormatted = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      final bodyData = <String, dynamic>{
        'idvictima': idVictima,
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
}
