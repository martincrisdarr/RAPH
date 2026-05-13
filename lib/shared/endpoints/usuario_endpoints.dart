import '../config/api_config.dart';

class UsuarioEndpoints {
  static const String _recurso = '/usuarios';

  static String listar() => ApiConfig.baseUrl + _recurso;

  static String obtener(int id) => '${ApiConfig.baseUrl}$_recurso/$id';

  static String crear() => ApiConfig.baseUrl + _recurso;

  static String actualizar(int id) => '${ApiConfig.baseUrl}$_recurso/$id';

  static String eliminar(int id) => '${ApiConfig.baseUrl}$_recurso/$id';

  UsuarioEndpoints._();
}

