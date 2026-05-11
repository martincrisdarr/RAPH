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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Spacer / Arrow
            return const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white24,
                    size: 16,
                  ),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isSelected = stepIndex == currentStep;
          final isPast = stepIndex < currentStep;

          return GestureDetector(
            onTap: onStepTapped != null ? () => onStepTapped!(stepIndex) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                        ? theme.colorScheme.primary.withOpacity(0.1) 
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${stepIndex + 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : Colors.white54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[stepIndex],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
