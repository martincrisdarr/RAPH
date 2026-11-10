import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/hospital.dart';
import '../../config/auth_controller.dart';

class HospitalService {
  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      final cleanToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      headers['Authorization'] = 'Bearer $cleanToken';
    }
    return headers;
  }

  static List<Hospital>? _cache;

  static Future<List<Hospital>> obtenerHospitales({bool forzarRecarga = false}) async {
    if (!forzarRecarga && _cache != null) {
      return _cache!;
    }
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_hospital?activo=1');
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _cache = data
            .map((j) => Hospital.fromJson(j as Map<String, dynamic>))
            .where((h) => h.activo == 1)
            .toList();
        return _cache!;
      } else {
        throw Exception('Error al cargar hospitales (${response.statusCode})');
      }
    } catch (e) {
      print('[HospitalService] Error en obtenerHospitales: $e');
      rethrow;
    }
  }

  static Future<List<Hospital>> obtenerCercanos({
    required double latitud,
    required double longitud,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/ser_sien_dsp_hospital/cercanos?lat=$latitud&lng=$longitud',
      );
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => Hospital.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('[HospitalService] Error en obtenerCercanos: $e');
    }
    return obtenerHospitales(forzarRecarga: true);
  }

  static Future<Hospital?> crearHospital({
    required String nombre,
    required String direccion,
    String localidad = 'Neuquén',
    String telefono = '',
    String complejidad = 'General',
    double? latitud,
    double? longitud,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_hospital');
      final payload = {
        'nombre': nombre.trim(),
        'direccion': direccion.trim(),
        'localidad': localidad.trim().isEmpty ? 'Neuquén' : localidad.trim(),
        'telefono': telefono.trim(),
        'complejidad': complejidad.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'activo': 1,
      };
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _cache = null;
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return Hospital.fromJson(data);
      }
    } catch (e) {
      print('[HospitalService] Error al crear hospital: $e');
    }
    return null;
  }

  static Future<Hospital?> actualizarHospital(
    int idhospital, {
    required String nombre,
    required String direccion,
    String localidad = 'Neuquén',
    String telefono = '',
    String complejidad = 'General',
    double? latitud,
    double? longitud,
    int activo = 1,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_hospital/$idhospital');
      final payload = {
        'nombre': nombre.trim(),
        'direccion': direccion.trim(),
        'localidad': localidad.trim().isEmpty ? 'Neuquén' : localidad.trim(),
        'telefono': telefono.trim(),
        'complejidad': complejidad.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'activo': activo,
      };
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        _cache = null;
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return Hospital.fromJson(data);
      }
    } catch (e) {
      print('[HospitalService] Error al actualizar hospital: $e');
    }
    return null;
  }

  static Future<bool> eliminarHospital(int idhospital) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/ser_sien_dsp_hospital/$idhospital');
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 200 || response.statusCode == 204) {
        _cache = null;
        return true;
      }
    } catch (e) {
      print('[HospitalService] Error al eliminar hospital: $e');
    }
    return false;
  }
}

