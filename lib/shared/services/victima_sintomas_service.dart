import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';
import '../models/sintoma.dart';
import '../models/sintoma_formulario.dart';

class VictimaSintomasService {
  static const String _baseUrl = ApiConfig.baseUrl;

  static Map<String, String> _getHeaders() {
    final token = RaphAuthController.instance.token;
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Obtiene el catálogo completo de síntomas activos.
  static Future<List<Sintoma>> obtenerSintomas() async {
    try {
      final url = Uri.parse('$_baseUrl/ser_sien_dsp_sintoma?filter[activo]=1');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Sintoma.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error al obtener catálogo de síntomas: $e');
    }
    return [];
  }

  /// Obtiene el árbol completo del formulario dinámico para un síntoma.
  static Future<SintomaFormulario?> obtenerFormularioSintoma(int idSintoma) async {
    try {
      final url = Uri.parse('$_baseUrl/ser_sien_dsp_sintoma/$idSintoma/formulario');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return SintomaFormulario.fromJson(data);
      }
    } catch (e) {
      print('Error al obtener formulario de síntoma $idSintoma: $e');
    }
    return null;
  }

  /// Inicia una sesión de evaluación para una víctima.
  static Future<int?> crearEvaluacion(int idVictima, String usuario) async {
    try {
      final url = Uri.parse('$_baseUrl/ser_sien_dsp_victima_evaluacion');
      final payload = {
        'idvictima': idVictima,
        'usuario': usuario,
        'observaciones': 'Evaluación iniciada desde atención de víctima',
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['idvictimaevaluacion'] ?? data['id'];
      }
    } catch (e) {
      print('Error al crear evaluación de víctima: $e');
    }
    return null;
  }

  /// Asocia un síntoma a una evaluación activa.
  static Future<int?> agregarSintoma({
    required int idEvaluacion,
    required int idSintoma,
    String origen = 'OPERADOR',
    required String usuario,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/ser_sien_dsp_victima_evaluacion/$idEvaluacion/sintoma');
      final payload = {
        'idsintoma': idSintoma,
        'origen': origen,
        'confirmado': origen == 'IA_SUGERENCIA' ? 0 : 1,
        'usuario': usuario,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['idvictimasintoma'] ?? data['id'];
      }
    } catch (e) {
      print('Error al agregar síntoma a evaluación: $e');
    }
    return null;
  }

  /// Registra una respuesta incremental a una pregunta dentro de la evaluación.
  static Future<bool> guardarRespuesta({
    required int idEvaluacion,
    required int idVictimaSintoma,
    required int idSintomaPregunta,
    int? idSintomaPreguntaOpcion,
    dynamic valor,
    required String usuario,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/ser_sien_dsp_victima_evaluacion/$idEvaluacion/respuesta');
      final Map<String, dynamic> payload = {
        'idvictimasintoma': idVictimaSintoma,
        'idsintomapregunta': idSintomaPregunta,
        'usuario': usuario,
      };

      if (idSintomaPreguntaOpcion != null) {
        payload['idsintomapreguntaopcion'] = idSintomaPreguntaOpcion;
      }

      if (valor is bool) {
        payload['valor_booleano'] = valor ? 1 : 0;
      } else if (valor is num) {
        payload['valor_numerico'] = valor;
      } else if (valor is String) {
        payload['valor_texto'] = valor;
      }

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al guardar respuesta de síntoma: $e');
    }
    return false;
  }
}
