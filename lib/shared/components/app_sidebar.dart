import 'package:flutter/material.dart';

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
    SidebarItem(icon: Icons.add_box_rounded, label: 'Ingreso'),
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
              child: Column(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isSelected = selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: HoverRightTooltip(
                      message: item.label,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onItemSelected(index),
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
                  );
                }),
              ),
            ),
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

