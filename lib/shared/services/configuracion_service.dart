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

  static final Map<int, List<Configuracion>> _cachePorTipo = {};
  static final Map<int, Future<List<Configuracion>>> _inFlightPorTipo = {};

  static Future<List<Configuracion>> obtenerPorTipo(int idTipo, {bool forzarRecarga = false}) async {
    if (!forzarRecarga) {
      if (_cachePorTipo.containsKey(idTipo)) {
        return _cachePorTipo[idTipo]!;
      }
      if (_inFlightPorTipo.containsKey(idTipo)) {
        return await _inFlightPorTipo[idTipo]!;
      }
    }

    final future = _ejecutarObtenerPorTipo(idTipo);
    _inFlightPorTipo[idTipo] = future;

    try {
      final items = await future;
      _cachePorTipo[idTipo] = items;
      return items;
    } catch (e) {
      _cachePorTipo.remove(idTipo);
      rethrow;
    } finally {
      _inFlightPorTipo.remove(idTipo);
    }
  }

  static Future<List<Configuracion>> _ejecutarObtenerPorTipo(int idTipo) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/ser_sien_dsp_vie_configuraciones?filter%5Bidconfiguraciontipo%5D=$idTipo&filter%5Bactivo%5D=1',
    );
    final response = await http.get(url, headers: _getHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((j) => Configuracion.fromJson(j)).where((e) => e.activo == 1).toList();
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

  /// ID de 'Sin código' en Configuraciones Tipo 7 (por defecto 63)
  static const int idSinCodigoConst = 63;
  static int? _idSinCodigoCached;

  static Future<int> obtenerIdSinCodigo() async {
    if (_idSinCodigoCached != null) return _idSinCodigoCached!;
    try {
      final protocolos = await obtenerProtocolos();
      for (var p in protocolos) {
        final desc = p.descripcion.toLowerCase();
        if (desc.contains('sin c') || desc.contains('sin codigo') || desc.contains('sin código')) {
          _idSinCodigoCached = p.idconfiguracion;
          return p.idconfiguracion;
        }
      }
    } catch (_) {}
    return _idSinCodigoCached ?? idSinCodigoConst;
  }

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
        _cachePorTipo.remove(idconfiguraciontipo);
        _inFlightPorTipo.remove(idconfiguraciontipo);
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
        _cachePorTipo.remove(idconfiguraciontipo);
        _inFlightPorTipo.remove(idconfiguraciontipo);
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
      if (response.statusCode == 200 || response.statusCode == 204) {
        _cachePorTipo.clear();
        _inFlightPorTipo.clear();
        return true;
      }
      return false;
    } catch (e) {
      print('[ConfiguracionService] Error al eliminar configuración: $e');
    }
    return false;
  }
}
