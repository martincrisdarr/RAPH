import 'package:raph/shared/models/usuario.dart';

class Sesion {
  static Sesion? sesionActual;

  final bool success;
  final Usuario usuario;
  final String token;
  final Map<String, dynamic> permisos;

  static const String PARAM_SUCCESS = 'success';
  static const String PARAM_USUARIO = 'usuario';
  static const String PARAM_TOKEN = 'token';
  static const String PARAM_PERMISOS = 'permisos';

  Sesion({
    required this.success,
    required this.usuario,
    required this.token,
    required this.permisos,
  });

  factory Sesion.fromJson(Map<String, dynamic> json) {
    return Sesion(
      success: json[PARAM_SUCCESS] as bool? ?? false,
      usuario: Usuario.fromJson(json[PARAM_USUARIO] as Map<String, dynamic>),
      token: json[PARAM_TOKEN] as String? ?? '',
      permisos: json[PARAM_PERMISOS] as Map<String, dynamic>? ?? {},
    );
  }

  static Future<void> iniciarSesion(Sesion sesion, String passPlaintxt) async {
    sesion.usuario.passPlaintxt = passPlaintxt;
    sesionActual = sesion;
  }

  static void cerrarSesion() {
    sesionActual = null;
  }

  static bool get estaLogueado => sesionActual != null;
}

