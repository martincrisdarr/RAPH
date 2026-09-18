import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:user_session_contract/user_session_contract.dart';
import '../../config/auth_controller.dart';
import '../../modules/ingreso/controllers/ingreso_controller.dart';
import '../services/socket_service.dart';

class SidebarItem {
  final IconData icon;
  final String label;

  SidebarItem({required this.icon, required this.label});
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<SidebarItem> _items = [
    SidebarItem(icon: Icons.list_alt_rounded, label: 'Tablero'),
    SidebarItem(icon: Icons.local_shipping_rounded, label: 'Despacho'),
    SidebarItem(icon: Icons.settings_rounded, label: 'Configuraciones'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 80.0,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Image.asset(
              'assets/images/logo_secretaria.png',
              package: 'raph',
              width: 55,
              height: 55,
              fit: BoxFit.contain,
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          // Navigation List
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ListenableBuilder(
                listenable: IngresoController(),
                builder: (context, child) {
                  final tieneBorrador = IngresoController().tieneBorrador;

                  return Column(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      // Index 0 in sidebar corresponds to Page Index 1 (Tablero)
                      // Index 1 corresponds to Page Index 2 (Despacho)
                      // Index 2 corresponds to Page Index 3 (Configuraciones)
                      final isSelected = selectedIndex == (index + 1);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: HoverRightTooltip(
                              message: item.label,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => onItemSelected(index + 1),
                                hoverColor: theme.colorScheme.primary.withOpacity(0.05),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14.0),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? theme.colorScheme.primary.withOpacity(0.15) 
                                      : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected 
                                        ? theme.colorScheme.primary.withOpacity(0.5) 
                                        : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: isSelected 
                                      ? theme.colorScheme.primary 
                                      : theme.colorScheme.onSurface.withOpacity(0.7),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Si es el ítem "Tablero" (índice 0) y hay un borrador activo
                          if (index == 0 && tieneBorrador) ...[
                            // Línea de conexión sutil
                            Container(
                              width: 2,
                              height: 10,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.3),
                                    Colors.amber.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // Botón de Borrador Activo (Submenú)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  HoverRightTooltip(
                                    message: 'Continuar Incidente',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        IngresoController().vistaFormulario = true;
                                        onItemSelected(0);
                                      },
                                      hoverColor: Colors.amber.withOpacity(0.05),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          color: selectedIndex == 0 
                                            ? Colors.amber.withOpacity(0.15) 
                                            : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: selectedIndex == 0 
                                              ? Colors.amber.withOpacity(0.5) 
                                              : Colors.amber.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit_note_rounded,
                                          color: selectedIndex == 0 
                                            ? Colors.amber 
                                            : Colors.amber.withOpacity(0.7),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Botón de la cruz (X) para descartar borrador
                                    Positioned(
                                    top: -4,
                                    right: -4,
                                    child: HoverRightTooltip(
                                      message: 'Cerrar Incidente',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () async {
                                            final confirm = await _mostrarDialogoDescartarBorrador(context);
                                            if (confirm == true) {
                                              await IngresoController().limpiarBorrador();
                                              if (selectedIndex == 0) {
                                                onItemSelected(1);
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.amber, width: 1.5),
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.amber,
                                              size: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ],
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          // Socket Connection Status Indicator
          ValueListenableBuilder<bool>(
            valueListenable: SocketService().isConnected,
            builder: (context, connected, child) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: HoverRightTooltip(
                  message: connected ? 'Sockets Conectados' : 'Sockets Desconectados',
                  child: Icon(
                    connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: connected ? Colors.greenAccent : Colors.redAccent,
                    size: 22,
                  ),
                ),
              );
            },
          ),
          // User Info (Avatar + Tooltip de Perfil + Modal de Detalles)
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ListenableBuilder(
              listenable: RaphAuthController.instance,
              builder: (context, _) {
                final user = RaphAuthController.instance.currentUser;
                final nombre = (user?.nombre ?? '').trim();
                final apellido = (user?.apellido ?? '').trim();
                final email = (user?.email ?? '').trim();

                String displayName = 'Operador';
                if (nombre.isNotEmpty || apellido.isNotEmpty) {
                  displayName = '$nombre $apellido'.trim();
                } else if (email.isNotEmpty) {
                  displayName = email;
                }

                String initials = '';
                if (nombre.isNotEmpty && apellido.isNotEmpty) {
                  initials = '${nombre[0]}${apellido[0]}'.toUpperCase();
                } else if (nombre.isNotEmpty) {
                  initials = nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
                } else if (displayName.isNotEmpty && displayName != 'Operador') {
                  initials = displayName[0].toUpperCase();
                }

                String rolSubtitle = 'Guardia Operativa';
                if (user != null) {
                  final parts = <String>[];
                  if (user.roles.isNotEmpty) {
                    parts.add(user.roles.join(', '));
                  }
                  if (user.nombreOrganismo != null && user.nombreOrganismo!.isNotEmpty) {
                    parts.add(user.nombreOrganismo!);
                  }
                  if (parts.isNotEmpty) {
                    rolSubtitle = parts.join(' • ');
                  }
                }

                final estaAutenticado = user != null ||
                    (RaphAuthController.instance.token != null &&
                        RaphAuthController.instance.token!.isNotEmpty);

                return HoverRightTooltip(
                  customContent: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: estaAutenticado ? Colors.greenAccent : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rolSubtitle,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Clic para ver perfil',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _mostrarDialogoPerfil(
                      context,
                      user: user,
                      displayName: displayName,
                      subtitle: rolSubtitle,
                      email: email,
                      initials: initials,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          radius: 20,
                          child: initials.isNotEmpty
                              ? Text(
                                  initials,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                )
                              : Icon(Icons.person, color: theme.colorScheme.primary, size: 24),
                        ),
                        if (estaAutenticado)
                          Positioned(
                            bottom: -1,
                            right: -1,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class HoverRightTooltip extends StatefulWidget {
  final Widget child;
  final String? message;
  final Widget? customContent;
  const HoverRightTooltip({
    super.key,
    required this.child,
    this.message,
    this.customContent,
  });

  @override
  State<HoverRightTooltip> createState() => _HoverRightTooltipState();
}

class _HoverRightTooltipState extends State<HoverRightTooltip> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.show(),
      onExit: (_) => _controller.hide(),
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _controller,
          overlayChildBuilder: (context) {
            final theme = Theme.of(context);
            return CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.centerRight,
              followerAnchor: Alignment.centerLeft,
              offset: const Offset(16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: widget.customContent != null
                        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2430),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.6),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: widget.customContent ??
                        Text(
                          widget.message ?? '',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

Future<void> _mostrarDialogoPerfil(
  BuildContext context, {
  required UserData? user,
  required String displayName,
  required String subtitle,
  required String email,
  required String initials,
}) {
  final theme = Theme.of(context);
  final token = RaphAuthController.instance.token;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => PointerInterceptor(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2430),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar con initials o ícono
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: initials.isNotEmpty
                        ? Text(
                            initials,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          )
                        : Icon(Icons.person, color: theme.colorScheme.primary, size: 36),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E2430), width: 2.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Nombre
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              // Rol / Dependencia
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Colors.white12),
              const SizedBox(height: 16),
              // Datos de la cuenta
              if (email.isNotEmpty)
                _buildPerfilInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Correo Electrónico',
                  value: email,
                ),
              if (user?.nombreOrganismo != null && user!.nombreOrganismo!.isNotEmpty)
                _buildPerfilInfoRow(
                  icon: Icons.business_rounded,
                  label: 'Organismo',
                  value: user.nombreOrganismo!,
                ),
              if (user != null && user.roles.isNotEmpty)
                _buildPerfilInfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Roles / Permisos',
                  value: user.roles.join(', '),
                ),
              _buildPerfilInfoRow(
                icon: Icons.shield_outlined,
                label: 'Estado de Sesión',
                value: token != null && token.isNotEmpty
                    ? 'Conectado y Autenticado'
                    : 'Sin Token de Acceso',
              ),
              const SizedBox(height: 20),
              // Botones de Acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ),
                  if (RaphAuthController.instance.session != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await RaphAuthController.instance.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.2),
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Salir'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildPerfilInfoRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


Future<bool?> _mostrarDialogoDescartarBorrador(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => PointerInterceptor(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2430),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.amber.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.amber.withOpacity(0.08),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Badge con Ícono
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.highlight_off_rounded,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              // Título
              const Text(
                'Cerrar Incidente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              // Descripción
              Text(
                '¿Estás seguro de que deseas cerrar este incidente y limpiar la atención actual?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Acciones (Botones)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.amber.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cerrar Incidente',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

