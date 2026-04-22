import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/configuracion.dart';

class ConfiguracionService {
  /// Obtiene los tipos de ingreso (idconfiguraciontipo = 3)
  static Future<List<Configuracion>> obtenerTiposIngreso() async {
    final url = Uri.parse('https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/ser_sien_dsp_vie_configuraciones?filter%5Bidconfiguraciontipo%5D=3');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Configuracion.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar tipos de ingreso: ${response.statusCode}');
    }
  }
}
