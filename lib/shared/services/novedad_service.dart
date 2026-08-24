import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/novedad.dart';
import '../../config/auth_controller.dart';

class NovedadService {
  static const String _baseUrl =
      '${ApiConfig.baseUrl}/ser_sien_dsp_incidente_novedad';

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
    // Inyectar el legajo/usuario en la novedad si no tiene o si contiene espacios (ej. "Martín Darroux")
    if (novedad.usuario == null || novedad.usuario!.trim().isEmpty || novedad.usuario!.contains(' ')) {
      novedad = novedad.copyWith(usuario: 'mdarroux');
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

  /// Obtiene el listado de novedades de un incidente desde el backend.
  static Future<List<Novedad>> obtenerPorIncidente(int idIncidente) async {
    try {
      final urlStr = '$_baseUrl?filter%5Bidincidente%5D=$idIncidente';
      final response = await http.get(Uri.parse(urlStr), headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((n) => Novedad.fromJson(n)).toList();
      } else {
        print('Error al obtener novedades: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Excepcion en obtenerPorIncidente: $e');
      return [];
    }
  }
}
