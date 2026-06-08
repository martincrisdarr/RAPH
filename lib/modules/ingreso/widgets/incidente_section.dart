import 'package:flutter/material.dart';
import '../controllers/ingreso_controller.dart';

class IncidenteSection extends StatefulWidget {
  final VoidCallback? onDespacho;
  const IncidenteSection({super.key, this.onDespacho});

  @override
  State<IncidenteSection> createState() => _IncidenteSectionState();
}

class _IncidenteSectionState extends State<IncidenteSection> {
  final _ingresoController = IngresoController();
  late final TextEditingController _descripcionIncidenteController;
  
  final List<Map<String, dynamic>> _protocolosSugeridos = [
    {'nombre': 'Accidente Vehicular', 'color': Colors.red.shade400},
    {'nombre': 'Derrumbe', 'color': Colors.red.shade400},
    {'nombre': 'Catástrofe', 'color': Colors.red.shade400},
    {'nombre': 'Gases Tóxicos', 'color': Colors.red.shade400},
    {'nombre': 'Incendio', 'color': Colors.red.shade400},
    {'nombre': 'Accidente Industrial', 'color': Colors.red.shade400},
  ];
  final List<String> _protocolosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _descripcionIncidenteController = TextEditingController(text: _ingresoController.incidenteActual.descripcion ?? '');
    _ingresoController.addListener(_onControllerUpdate);
  }

  int? _lastIncidenteId;

  void _onControllerUpdate() {
    if (mounted) {
      final incidente = _ingresoController.incidenteActual;
      
      // Sincronización de descripción
      if (incidente.idIncidente != _lastIncidenteId) {
        _lastIncidenteId = incidente.idIncidente;
        _descripcionIncidenteController.text = incidente.descripcion ?? '';
      } else {
        final nuevaDesc = incidente.descripcion ?? '';
        if (_descripcionIncidenteController.text != nuevaDesc) {
          _descripcionIncidenteController.text = nuevaDesc;
        }
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    _descripcionIncidenteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Protocolos rápidos:', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _protocolosSugeridos.map((protoData) {
                final protocolo = protoData['nombre'] as String;
                final color = protoData['color'] as Color;
                final isSelected = _protocolosSeleccionados.contains(protocolo);
                
                return ActionChip(
                  label: Text(
                    protocolo, 
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : color.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isSelected 
                      ? color.withOpacity(0.4) 
                      : color.withOpacity(0.1),
                  side: BorderSide(
                    color: isSelected ? color : color.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    setState(() {
                      if (isSelected) {
                        _protocolosSeleccionados.remove(protocolo);
                      } else {
                        _protocolosSeleccionados.add(protocolo);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextFormField(
              controller: _descripcionIncidenteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (val) => _ingresoController.updateIncidente(descripcion: val),
              decoration: InputDecoration(
                labelText: 'Descripción del incidente',
                alignLabelWithHint: true,
                hintText: 'Ingresá los detalles del incidente...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.02),
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
          if (widget.onDespacho != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: widget.onDespacho,
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('DESPACHO RÁPIDO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary, width: 1.0),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
