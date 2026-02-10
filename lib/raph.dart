/// Librería RAPH - API pública + Shell principal de UI
library raph;

import 'package:flutter/material.dart';

// IMPORTS (necesarios para USAR símbolos en este archivo)
import 'modules/auth/controllers/auth_controller.dart';
import 'modules/auth/models/sesion.dart';
import 'modules/auth/views/sesion_detalle_widget.dart';
import 'modules/user/views/usuario_list_widget.dart';
import 'shared/models/usuario.dart';

// EXPORTS (API pública del package)
export 'modules/auth/models/sesion.dart';
export 'modules/auth/controllers/auth_controller.dart';
export 'modules/auth/views/sesion_detalle_widget.dart';

export 'shared/models/usuario.dart';
export 'modules/user/controllers/usuario_controller.dart';
export 'modules/user/views/usuario_list_widget.dart';

export 'shared/config/api_config.dart';
export 'shared/endpoints/auth_endpoints.dart';
export 'shared/endpoints/usuario_endpoints.dart';


// ============================================================================
// RAPH SCREEN (Shell principal para demo/host apps)
// ============================================================================

/// Pantalla principal de la librería RAPH.
/// Usar como [home] o ruta en la aplicación host (example u otra app).
class RaphScreen extends StatefulWidget {
  const RaphScreen({super.key});

  @override
  State<RaphScreen> createState() => _RaphScreenState();
}

class _RaphScreenState extends State<RaphScreen> {
  final AuthController _authController = AuthController.getInstance();

  bool _isLoggingIn = false;

  // Dev-only: alterna pantallas para testear módulos sin tocar /example
  RaphDevView _selectedView = RaphDevView.sessionDetalle;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    setState(() => _isLoggingIn = true);

    // Auto-login de desarrollo
    await _authController.login('dev12345', 'dev12345');

    setState(() => _isLoggingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAPH'),
        centerTitle: true,
        actions: [
          // Cambiar vista (solo dev)
          PopupMenuButton<RaphDevView>(
            tooltip: 'Cambiar vista',
            initialValue: _selectedView,
            onSelected: (value) => setState(() => _selectedView = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: RaphDevView.sessionDetalle,
                child: Text('Sesión - Detalle'),
              ),
              PopupMenuItem(
                value: RaphDevView.userListDemo,
                child: Text('Usuarios - Lista (demo)'),
              ),
            ],
            icon: const Icon(Icons.view_module),
          ),

          if (Sesion.estaLogueado)
            IconButton(
              tooltip: 'Refrescar UI',
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),

          if (Sesion.estaLogueado)
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () {
                _authController.logout();
                setState(() {});
              },
            ),
        ],
      ),
      body: _isLoggingIn
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Iniciando sesión...'),
                ],
              ),
            )
          : _buildSelectedView(),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case RaphDevView.sessionDetalle:
        // Si tu widget depende de estado global Sesion, sacale el const para que reconstruya fácil
        return SesionDetalleWidget();

      case RaphDevView.userListDemo:
        // Demo mínimo para verificar render y estilos sin tocar controllers.
        // Se usa el constructor REAL de Usuario (sin inventar campos como `id`).
        final usuariosDemo = <Usuario>[
          Usuario(
            user: 'jperez',
            nombre: 'Juan',
            apellido: 'Pérez',
            dni: 11222333,
            mail: 'juan@demo.com',
            idOrganismo: 1,
            activo: 1,
            esHumano: 1,
          ),
          Usuario(
            user: 'agomez',
            nombre: 'Ana',
            apellido: 'Gómez',
            dni: 44555666,
            mail: 'ana@demo.com',
            idOrganismo: 1,
            activo: 0,
            esHumano: 1,
          ),
        ];

        return UsuarioListWidget(
          usuarios: usuariosDemo,
          onUsuarioTap: (u) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tap en: ${u.nombre} ${u.apellido}')),
            );
          },
        );
    }
  }
}

/// Vistas disponibles para testear módulos desde el shell.
enum RaphDevView {
  sessionDetalle,
  userListDemo,
}
