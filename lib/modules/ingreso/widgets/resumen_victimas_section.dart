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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: victimas.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 32),
      itemBuilder: (context, index) {
        final victima = victimas[index];
        return _buildVictimaTile(theme, index + 1, victima);
      },
    );
  }

  Widget _buildVictimaTile(ThemeData theme, int number, VictimaData victima) {
    // Triage Code Color
    Color codeColor;
    switch (victima.codigoTriage) {
      case 'Rojo':
        codeColor = Colors.red.shade600;
        break;
      case 'Amarillo':
        codeColor = Colors.yellow.shade700;
        break;
      case 'Verde':
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
