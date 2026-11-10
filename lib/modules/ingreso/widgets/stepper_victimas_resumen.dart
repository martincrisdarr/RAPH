import 'package:flutter/material.dart';
import '../../../shared/models/victima_despacho_resumen.dart';
import '../../../shared/theme/app_theme_tokens.dart';
import '../controllers/ingreso_controller.dart';

class StepperVictimasResumen extends StatelessWidget {
  final List<VictimaDespachoResumen> items;

  const StepperVictimasResumen({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final finalizedCount = items.where((i) => i.isFinalizado).length;
    final totalCount = items.length;
    final allFinalized = finalizedCount == totalCount && totalCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt.withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: allFinalized
              ? AppColors.accentGreen.withOpacity(0.4)
              : AppColors.border,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 16,
                color: allFinalized ? AppColors.accentGreen : AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'DESPACHOS POR VÍCTIMA',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: allFinalized
                      ? AppColors.accentGreen.withOpacity(0.15)
                      : AppColors.accentBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  border: Border.all(
                    color: allFinalized
                        ? AppColors.accentGreen.withOpacity(0.4)
                        : AppColors.accentBlue.withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (allFinalized) ...[
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: AppColors.accentGreen),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      allFinalized
                          ? 'Todas finalizadas ($finalizedCount/$totalCount)'
                          : '$finalizedCount de $totalCount finalizadas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: allFinalized
                            ? AppColors.accentGreen
                            : AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: items.map((item) {
              return _buildVictimaChip(context, item);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVictimaChip(BuildContext context, VictimaDespachoResumen item) {
    final controller = IngresoController();
    final isSelected = controller.selectedVictimaIndex == (item.index - 1);

    return InkWell(
      onTap: () {
        if (item.index - 1 < controller.victimas.length) {
          controller.selectedVictimaIndex = item.index - 1;
        }
      },
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: item.isFinalizado
              ? const Color(0xFF10B981).withOpacity(0.08)
              : isSelected
                  ? AppColors.accentBlue.withOpacity(0.12)
                  : const Color(0xFF161F30),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: item.isFinalizado
                ? const Color(0xFF10B981).withOpacity(0.4)
                : isSelected
                    ? AppColors.accentBlue.withOpacity(0.6)
                    : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge V1 / V2 con color de triage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.triageColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: item.triageColor, width: 1),
              ),
              child: Text(
                'V${item.index}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: item.triageColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nombre de la víctima
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                item.nombre,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('•', style: TextStyle(color: Colors.white24, fontSize: 12)),
            const SizedBox(width: 8),
            // Móvil asignado
            if (item.movilNombre != null) ...[
              const Icon(
                Icons.directions_car_rounded,
                size: 13,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                item.movilNombre!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ] else ...[
              const Text(
                'Sin móvil',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(width: 8),
            // Chip de estado operativo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.estadoColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: item.estadoColor.withOpacity(0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.estadoIcon,
                    size: 11,
                    color: item.estadoColor,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      item.estadoLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.estadoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

