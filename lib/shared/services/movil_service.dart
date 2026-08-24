import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';
import '../models/movil.dart';

class MovilService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _endpoint = '$_baseUrl/ser_sien_dsp_movil';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    return headers;
  }

  /// Obtiene el listado de móviles desde el backend Yii2
  static Future<List<Movil>> obtenerMoviles() async {
    try {
      final response = await http.get(
        Uri.parse('$_endpoint?expand=unidades,telefonos'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((e) => Movil.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      } else {
        print('[MovilService] Error al obtener móviles: status ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('[MovilService] Excepción al obtener móviles: $e');
      rethrow;
    }
  }

  /// Crea un nuevo móvil en el backend
  static Future<Movil?> crearMovil(Movil movil) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: _getHeaders(),
        body: json.encode({
          'nombre': movil.nombre,
          'descripcion': movil.descripcion,
          'activo': movil.activo,
          if (movil.idmovilEstado != null) 'idmovil_estado': movil.idmovilEstado,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Movil.fromJson(decoded);
        }
      } else {
        print('[MovilService] Error al crear móvil: status ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('[MovilService] Excepción al crear móvil: $e');
      rethrow;
    }
  }

  /// Actualiza un móvil existente en el backend
  static Future<Movil?> actualizarMovil(Movil movil) async {
    try {
      final response = await http.put(
        Uri.parse('$_endpoint/${movil.id}'),
        headers: _getHeaders(),
        body: json.encode({
          'nombre': movil.nombre,
          'descripcion': movil.descripcion,
          'activo': movil.activo,
          if (movil.idmovilEstado != null) 'idmovil_estado': movil.idmovilEstado,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Movil.fromJson(decoded);
        }
      } else {
        print('[MovilService] Error al actualizar móvil: status ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('[MovilService] Excepción al actualizar móvil: $e');
      rethrow;
    }
  }

  /// Elimina (desactiva) un móvil en el backend
  static Future<bool> eliminarMovil(String idMovil) async {
    try {
      final response = await http.delete(
        Uri.parse('$_endpoint/$idMovil'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('[MovilService] Error al eliminar móvil: status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[MovilService] Excepción al eliminar móvil: $e');
      rethrow;
    }
  }
}
