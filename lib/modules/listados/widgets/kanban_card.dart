import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/services/despacho_service.dart';

class MovilStatus {
  final int? idDespacho;
  final String nombre;
  String status;
  DateTime lastStatusChange;
  final String? victimaNombre;
  final String? hospitalNombre;
  final bool tieneMovil;

  MovilStatus({
    this.idDespacho,
    required this.nombre,
    required this.status,
    DateTime? lastStatusChange,
    this.victimaNombre,
    this.hospitalNombre,
    this.tieneMovil = true,
  }) : lastStatusChange = lastStatusChange ?? DateTime.now();
}

class KanbanCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String time;
  final String? priority;
  final Color priorityColor;
  final List<MovilStatus> moviles;
  final String globalStatus;

  final VoidCallback? onTap;

  final String? description;
  final String? address;

  const KanbanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    this.priority,
    required this.priorityColor,
    required this.moviles,
    required this.globalStatus,
    this.description,
    this.address,
    this.onTap,
  });

  @override
  State<KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<KanbanCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getElapsedTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final cardContent = Ink(
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.priority != null && widget.priority!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.priorityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: widget.priorityColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.priority!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.globalStatus == 'Cerrado') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            'CERRADO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.time.isNotEmpty)
                Text(
                  widget.time,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if ((widget.globalStatus == 'En curso' || widget.globalStatus == 'Finalizado' || widget.globalStatus == 'Cerrado') && widget.moviles.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 10),
            Column(
              children: [
                for (int index = 0; index < widget.moviles.length; index++) ...[
                  _buildVictimaMovilRow(theme, widget.moviles[index]),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: cardContent,
        ),
      ),
    );
  }

  Widget _buildVictimaMovilRow(ThemeData theme, MovilStatus m) {
    final hasVictimName = m.victimaNombre != null && m.victimaNombre!.isNotEmpty;
    final hasHospital = m.hospitalNombre != null && m.hospitalNombre!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasVictimName) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        m.victimaNombre!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (m.tieneMovil) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_rounded, size: 13, color: theme.colorScheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        m.nombre,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildTimelineForMovil(theme, m),
                const SizedBox(width: 8),
                _buildTimeElapsedBadge(theme, m),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.orangeAccent),
                      const SizedBox(width: 5),
                      Text(
                        'Sin móvil asignado',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 2,
                    color: Colors.orangeAccent.withOpacity(0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pendiente',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orangeAccent.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (hasHospital) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_hospital_rounded, size: 11, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Destino: ${m.hospitalNombre}',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineForMovil(ThemeData theme, MovilStatus movil) {
    const steps = ['Despachado', 'En sitio', 'Traslado', 'Finalizado'];
    final bool isCerrado = movil.status == 'Cerrado' || widget.globalStatus == 'Cerrado';
    final int activeIndex = (movil.status == 'Arribado' || isCerrado) ? 3 : steps.indexOf(movil.status);
    final isFinalizado = isCerrado || movil.status == 'Finalizado' || movil.status == 'Arribado' || widget.globalStatus == 'Finalizado';
    final Color activeColor = isFinalizado ? const Color(0xFF10B981) : theme.colorScheme.primary;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final double startOffset = 6.0;
          final double endOffset = 6.0;
          final double availableLine = totalWidth - startOffset - endOffset;
          final double stepSpacing = availableLine > 0 ? availableLine / 3 : 25.0;

          return SizedBox(
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // 1. Línea de fondo (gris)
                Positioned(
                  left: startOffset,
                  right: endOffset,
                  top: 11,
                  height: 2,
                  child: Container(
                    color: Colors.white10,
                  ),
                ),
                
                // 2. Línea de progreso
                if (isFinalizado)
                  Positioned(
                    left: startOffset,
                    right: endOffset,
                    top: 11,
                    height: 2,
                    child: Container(
                      color: activeColor.withOpacity(0.6),
                    ),
                  )
                else if (activeIndex != -1 && activeIndex > 0)
                  Positioned(
                    left: startOffset,
                    width: activeIndex * stepSpacing,
                    top: 11,
                    height: 2,
                    child: Container(
                      color: activeColor.withOpacity(0.6),
                    ),
                  ),

                // 3. Círculos de los pasos (Interactivos)
                for (int i = 0; i < 4; i++) ...[
                  () {
                    final isStepActive = i == activeIndex;
                    final isStepCompleted = isFinalizado || (activeIndex != -1 && i < activeIndex);
                    final double size = isStepActive ? 10.0 : 6.0;
                    final double circleCenterLeft = startOffset + i * stepSpacing;

                    return Positioned(
                      left: circleCenterLeft - 12.0,
                      top: 0,
                      width: 24.0,
                      height: 24.0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final nuevoPasoLabel = steps[i];
                          setState(() {
                            movil.status = nuevoPasoLabel;
                            movil.lastStatusChange = DateTime.now();
                          });
                          if (movil.idDespacho != null) {
                            String backendEstado = 'despachado';
                            if (nuevoPasoLabel == 'En sitio') {
                              backendEstado = 'en_sitio';
                            } else if (nuevoPasoLabel == 'Traslado') {
                              backendEstado = 'traslado';
                            } else if (nuevoPasoLabel == 'Finalizado') {
                              backendEstado = 'finalizado';
                            }
                            await DespachoService.cambiarEstadoOperativo(
                              idDespacho: movil.idDespacho!,
                              estadoOperativo: backendEstado,
                            );
                          }
                        },
                        child: Center(
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: (isStepActive || isStepCompleted)
                                  ? activeColor
                                  : Colors.white24,
                              shape: BoxShape.circle,
                              boxShadow: isStepActive
                                  ? [
                                      BoxShadow(
                                        color: activeColor.withOpacity(0.6),
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

                // 4. Etiqueta de texto para el paso activo (ubicada sobre el paso activo)
                if (activeIndex != -1)
                  Positioned(
                    left: (startOffset + activeIndex * stepSpacing - 18.0).clamp(0.0, totalWidth - 62.0),
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: activeColor.withOpacity(0.4), width: 0.6),
                      ),
                      child: Text(
                        isCerrado ? 'Cerrado' : steps[activeIndex],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: activeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeElapsedBadge(ThemeData theme, MovilStatus movil) {
    const steps = ['Despachado', 'En sitio', 'Traslado', 'Finalizado'];
    final activeIndex = (movil.status == 'Arribado' || movil.status == 'Cerrado' || widget.globalStatus == 'Cerrado')
        ? 3
        : steps.indexOf(movil.status);
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
