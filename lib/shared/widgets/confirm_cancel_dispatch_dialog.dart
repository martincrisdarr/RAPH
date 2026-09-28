import 'package:flutter/material.dart';
import '../theme/app_theme_tokens.dart';

class ConfirmCancelDispatchDialog extends StatelessWidget {
  final String movilNombre;
  final String? victimaNombre;
  final String? detalle;

  const ConfirmCancelDispatchDialog({
    super.key,
    required this.movilNombre,
    this.victimaNombre,
    this.detalle,
  }) : super();

  /// Muestra el modal de confirmación y retorna `true` si el usuario confirma la cancelación.
  static Future<bool> show(
    BuildContext context, {
    required String movilNombre,
    String? victimaNombre,
    String? detalle,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ConfirmCancelDispatchDialog(
        movilNombre: movilNombre,
        victimaNombre: victimaNombre,
        detalle: detalle,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: AppColors.accentRed.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.accentRed.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con Icono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.accentRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CANCELAR DESPACHO',
                        style: TextStyle(
                          color: AppColors.accentRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '¿Confirmar cancelación?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Tarjeta de detalles del despacho a cancelar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.airport_shuttle, size: 16, color: AppColors.accentBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Móvil: $movilNombre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  if (victimaNombre != null && victimaNombre!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Víctima: $victimaNombre',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (detalle != null && detalle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      detalle!,
                      style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Mensaje explicativo del efecto
            const Text(
              'Esta acción cambiará el estado del despacho a Cancelado (Activo: 2) y liberará la unidad para que quede Disponible en base.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 22),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Volver', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                  ),
                  icon: const Icon(Icons.delete_forever_outlined, size: 16),
                  label: const Text(
                    'Sí, cancelar despacho',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
