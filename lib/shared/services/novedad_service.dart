import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/novedad.dart';
import '../../config/auth_controller.dart';

class NovedadService {
  static const String _baseUrl =
      'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/ser_sien_dsp_incidente_novedad';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Crea una nueva novedad en el backend. Retorna la novedad con el ID asignado,
  /// o null si hubo un error.
  static Future<Novedad?> crear(Novedad novedad) async {
    // Inyectar usuario si no tiene
    if (novedad.usuario == null) {
      final currentUser = RaphAuthController.instance.currentUser;
      if (currentUser != null) {
        final nombre = '${currentUser.nombre ?? ''} ${currentUser.apellido ?? ''}'.trim();
        novedad = novedad.copyWith(usuario: nombre.isNotEmpty ? nombre : 'App GIRO');
      }
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: jsonEncode(novedad.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Novedad.fromJson(data);
      } else {
        print('Error al crear novedad: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepcion en crearNovedad: $e');
      return null;
    }
  }
}
