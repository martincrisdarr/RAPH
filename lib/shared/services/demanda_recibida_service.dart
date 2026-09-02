import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/configuracion.dart';
import '../models/demanda_recibida.dart';
import '../models/incidente.dart';
import '../../config/auth_controller.dart';

class DemandaRecibidaService {
  static const String _baseUrl = '${ApiConfig.baseUrl}/ser_sien_dsp_demanda_recibida';

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
      // Inyectar el legajo/usuario en la demanda si no tiene
      if (demanda.usuario == null || demanda.usuario!.contains(' ')) {
        demanda = demanda.copyWith(usuario: 'mdarroux');
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
      var incUrlStr = '${ApiConfig.baseUrl}/ser_sien_dsp_incidente/recientes?expand=ultimoEstadoRel.estadoRel';

      if (direccion != null && direccion.isNotEmpty) {
        incUrlStr += '&filter%5Bdireccion%5D%5Blike%5D=${Uri.encodeComponent(direccion)}';
      }

      if (fecha != null) {
        final f = fecha;
        final fechaStr = '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
        incUrlStr += '&filter%5Bfechahoraauto%5D%5Blike%5D=${Uri.encodeComponent(fechaStr)}';
      }

      final responseInc = await http.get(Uri.parse(incUrlStr), headers: _getHeaders());

      if (responseInc.statusCode == 200) {
        final decoded = jsonDecode(responseInc.body);
        if (decoded is List) {
          return decoded.map<DemandaRecibida>((j) {
            if (j is Map<String, dynamic>) {
              final idIncidente = j['idincidente'] != null ? int.tryParse(j['idincidente'].toString()) : null;
              final estadoMap = j['ultimoEstadoRel'] != null && j['ultimoEstadoRel']['estadoRel'] != null
                  ? j['ultimoEstadoRel']['estadoRel']
                  : j['estado'];

              return DemandaRecibida(
                idDemandaRecibida: idIncidente ?? (j['iddemandarecibida'] != null ? int.tryParse(j['iddemandarecibida'].toString()) : null),
                idIncidente: idIncidente,
                fechaHora: (j['fechahoraauto'] ?? j['fechahora']) != null ? DateTime.tryParse((j['fechahoraauto'] ?? j['fechahora']).toString()) : null,
                estado: estadoMap != null ? Configuracion.fromJson(estadoMap) : null,
                tipoIngreso: j['tipo_ingreso'] != null ? Configuracion.fromJson(j['tipo_ingreso']) : null,
                incidente: j['incidente'] != null
                    ? Incidente.fromJson(j['incidente'])
                    : Incidente.fromJson(j),
              );
            }
            return DemandaRecibida();
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Excepcion en obtenerRecientes: $e');
      return [];
    }
  }

  static Future<DemandaRecibida?> obtenerPorIncidente(int idIncidente) async {
    try {
      final urlStr = '$_baseUrl?filter%5Bidincidente%5D=$idIncidente&expand=estado,tipo_ingreso,incidente,incidente.victimas.persona,incidente.victimas.persona_sin_dni,incidente.victimas.despachos.movilunidad,incidente.novedades';
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
      final urlStr = '$_baseUrl?filter%5Bidincidente%5D=$idIncidente&expand=estado,tipo_ingreso,incidente,incidente.victimas.persona,incidente.victimas.persona_sin_dni,incidente.victimas.despachos.movilunidad,incidente.novedades';
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

  static Future<DemandaRecibida?> obtenerPorId(int idDemandaRecibida) async {
    try {
      final urlStr = '$_baseUrl/$idDemandaRecibida?expand=estado,tipo_ingreso,incidente,incidente.victimas.persona,incidente.victimas.persona_sin_dni,incidente.victimas.despachos.movilunidad,incidente.novedades';
      final response = await http.get(Uri.parse(urlStr), headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DemandaRecibida.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error en obtenerPorId: $e');
      return null;
    }
  }
}
