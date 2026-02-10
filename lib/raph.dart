/// Librería RAPH - API pública + Shell principal de UI
library raph;

import 'package:flutter/material.dart';

// IMPORTS (necesarios para USAR símbolos en este archivo)
import 'modules/auth/controllers/auth_controller.dart';
import 'modules/auth/models/sesion.dart';
import 'modules/auth/views/sesion_detalle_widget.dart';
import 'modules/user/views/usuario_list_widget.dart';
import 'shared/models/usuario.dart';

// Layout
import 'shared/components/layout/app_scaffold.dart';
import 'shared/components/layout/app_sidebar.dart'; // AppMenuItem

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

// Layout / componentes compartidos
export 'shared/components/layout/app_topbar.dart';
export 'shared/components/layout/app_sidebar.dart';
export 'shared/components/layout/app_scaffold.dart';

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

  // Sidebar: item seleccionado
  AppMenuItem _selectedMenuItem = AppMenuItem.ingreso;

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
    return AppScaffold(
      userName: 'Mari', // si después tenés Sesion.nombre, lo reemplazás acá
      selectedItem: _selectedMenuItem,
      onItemSelected: (item) {
        setState(() => _selectedMenuItem = item);

        // Opcional: mapear sidebar -> view de dev (si te sirve ahora)
        // Esto es SOLO demo; después lo reemplazás por navegación real.
        switch (item) {
          case AppMenuItem.despacho:
            setState(() => _selectedView = RaphDevView.sessionDetalle);
            break;
          case AppMenuItem.listado:
            setState(() => _selectedView = RaphDevView.userListDemo);
            break;
          case AppMenuItem.ingreso:
            setState(() => _selectedView = RaphDevView.sessionDetalle);
            break;
        }
      },
      onLogout: () {
        _authController.logout();
        setState(() {});
      },
      onIngresoTap: () {
        setState(() => _selectedMenuItem = AppMenuItem.ingreso);
      },
      child: _isLoggingIn
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
          : _buildCenterContent(),
    );
  }

  /// Contenido central: incluye el selector dev (opcional) + la vista actual.
  Widget _buildCenterContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra superior del contenido central (DEV selector)
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<RaphDevView>(
              tooltip: 'Cambiar vista (DEV)',
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
          ),
          const SizedBox(height: 12),

          // Vista central
          Expanded(child: _buildSelectedView()),
        ],
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case RaphDevView.sessionDetalle:
        return SesionDetalleWidget();

      case RaphDevView.userListDemo:
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
