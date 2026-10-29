/// Librería RAPH - API pública + Shell principal de UI
library raph;

import 'package:flutter/material.dart';
import 'package:user_session_contract/user_session_contract.dart';

// IMPORTS (necesarios para USAR símbolos en este archivo)
import 'raph_app.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'modules/auth/models/sesion.dart';
import 'modules/auth/views/sesion_detalle_widget.dart';
import 'modules/user/views/usuario_list_widget.dart';
import 'shared/models/usuario.dart';

// Layout
import 'shared/components/layout/app_scaffold.dart';
import 'shared/components/layout/app_sidebar.dart'; // AppMenuItem

// EXPORTS (API pública del package)
export 'raph_app.dart';
export 'config/auth_controller.dart';
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

// Sockets / Edición Colaborativa
export 'shared/services/socket_service.dart';
export 'shared/services/socket_events.dart';
export 'shared/components/collab_text_field.dart';

/// Pantalla principal de la librería RAPH compatible con inyección desde Portal GIRO.
/// Acepta [session] opcional (contrato [IUserSession]) tal como indica la Guía de Integración.
class RaphScreen extends StatelessWidget {
  final IUserSession? session;

  const RaphScreen({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    return RaphApp(session: session);
  }
}

/// Vistas disponibles para testear módulos desde el shell legacy.
enum RaphDevView {
  sessionDetalle,
  userListDemo,
}
