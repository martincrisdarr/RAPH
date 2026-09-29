import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';
import '../models/unidad.dart';

class UnidadService {
  static const String _endpoint = ApiConfig.unidadesVehicularesUrl;

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    return headers;
  }

  /// Obtiene el listado de unidades vehiculares (ambulancias) desde el endpoint de GIRO (ser_veh_vie_unidad_despacho)
  static Future<List<Unidad>> obtenerUnidades() async {
    try {
      final response = await http.get(
        Uri.parse(_endpoint),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((e) => Unidad.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      } else {
        print('[UnidadService] Error al obtener unidades vehiculares: status ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      print('[UnidadService] Excepción al obtener unidades vehiculares: $e');
      rethrow;
    }
  }

  /// Asigna o desasigna una unidad vehicular a un móvil en la tabla ser_sien_dsp_movil_unidad del backend
  static Future<bool> asignarUnidadAMovil({
    required String idUnidad,
    required String? idMovil,
    String? patente,
    String? marca,
    String? modelo,
  }) async {
    try {
      final cleanIdMovil = idMovil?.replaceAll(RegExp(r'[^0-9]'), '');
      final int? idMovilInt = (cleanIdMovil != null && cleanIdMovil.isNotEmpty)
          ? int.tryParse(cleanIdMovil)
          : null;

      final cleanIdUnidad = idUnidad.replaceAll(RegExp(r'[^0-9]'), '');
      final int? idUnidadInt = cleanIdUnidad.isNotEmpty ? int.tryParse(cleanIdUnidad) : null;

      if (idUnidadInt == null) {
        print('[UnidadService] ID de unidad inválido: $idUnidad');
        return false;
      }

      final http.Response response;
      if (idMovilInt != null) {
        // Asignación activa
        final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_movil_unidad');
        final Map<String, dynamic> body = {
          'idmovil': idMovilInt,
          'idunidad': idUnidadInt,
        };
        if (patente != null && patente.isNotEmpty) body['patente'] = patente;
        if (marca != null && marca.isNotEmpty) body['marca'] = marca;
        if (modelo != null && modelo.isNotEmpty) body['modelo'] = modelo;

        response = await http.post(
          url,
          headers: _getHeaders(),
          body: json.encode(body),
        );
      } else {
        // Desasignación
        final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_movil_unidad/desasignar');
        response = await http.post(
          url,
          headers: _getHeaders(),
          body: json.encode({
            'idunidad': idUnidadInt,
          }),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('[UnidadService] Error al asignar/desasignar unidad $idUnidad con móvil $idMovil: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('[UnidadService] Excepción al asignar unidad: $e');
      return false;
    }
  }
}
