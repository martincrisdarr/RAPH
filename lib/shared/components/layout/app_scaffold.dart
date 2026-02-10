import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'app_topbar.dart';

/// Contenedor general de layout para la aplicación.
///
/// Combina:
/// - Sidebar lateral izquierda (`AppSidebar`)
/// - Topbar superior (`AppTopbar`)
/// - Área central de contenido (inyectada por parámetro)
///
/// No implementa lógica de negocio ni navegación,
/// solo estructura visual y callbacks.
class AppScaffold extends StatelessWidget {
  final String userName;
  final AppMenuItem selectedItem;
  final ValueChanged<AppMenuItem> onItemSelected;
  final VoidCallback onLogout;
  final VoidCallback onIngresoTap;
  final Widget child;

  const AppScaffold({
    super.key,
    required this.userName,
    required this.selectedItem,
    required this.onItemSelected,
    required this.onLogout,
    required this.onIngresoTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ancho razonable para sidebar según el espacio disponible.
        final double maxWidth = constraints.maxWidth;
        final double sidebarWidth =
            maxWidth < 900 ? maxWidth * 0.25 : 260; // responsive básico

        return Column(
          children: [
            // Topbar 100% ancho, por encima del sidebar
            AppTopbar(
              userName: userName,
              selectedItem: selectedItem,
              onLogout: onLogout,
              onIngresoTap: onIngresoTap,
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: sidebarWidth.clamp(200, 260),
                    child: AppSidebar(
                      selectedItem: selectedItem,
                      onItemSelected: onItemSelected,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

