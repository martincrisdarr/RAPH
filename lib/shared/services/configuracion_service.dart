import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/configuracion.dart';
import '../../config/auth_controller.dart';

class ConfiguracionService {
  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    return headers;
  }

  static Future<List<Configuracion>> obtenerPorTipo(int idTipo) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/ser_sien_dsp_vie_configuraciones?filter%5Bidconfiguraciontipo%5D=$idTipo&filter%5Bactivo%5D=1',
    );
    final response = await http.get(url, headers: _getHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      final items = data.map((j) => Configuracion.fromJson(j)).toList();
      return items.where((e) => e.activo == 1).toList();
    } else {
      throw Exception('Error al cargar configuraciones (tipo $idTipo): ${response.statusCode}');
    }
  }

  /// Tipos de ingreso (idconfiguraciontipo = 3)
  static Future<List<Configuracion>> obtenerTiposIngreso() => obtenerPorTipo(3);

  /// Tipos de Incidente (idconfiguraciontipo = 4)
  static Future<List<Configuracion>> obtenerTiposIncidente() => obtenerPorTipo(4);

  /// Géneros (idconfiguraciontipo = 6)
  static Future<List<Configuracion>> obtenerGeneros() => obtenerPorTipo(6);

  /// Protocolos de Emergencia (idconfiguraciontipo = 7)
  static Future<List<Configuracion>> obtenerProtocolos() => obtenerPorTipo(7);

  /// Etiquetas de Incidentes (idconfiguraciontipo = 8)
  static Future<List<Configuracion>> obtenerEtiquetas() => obtenerPorTipo(8);

  /// Crear una nueva configuración en la BD
  static Future<Configuracion?> crearConfiguracion({
    required String descripcion,
    required int idconfiguraciontipo,
    int orden = 1,
    int activo = 1,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_configuracion');
      final payload = {
        'descripcion': descripcion,
        'idconfiguraciontipo': idconfiguraciontipo,
        'orden': orden,
        'activo': activo,
      };
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return Configuracion.fromJson({
          ...data,
          'nombre': data['nombre'] ?? '',
          'descripcion': data['descripcion'] ?? descripcion,
          'idconfiguraciontipo': data['idconfiguraciontipo'] ?? idconfiguraciontipo,
          'tipo_activo': 1,
        });
      }
    } catch (e) {
      print('[ConfiguracionService] Error al crear configuración: $e');
    }
    return null;
  }

  /// Actualizar una configuración existente
  static Future<Configuracion?> actualizarConfiguracion(
    int id, {
    required String descripcion,
    required int idconfiguraciontipo,
    int orden = 1,
    int activo = 1,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_configuracion/$id');
      final payload = {
        'descripcion': descripcion,
        'idconfiguraciontipo': idconfiguraciontipo,
        'orden': orden,
        'activo': activo,
      };
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return Configuracion.fromJson({
          ...data,
          'nombre': data['nombre'] ?? '',
          'descripcion': data['descripcion'] ?? descripcion,
          'idconfiguraciontipo': data['idconfiguraciontipo'] ?? idconfiguraciontipo,
          'tipo_activo': 1,
        });
      }
    } catch (e) {
      print('[ConfiguracionService] Error al actualizar configuración: $e');
    }
    return null;
  }

  /// Eliminar o desactivar una configuración
  static Future<bool> eliminarConfiguracion(int id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_configuracion/$id');
      final response = await http.delete(url, headers: _getHeaders());
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('[ConfiguracionService] Error al eliminar configuración: $e');
    }
    return false;
  }
}
