import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/victima.dart';
import '../../config/auth_controller.dart';

class VictimaService {
  static const String _baseUrl =
      'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/ser_sien_dsp_victima';

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
}
