import 'dart:async';
import 'package:flutter/material.dart';

class MovilStatus {
  final String nombre;
  String status;
  DateTime lastStatusChange;

  MovilStatus({
    required this.nombre,
    required this.status,
    DateTime? lastStatusChange,
  }) : lastStatusChange = lastStatusChange ?? DateTime.now();
}

class KanbanCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String time;
  final String priority;
  final Color priorityColor;
  final List<MovilStatus> moviles;
  final String globalStatus;

  const KanbanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.moviles,
    required this.globalStatus,
    this.priority = 'Media',
    this.priorityColor = Colors.orange,
  });

  @override
  State<KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<KanbanCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Update every 10 seconds to keep durations updated
    _ticker = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _getElapsedTime(DateTime lastChange) {
    final difference = DateTime.now().difference(lastChange);
    final minutes = difference.inMinutes;
    if (minutes <= 0) {
      final seconds = difference.inSeconds;
      if (seconds < 0) return '0 seg';
      return '$seconds seg';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final cardContent = LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: widget.priorityColor.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.priorityColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: widget.priorityColor.withOpacity(0.5), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.priority,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: widget.priorityColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.globalStatus != 'Llamada recibida')
                    Text(
                      widget.time,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              if (widget.globalStatus != 'Llamada recibida') ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 12),
                Column(
                  children: [
                    for (int index = 0; index < widget.moviles.length; index++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 75.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_shipping, size: 14, color: theme.colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.moviles[index].nombre,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 56),
                            if (widget.globalStatus == 'En curso') ...[
                              _buildTimelineForMovil(theme, widget.moviles[index], cardWidth),
                            ],
                            const Spacer(),
                            if (widget.globalStatus == 'En curso') ...[
                              _buildTimeElapsedBadge(theme, widget.moviles[index]),
                              const SizedBox(width: 8),
                            ],
                            if (widget.globalStatus == 'Llamada recibida' && index == 0) ...[
                              const Icon(Icons.more_horiz, size: 18, color: Colors.white30),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: cardContent,
    );
  }

  Widget _buildTimelineForMovil(ThemeData theme, MovilStatus movil, double cardWidth) {
    const steps = ['Despachado', 'En sitio', 'Traslado', 'Arribado'];
    final activeIndex = steps.indexOf(movil.status);
    final isFinalizado = movil.status == 'Finalizado' || widget.globalStatus == 'Finalizado';

    const double timelineWidth = 120.0;
    final double stepSpacing = (timelineWidth - 50.0) / 3;

    return SizedBox(
      width: timelineWidth,
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // 1. Línea de fondo (gris)
          Positioned(
            left: 5,
            width: 3 * stepSpacing,
            top: 9,
            height: 2,
            child: Container(
              color: Colors.white10,
            ),
          ),
          
          // 2. Línea de progreso (azul primario)
          if (isFinalizado)
            Positioned(
              left: 5,
              width: 3 * stepSpacing,
              top: 9,
              height: 2,
              child: Container(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            )
          else if (activeIndex != -1 && activeIndex > 0)
            Positioned(
              left: 5,
              width: activeIndex * stepSpacing,
              top: 9,
              height: 2,
              child: Container(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),

          // 3. Círculos de los pasos (Interactivos)
          for (int i = 0; i < 4; i++) ...[
            () {
              final isStepActive = i == activeIndex;
              final isStepCompleted = isFinalizado || (activeIndex != -1 && i < activeIndex);
              final double size = isStepActive ? 10.0 : 6.0;
              final double leftOffset = i * stepSpacing + (isStepActive ? 0.0 : 2.0);

              return Positioned(
                left: leftOffset - (12.0 - (size / 2)),
                top: 10.0 - 12.0,
                width: 24.0,
                height: 24.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      movil.status = steps[i];
                      movil.lastStatusChange = DateTime.now();
                    });
                  },
                  child: Center(
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: (isStepActive || isStepCompleted)
                            ? theme.colorScheme.primary
                            : Colors.white24,
                        shape: BoxShape.circle,
                        boxShadow: isStepActive
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }(),
          ],

          // 4. Etiqueta de texto para el paso activo (siempre a la derecha)
          if (activeIndex != -1)
            Positioned(
              left: activeIndex * stepSpacing + 14.0,
              top: 3,
              child: Text(
                steps[activeIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeElapsedBadge(ThemeData theme, MovilStatus movil) {
    const steps = ['Despachado', 'En sitio', 'Traslado', 'Arribado'];
    final activeIndex = steps.indexOf(movil.status);
    if (activeIndex == -1) {
      return const SizedBox.shrink();
    }

    return Text(
      _getElapsedTime(movil.lastStatusChange),
      style: theme.textTheme.labelSmall?.copyWith(
        color: Colors.white38,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    );
  }
}
