import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';

/// Ítems de menú disponibles en la sidebar de la app.
enum AppMenuItem {
  despacho,
  listado,
  ingreso,
}

/// Sidebar lateral izquierda reutilizable.
///
/// Muestra un menú vertical con ítems:
/// - DESPACHO
/// - LISTADO
/// - INGRESO
///
/// Solo maneja UI y callbacks, sin navegación interna ni lógica de negocio.
class AppSidebar extends StatelessWidget {
  final AppMenuItem selectedItem;
  final ValueChanged<AppMenuItem> onItemSelected;

  const AppSidebar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border(
            right: BorderSide(
              color: AppColors.border.withOpacity(0.9),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.60),
              blurRadius: 28,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: SafeArea(
          right: false,
          bottom: false,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _SidebarItem(
                  icon: Icons.login,
                  label: 'INGRESO',
                  isSelected: selectedItem == AppMenuItem.ingreso,
                  onTap: () => onItemSelected(AppMenuItem.ingreso),
                ),
                _SidebarItem(
                  icon: Icons.list_alt,
                  label: 'LISTADO',
                  isSelected: selectedItem == AppMenuItem.listado,
                  onTap: () => onItemSelected(AppMenuItem.listado),
                ),
                _SidebarItem(
                  icon: Icons.local_phone,
                  label: 'DESPACHO',
                  isSelected: selectedItem == AppMenuItem.despacho,
                  onTap: () => onItemSelected(AppMenuItem.despacho),
                ),
                const Spacer(),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                const Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SidebarFooterBadge(
                        initials: 'SE',
                        label:
                            'Secretaría de Emergencias y Gestión de Riesgos',
                        badgeColor: AppColors.accentBlue,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _SidebarFooterBadge(
                        initials: 'GN',
                        label: 'Gobierno de la Provincia de Neuquén',
                        badgeColor: AppColors.accentGreen,
                      ),
                    ],
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

/// Item de menú con estilo botón/card.
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color borderColor =
        isSelected ? colorScheme.primary : AppColors.border;
    // Mantener el mismo grosor de borde para evitar "saltos" visuales.
    final double borderWidth = 1.2;
    final Color textColor =
        isSelected ? AppColors.textPrimary : AppColors.textSecondary;
    final Color iconColor =
        isSelected ? AppColors.textPrimary : AppColors.textSecondary;

    final Color badgeBackground = isSelected
        ? colorScheme.primary.withOpacity(0.24)
        : AppColors.surface;
    final Color badgeIconColor = isSelected
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    final Color itemBackground =
        isSelected ? AppColors.surface : Colors.transparent;
    final Duration itemDuration =
        isSelected ? AppDurations.medium : Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: AnimatedContainer(
            duration: itemDuration,
            curve: Curves.easeOut,
            height: 50,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: itemBackground,
              border: Border.all(color: borderColor, width: borderWidth),
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.26),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, size: 18, color: badgeIconColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Badge institucional para el footer (placeholder de logo).
class _SidebarFooterBadge extends StatelessWidget {
  final String initials;
  final String label;
  final Color badgeColor;

  const _SidebarFooterBadge({
    required this.initials,
    required this.label,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              initials,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
