import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';
import '../models/jornada.dart';

class JornadaService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _endpoint = '$_baseUrl/ser_sien_dsp_jornada';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    return headers;
  }

  /// Inicia una nueva jornada para un usuario y móvil
  static Future<Jornada?> iniciarJornada({
    required String user,
    required int idmovil,
    int? kmInicio,
    String? rol,
    String? observaciones,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_endpoint/iniciar'),
        headers: _getHeaders(),
        body: json.encode({
          'user': user,
          'idmovil': idmovil,
          if (kmInicio != null) 'km_inicio': kmInicio,
          if (rol != null) 'rol': rol,
          if (observaciones != null) 'observaciones': observaciones,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Jornada.fromJson(decoded);
        }
      } else {
        print('[JornadaService] Error al iniciar jornada: status ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('[JornadaService] Excepción al iniciar jornada: $e');
      rethrow;
    }
  }

  /// Finaliza una jornada existente
  static Future<Jornada?> finalizarJornada({
    int? idjornada,
    String? user,
    int? kmFin,
    String? observaciones,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_endpoint/finalizar'),
        headers: _getHeaders(),
        body: json.encode({
          if (idjornada != null) 'idjornada': idjornada,
          if (user != null) 'user': user,
          if (kmFin != null) 'km_fin': kmFin,
          if (observaciones != null) 'observaciones': observaciones,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Jornada.fromJson(decoded);
        }
      } else {
        print('[JornadaService] Error al finalizar jornada: status ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('[JornadaService] Excepción al finalizar jornada: $e');
      rethrow;
    }
  }

  /// Obtiene la jornada activa del usuario especificado
  static Future<Jornada?> obtenerJornadaActiva(String user) async {
    try {
      final response = await http.get(
        Uri.parse('$_endpoint/activa?user=${Uri.encodeComponent(user)}&expand=movil'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['activa'] == true && decoded['jornada'] != null) {
          return Jornada.fromJson(Map<String, dynamic>.from(decoded['jornada']));
        }
      }
      return null;
    } catch (e) {
      print('[JornadaService] Excepción al obtener jornada activa: $e');
      return null;
    }
  }

  /// Obtiene el historial de jornadas con filtros opcionales
  static Future<List<Jornada>> obtenerJornadas({
    String? user,
    int? idmovil,
    int? estado,
  }) async {
    try {
      final params = <String, String>{'expand': 'movil'};
      if (user != null && user.isNotEmpty) params['user'] = user;
      if (idmovil != null) params['idmovil'] = idmovil.toString();
      if (estado != null) params['estado'] = estado.toString();

      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((e) => Jornada.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
      return [];
    } catch (e) {
      print('[JornadaService] Excepción al obtener jornadas: $e');
      return [];
    }
  }
}
