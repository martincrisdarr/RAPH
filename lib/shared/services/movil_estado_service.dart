import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';
import '../models/movil_estado.dart';

class MovilEstadoService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _endpoint = '$_baseUrl/ser_sien_dsp_movil_estado';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    return headers;
  }

  /// Obtiene los estados de móvil desde el backend
  static Future<List<MovilEstado>> obtenerEstados() async {
    try {
      final response = await http.get(
        Uri.parse(_endpoint),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((e) => MovilEstado.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
