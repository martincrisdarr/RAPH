import 'package:flutter/material.dart';

class IncidenteSection extends StatefulWidget {
  const IncidenteSection({super.key});

  @override
  State<IncidenteSection> createState() => _IncidenteSectionState();
}

class _IncidenteSectionState extends State<IncidenteSection> {
  final TextEditingController _descripcionIncidenteController = TextEditingController();
  final List<Map<String, dynamic>> _etiquetasSugeridas = [
    {'nombre': 'Caída', 'color': Colors.yellow.shade300},
    {'nombre': 'Tránsito', 'color': Colors.yellow.shade300},
    {'nombre': 'Arma blanca', 'color': Colors.red.shade300},
    {'nombre': 'Arma de fuego', 'color': Colors.red.shade300},
    {'nombre': 'Inconsciente', 'color': Colors.red.shade300},
    {'nombre': 'Cardíaco', 'color': Colors.red.shade300},
    {'nombre': 'Respiratorio', 'color': Colors.yellow.shade300},
    {'nombre': 'Quemadura', 'color': Colors.yellow.shade300},
    {'nombre': 'Vía Pública', 'color': Colors.green.shade300},
    {'nombre': 'Domicilio', 'color': Colors.green.shade300},
  ];
  final List<String> _etiquetasSeleccionadas = [];

  @override
  void dispose() {
    _descripcionIncidenteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TextFormField(
            controller: _descripcionIncidenteController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              labelText: 'Descripción del incidente',
              alignLabelWithHint: true,
              hintText: 'Ingresá los detalles del incidente...',
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Etiquetas rápidas:', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white54)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _etiquetasSugeridas.map((etiquetaData) {
              final etiqueta = etiquetaData['nombre'] as String;
              final color = etiquetaData['color'] as Color;
              final isSelected = _etiquetasSeleccionadas.contains(etiqueta);
              
              return ActionChip(
                label: Text(
                  etiqueta, 
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
                      _etiquetasSeleccionadas.remove(etiqueta);
                    } else {
                      _etiquetasSeleccionadas.add(etiqueta);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
