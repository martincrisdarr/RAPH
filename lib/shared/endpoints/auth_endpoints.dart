import '../config/api_config.dart';

class AuthEndpoints {
  static const String _recurso = '/usuario';

  static String login() => '${ApiConfig.baseUrl}$_recurso/login';

  AuthEndpoints._();
}

