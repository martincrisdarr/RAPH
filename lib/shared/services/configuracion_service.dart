import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/configuracion.dart';
import '../../config/auth_controller.dart';

class ConfiguracionService {
  static Future<List<Configuracion>> _fetchByTipo(int idTipo) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/ser_sien_dsp_vie_configuraciones?filter%5Bidconfiguraciontipo%5D=$idTipo',
    );
    final token = RaphAuthController.instance.token;
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => Configuracion.fromJson(j)).toList();
    } else {
      throw Exception('Error al cargar configuraciones (tipo $idTipo): ${response.statusCode}');
    }
  }

  /// Tipos de ingreso (idconfiguraciontipo = 3)
  static Future<List<Configuracion>> obtenerTiposIngreso() => _fetchByTipo(3);

  /// Géneros (idconfiguraciontipo = 6)
  static Future<List<Configuracion>> obtenerGeneros() => _fetchByTipo(6);
}
