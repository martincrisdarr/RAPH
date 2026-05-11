import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/demanda_recibida.dart';
import '../../config/auth_controller.dart';

class DemandaRecibidaService {
  static const String _baseUrl = 'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/ser_sien_dsp_demanda_recibida';

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<DemandaRecibida?> crear(DemandaRecibida demanda) async {
    try {
      // Inyectar el nombre del usuario logueado en la demanda si no tiene
      if (demanda.usuario == null) {
        final currentUser = RaphAuthController.instance.currentUser;
        if (currentUser != null) {
          final nombreCompleto = '${currentUser.nombre ?? ''} ${currentUser.apellido ?? ''}'.trim();
          demanda = demanda.copyWith(usuario: nombreCompleto.isNotEmpty ? nombreCompleto : 'App GIRO');
        }
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: jsonEncode(demanda.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return DemandaRecibida.fromJson(data);
      } else {
        print('Error al crear demanda: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepcion en crearDemanda: $e');
      return null;
    }
  }

  static Future<bool> actualizar(DemandaRecibida demanda) async {
    if (demanda.idDemandaRecibida == null) return false;
    
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${demanda.idDemandaRecibida}'),
        headers: _getHeaders(),
        body: jsonEncode(demanda.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        // Fallback en caso de que el backend espere el PUT en la misma URL sin ID
        final responseFallback = await http.put(
          Uri.parse(_baseUrl),
          headers: _getHeaders(),
          body: jsonEncode(demanda.toJson()),
        );
        return responseFallback.statusCode == 200 || responseFallback.statusCode == 204;
      }
    } catch (e) {
      print('Excepcion en actualizarDemanda: $e');
      return false;
    }
  }
}
