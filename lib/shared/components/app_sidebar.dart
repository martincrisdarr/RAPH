import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
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
                                      onTap: () => onItemSelected(0),
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
          // User Info (Avatar Only)
          const Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: HoverRightTooltip(
              message: 'Operador 1\nGuardia Nocturna',
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                radius: 20,
                child: Icon(Icons.person, color: theme.colorScheme.primary, size: 24),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class HoverRightTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  const HoverRightTooltip({super.key, required this.child, required this.message});

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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.8)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
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

