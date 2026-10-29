import 'package:flutter/material.dart';

class CustomStepper extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  const CustomStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
  });

  Color _getStepColor(int stepIndex, ThemeData theme) {
    switch (stepIndex) {
      case 0:
        return const Color(0xFF3B82F6); // Incidente (Blue)
      case 1:
        return const Color(0xFFF59E0B); // Despacho (Amber / Orange)
      case 2:
        return const Color(0xFF06B6D4); // En sitio (Cyan)
      case 3:
        return const Color(0xFF8B5CF6); // Traslado (Purple / Violet)
      case 4:
        return const Color(0xFF10B981); // Fin (Emerald / Green)
      case 5:
        return const Color(0xFFEF4444); // Cierre (Red / Rose)
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Conector con línea y flecha entre pasos
            final beforeStepIndex = index ~/ 2;
            final isTraversed = beforeStepIndex < currentStep;
            final activeArrowColor = _getStepColor(beforeStepIndex, theme);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: isTraversed
                              ? activeArrowColor.withValues(alpha: 0.75)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: isTraversed ? activeArrowColor : Colors.white12,
                      size: 14,
                    ),
                  ],
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCurrent = stepIndex == currentStep;
          final isPast = stepIndex < currentStep;
          final stepColor = _getStepColor(stepIndex, theme);

          final stepContent = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Círculo del paso
              if (isCurrent)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stepColor,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: stepColor.withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${stepIndex + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else if (isPast)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stepColor.withValues(alpha: 0.22),
                    border: Border.all(
                      color: stepColor,
                      width: 1.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: stepColor,
                      size: 18,
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: Colors.white24,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${stepIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 6),

              // 2. Etiqueta de texto del paso
              Text(
                steps[stepIndex],
                style: TextStyle(
                  color: isCurrent
                      ? Colors.white
                      : (isPast ? Colors.white.withValues(alpha: 0.88) : Colors.white38),
                  fontWeight: isCurrent
                      ? FontWeight.bold
                      : (isPast ? FontWeight.w600 : FontWeight.normal),
                  fontSize: isCurrent ? 12.5 : 12,
                  letterSpacing: isCurrent ? 0.3 : 0.0,
                ),
              ),

              const SizedBox(height: 3),

              // 3. Mini indicador de estado (fijo para alineación vertical)
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: stepColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: stepColor.withValues(alpha: 0.7),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'ACTUAL',
                    style: TextStyle(
                      color: stepColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                )
              else
                const SizedBox(height: 15), // Mantiene la altura equilibrada
            ],
          );

          if (onStepTapped != null) {
            return GestureDetector(
              onTap: () => onStepTapped!(stepIndex),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: stepContent,
              ),
            );
          }

          return stepContent;
        }),
      ),
    );
  }
}
