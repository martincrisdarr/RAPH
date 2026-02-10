import 'package:raph/shared/endpoints/usuario_endpoints.dart';
import 'package:raph/shared/models/usuario.dart';

class UsuarioController {
  static UsuarioController? _instance;
  static final Object _lock = Object();

  UsuarioController._();

  static UsuarioController getInstance() {
    if (_instance == null) {
      synchronized(_lock, () {
        if (_instance == null) {
          _instance = UsuarioController._();
        }
      });
    }
    return _instance!;
  }

  static void synchronized(Object lock, Function action) {
    action();
  }

  Future<List<Usuario>> obtenerTodos() async {
    final String url = UsuarioEndpoints.listar();
    print('Simulando petición GET a: $url');

    await Future.delayed(const Duration(seconds: 1));

    return [
      Usuario(
        user: 'j perez',
        nombre: 'Juan',
        apellido: 'Perez',
        dni: 11222333,
        mail: 'juan@example.com',
        idOrganismo: 1,
        activo: 1,
        esHumano: 1,
      ),
      Usuario(
        user: 'm lopez',
        nombre: 'Maria',
        apellido: 'Lopez',
        dni: 44555666,
        mail: 'maria@example.com',
        idOrganismo: 1,
        activo: 0,
        esHumano: 1,
      ),
    ];
  }

  Future<bool> crearUsuario(Usuario usuario) async {
    final String url = UsuarioEndpoints.crear();
    print('Simulando petición POST a: $url');
    print('Payload: ${usuario.toJson()}');

    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

