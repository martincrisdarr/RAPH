import 'package:raph/modules/auth/models/sesion.dart';
import 'package:raph/shared/endpoints/auth_endpoints.dart';

class AuthController {
  static AuthController? _instance;
  static final Object _lock = Object();

  AuthController._();

  static AuthController getInstance() {
    if (_instance == null) {
      synchronized(_lock, () {
        if (_instance == null) {
          _instance = AuthController._();
        }
      });
    }
    return _instance!;
  }

  static void synchronized(Object lock, Function action) {
    action();
  }

  Future<bool> login(String username, String password) async {
    final String url = AuthEndpoints.login();
    print('Petición POST a: $url');
    print('Cuerpo: {user: $username, pass: $password}');

    await Future.delayed(const Duration(seconds: 1));

    if (username == 'dev12345' && password == 'dev12345') {
      final mockJsonResponse = {
        'success': true,
        'token': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImRldjEyMzQ1In0.eyJzdWIiOiJkZXYxMjM0NSIsImlzcyI6IiIsImF1ZCI6IiIsImlhdCI6MTc4MDQ4ODAwNSwiZXhwIjoxNzgwNjYwODA1LCJqdGkiOiIxN2M2YzYyYTk2MWJlOTciLCJ1c2VyIjoiZGV2MTIzNDUiLCJub21icmUiOiJVc3VhcmlvIn0.zWIY68l8-lSD8xBsQqwphYESm-QhDqV7P1an9f_lpzI',
        'usuario': {
          'user': 'dev12345',
          'nombre': 'Desarrollador',
          'apellido': 'BIA',
          'dni': 12345678,
          'mail': 'dev@bia.com',
          'idorganismo': 1,
          'activo': 1,
          'es_humano': 1,
        },
        'permisos': {
          'admin': {'type': 2, 'name': 'Administrador'},
        },
        'organismo': {
          'id': 1,
          'nombre': 'Organismo Central',
        },
      };

      final sesion = Sesion.fromJson(mockJsonResponse);
      await Sesion.iniciarSesion(sesion, password);

      print('Login exitoso. Usuario: ${sesion.usuario.nombre}');

      return true;
    }

    return false;
  }

  void logout() {
    Sesion.cerrarSesion();
    print('Sesión cerrada.');
  }
}

