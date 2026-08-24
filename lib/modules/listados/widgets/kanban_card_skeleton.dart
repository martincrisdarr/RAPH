import 'package:flutter/material.dart';

class KanbanCardSkeleton extends StatefulWidget {
  const KanbanCardSkeleton({super.key});

  @override
  State<KanbanCardSkeleton> createState() => _KanbanCardSkeletonState();
}

class _KanbanCardSkeletonState extends State<KanbanCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.white.withOpacity(0.20) : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        final shimmerOpacity = _opacityAnimation.value;
        final boxColor = Color.lerp(baseColor, highlightColor, shimmerOpacity)!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222634) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Prioridad badge + Tiempo skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 70,
                    height: 22,
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title skeleton (Dirección / Título)
              Container(
                width: double.infinity,
                height: 18,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle skeleton (Descripción)
              FractionallySizedBox(
                widthFactor: 0.85,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer: Móviles asignados skeleton chips
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 26,
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 65,
                    height: 26,
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
