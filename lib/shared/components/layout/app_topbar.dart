import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';
import '../../services/socket_service.dart';
import 'app_sidebar.dart';

/// Barra superior de la aplicación (topbar) desacoplada del contenido central.
///
/// Diseño dark institucional:
/// - LEFT: Bloque "glass" con SIEN y título del sistema
/// - CENTER: Indicador de sección activa (INGRESO/LISTADO/DESPACHO)
/// - RIGHT: Avatar, nombre, usuario/legajo y botón Salir
///
/// Solo maneja UI y callbacks, sin lógica de negocio.
class AppTopbar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final AppMenuItem selectedItem;
  final VoidCallback onLogout;
  final VoidCallback onIngresoTap;

  /// Usuario/legajo mostrado bajo el nombre (ej. "mcarderi").
  /// Opcional; si está vacío se muestra solo el nombre.
  final String userSubTitle;

  const AppTopbar({
    super.key,
    required this.userName,
    required this.selectedItem,
    required this.onLogout,
    required this.onIngresoTap,
    this.userSubTitle = '',
  });

  String get _centerButtonLabel {
    switch (selectedItem) {
      case AppMenuItem.despacho:
        return 'DESPACHO';
      case AppMenuItem.listado:
        return 'LISTADO';
      case AppMenuItem.ingreso:
        return 'INGRESO';
    }
  }

  static const double _topbarHeight = 70;

  String get _userInitial {
    final trimmed = userName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Size get preferredSize => const Size.fromHeight(_topbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color topbarColor = AppColors.background;
    final Color leftBlockBackground = AppColors.surface;
    final Color centerButtonBorder = colorScheme.primary;
    final Color centerButtonBackground = AppColors.surfaceAlt;

    return Material(
      elevation: 2,
      color: topbarColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _topbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT: Bloque blanco con SIEN y título
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth.clamp(200.0, 420.0);
                        return Container(
                          width: width,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: leftBlockBackground,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.9),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SIEN',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder<bool>(
                                valueListenable: SocketService().isConnected,
                                builder: (context, connected, child) {
                                  return Tooltip(
                                    message: connected ? 'Sockets Conectados' : 'Sockets Desconectados',
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: connected ? Colors.greenAccent : Colors.redAccent,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (connected ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Sistema Integrado de Emergencias de Neuquén',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // CENTER: Indicador de sección actual (estilo sidebar)
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: centerButtonBackground,
                    border: Border.all(color: centerButtonBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [
                      BoxShadow(
                        color: centerButtonBorder.withOpacity(0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _centerButtonLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // RIGHT: Bloque usuario
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 20,
                        backgroundColor:
                            colorScheme.primary.withOpacity(0.25),
                          child: Text(
                            _userInitial,
                            style: const TextStyle(
                            color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                              color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (userSubTitle.isNotEmpty)
                              Text(
                                userSubTitle,
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: onLogout,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: leftBlockBackground,
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.8),
                                  width: 1.2,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.sm),
                              ),
                              child: const Text(
                                'Salir',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
