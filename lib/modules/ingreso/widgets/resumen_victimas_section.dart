import 'package:flutter/material.dart';
import '../controllers/ingreso_controller.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/services/configuracion_service.dart';

class ResumenVictimasSection extends StatefulWidget {
  const ResumenVictimasSection({super.key});

  @override
  State<ResumenVictimasSection> createState() => _ResumenVictimasSectionState();
}

class _ResumenVictimasSectionState extends State<ResumenVictimasSection> {
  final _ingresoController = IngresoController();
  Map<int, String> _generosMap = {};

  @override
  void initState() {
    super.initState();
    _ingresoController.addListener(_onControllerUpdate);
    _cargarGeneros();
  }

  Future<void> _cargarGeneros() async {
    try {
      final generos = await ConfiguracionService.obtenerGeneros();
      if (mounted) {
        setState(() {
          _generosMap = {
            for (var g in generos) g.idconfiguracion: g.descripcion,
          };
        });
      }
    } catch (e) {
      // Ignorar errores de red en la carga informativa de géneros
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final victimas = _ingresoController.victimas;

    if (victimas.isEmpty) {
      return const Center(
        child: Text(
          'No hay víctimas registradas',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: victimas.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 32),
        itemBuilder: (context, index) {
          final victima = victimas[index];
          return _buildVictimaTile(theme, index + 1, victima);
        },
      ),
    );
  }

  Map<String, dynamic>? _obtenerDespachoDeVictima(VictimaData victima, int index) {
    final despachos = _ingresoController.despachosActivos;
    if (despachos.isEmpty) return null;

    if (victima.idVictima != null) {
      for (final d in despachos.reversed) {
        final dVic = int.tryParse(d['idvictima']?.toString() ?? '');
        if (dVic == victima.idVictima) {
          return d;
        }
      }
    }
    if (victima.idMovilAsignado != null && victima.idMovilAsignado!.isNotEmpty) {
      for (final d in despachos.reversed) {
        final dM = (d['idmovil'] ?? d['idmovilunidad'])?.toString();
        if (dM == victima.idMovilAsignado) {
          return d;
        }
      }
    }
    // Si solo hay 1 víctima y un despacho sin idvictima explícito (ej. Código Rojo), asociarlo visualmente
    if (_ingresoController.victimas.length == 1 && index == 1) {
      return despachos.last;
    }
    return null;
  }

  String _formatearEstadoOperativo(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'en_camino':
      case 'en camino':
        return 'En Camino';
      case 'en_sitio':
      case 'en sitio':
        return 'En Sitio';
      case 'traslado':
      case 'en_traslado':
        return 'En Traslado';
      case 'en_hospital':
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Despachado';
    }
  }

  Color _colorEstadoOperativo(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'en_sitio':
      case 'en sitio':
        return const Color(0xFF06B6D4); // Cyan
      case 'traslado':
      case 'en_traslado':
        return const Color(0xFFA855F7); // Violeta
      case 'en_hospital':
      case 'finalizado':
        return const Color(0xFF10B981); // Verde
      default:
        return const Color(0xFFFF9800); // Naranja Despachado / En camino
    }
  }

  Widget _buildVictimaTile(ThemeData theme, int number, VictimaData victima) {
    final despacho = _obtenerDespachoDeVictima(victima, number);
    String? movilNombre;
    String? estadoOp;
    String? hospitalNombre;

    if (despacho != null) {
      estadoOp = (despacho['estado_operativo'] ?? 'despachado').toString();
      hospitalNombre = despacho['hospital_nombre']?.toString();
      if (despacho['movilunidad'] is Map) {
        final mu = despacho['movilunidad'] as Map;
        if (mu['movil'] is Map && mu['movil']['nombre'] != null) {
          movilNombre = mu['movil']['nombre'].toString();
        } else if (mu['patente'] != null) {
          movilNombre = 'Unidad ${mu['patente']}';
        }
      }
      movilNombre ??= 'Móvil asignado';
    }
    final triageVictima = victima.codigoTriage?.trim();
    final triageIncidente = _ingresoController.incidenteActual.codigoTriage?.trim();
    final idConfCodigoIncidente = _ingresoController.incidenteActual.idConfCodigo;
    final tieneProtocolos = _ingresoController.protocolosSeleccionados.isNotEmpty;

    String? effectiveTriage = (triageVictima != null && triageVictima.isNotEmpty) ? triageVictima : null;
    if (effectiveTriage == null) {
      if (tieneProtocolos || idConfCodigoIncidente == 29 || idConfCodigoIncidente == 135 || triageIncidente?.toLowerCase() == 'rojo') {
        effectiveTriage = 'Rojo';
      } else if (idConfCodigoIncidente == 30 || triageIncidente?.toLowerCase() == 'amarillo') {
        effectiveTriage = 'Amarillo';
      } else if (idConfCodigoIncidente == 31 || triageIncidente?.toLowerCase() == 'verde') {
        effectiveTriage = 'Verde';
      } else if (idConfCodigoIncidente == 63 || (triageIncidente != null && triageIncidente.toLowerCase().contains('sin'))) {
        effectiveTriage = 'Sin código';
      }
    }

    // Triage Code Color
    Color codeColor;
    switch (effectiveTriage?.toLowerCase()) {
      case 'rojo':
        codeColor = Colors.red.shade600;
        break;
      case 'amarillo':
        codeColor = Colors.yellow.shade700;
        break;
      case 'verde':
        codeColor = Colors.green.shade600;
        break;
      default:
        codeColor = Colors.white24;
    }

    final nombreCompleto = victima.nombre.trim();
    final String nombreDisplay = nombreCompleto.isNotEmpty ? nombreCompleto : 'Víctima $number';

    // Generar info string
    final List<String> detalles = [];
    if (victima.dni.trim().isNotEmpty) {
      detalles.add('DNI: ${victima.dni}');
    }
    if (victima.edad.trim().isNotEmpty) {
      detalles.add('${victima.edad} años');
    }
    if (victima.idConfGenero != null) {
      final genStr = _generosMap[victima.idConfGenero];
      if (genStr != null) {
        detalles.add(genStr);
      }
    }
    final String infoDisplay = detalles.isNotEmpty ? detalles.join(' • ') : 'Sin datos básicos';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Triage Badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: codeColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: codeColor, width: 2.5),
          ),
          child: Center(
            child: Text(
              'V$number',
              style: TextStyle(
                color: codeColor == Colors.white24 ? Colors.white70 : codeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Victim Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreDisplay,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                infoDisplay,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
              if (victima.observaciones.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  victima.observaciones,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ],
              if (movilNombre != null && estadoOp != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _colorEstadoOperativo(estadoOp).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _colorEstadoOperativo(estadoOp).withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            size: 13,
                            color: _colorEstadoOperativo(estadoOp),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$movilNombre • ${_formatearEstadoOperativo(estadoOp)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _colorEstadoOperativo(estadoOp),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hospitalNombre != null && hospitalNombre.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_hospital_rounded,
                              size: 13,
                              color: Color(0xFF00E5FF),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              hospitalNombre,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              if (victima.isCerrada) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 13, color: Color(0xFF10B981)),
                          SizedBox(width: 5),
                          Text(
                            'CIERRE DE VÍCTIMA COMPLETADO',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        victima.reporte ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ] else if (_ingresoController.isVictimaAtencionFinalizada(number - 1)) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    _ingresoController.selectedVictimaIndex = number - 1;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_actions_rounded, size: 13, color: Colors.amberAccent),
                        SizedBox(width: 5),
                        Text(
                          'Pendiente de cierre individual',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (victima.sintomasSeleccionados.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: victima.sintomasSeleccionados.map((sintoma) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 0.5),
                      ),
                      child: Text(
                        sintoma,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
