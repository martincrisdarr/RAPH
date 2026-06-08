import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/demanda_recibida.dart';
import '../models/incidente.dart';
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

  static Future<List<DemandaRecibida>> obtenerRecientes({DateTime? fecha, String? direccion}) async {
    try {
      // Endpoint específico para incidentes recientes
      final baseIncidenteUrl = 'https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/ser_sien_dsp_incidente/recientes';
      var urlStr = baseIncidenteUrl;
      
      bool hasQuery = false;
      int filterIndex = 0;
      if (direccion != null && direccion.isNotEmpty) {
        urlStr += '?filter%5Bdireccion%5D%5Blike%5D=${Uri.encodeComponent(direccion)}';
        filterIndex++;
        hasQuery = true;
      }

      if (fecha != null) {
        final f = fecha;
        final fechaStr = '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
        urlStr += (hasQuery ? '&' : '?') + 'filter%5Band%5D%5B$filterIndex%5D%5Bfechahoraauto%5D%5Blike%5D=${Uri.encodeComponent(fechaStr)}';
      }

      final url = Uri.parse(urlStr);
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<DemandaRecibida>((j) {
          // El JSON de este endpoint usa 'idincidente' (sin guión bajo)
          final idIncidente = j['idincidente'];
          
          return DemandaRecibida(
            idDemandaRecibida: idIncidente,
            fechaHora: j['fechahoraauto'] != null ? DateTime.tryParse(j['fechahoraauto']) : null,
            incidente: Incidente(
              idIncidente: idIncidente,
              direccion: j['direccion'] ?? 'No especificada',
              latitud: j['latitud'] != null ? double.tryParse(j['latitud'].toString()) : null,
              longitud: j['longitud'] != null ? double.tryParse(j['longitud'].toString()) : null,
              direccionAuto: j['direccion_auto'],
            ),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Excepcion en obtenerRecientes (Incidente): $e');
      return [];
    }
  }

  static Future<DemandaRecibida?> obtenerPorIncidente(int idIncidente) async {
    try {
      final urlStr = '$_baseUrl?filter%5Bidincidente%5D=$idIncidente&expand=estado,tipo_ingreso,incidente,incidente.victimas,incidente.novedades';
      final response = await http.get(Uri.parse(urlStr), headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return DemandaRecibida.fromJson(data.first);
        }
      }
      return null;
    } catch (e) {
      print('Error en obtenerPorIncidente: $e');
      return null;
    }
  }

  static Future<List<DemandaRecibida>> obtenerTodasPorIncidente(int idIncidente) async {
    try {
      final urlStr = '$_baseUrl?filter%5Bidincidente%5D=$idIncidente&expand=estado,tipo_ingreso,incidente,incidente.victimas,incidente.novedades';
      final response = await http.get(Uri.parse(urlStr), headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<DemandaRecibida>((j) => DemandaRecibida.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('Error en obtenerTodasPorIncidente: $e');
      return [];
    }
  }
}
