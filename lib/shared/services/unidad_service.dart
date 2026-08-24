import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';
import '../models/unidad.dart';

class UnidadService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _endpoint = '$_baseUrl/ser_sien_dsp_movil_unidad';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    return headers;
  }

  /// Obtiene el listado de unidades vehiculares desde el backend Yii2 (ser_sien_dsp_movil_unidad)
  static Future<List<Unidad>> obtenerUnidades() async {
    try {
      final response = await http.get(
        Uri.parse('$_endpoint?expand=unidad,movil,tipo_unidad,base'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((e) => Unidad.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      } else {
        print('[UnidadService] Error al obtener unidades: status ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('[UnidadService] Excepción al obtener unidades: $e');
      rethrow;
    }
  }
}
