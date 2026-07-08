import 'package:flutter/material.dart';
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
                              child: HoverRightTooltip(
                                message: 'Continuar Borrador',
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
                                          : Colors.transparent,
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

