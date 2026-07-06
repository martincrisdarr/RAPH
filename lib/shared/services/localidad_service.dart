import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/localidad.dart';
import '../../config/auth_controller.dart';

class LocalidadService {
  static const String _baseUrl =
      'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/localidad';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Busca localidades por nombre (mínimo 2 caracteres para buscar)
  static Future<List<Localidad>> buscar(String query) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.parse(
      '$_baseUrl?filter%5Bnombre_completo%5D%5Blike%5D=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Localidad.fromJson(json)).toList();
    } else {
      throw Exception('Error al buscar localidades: ${response.statusCode}');
    }
  }
}
