import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/components/custom_select.dart';
import '../../../shared/models/configuracion.dart';
import '../../../shared/models/victima.dart';
import '../../../shared/services/configuracion_service.dart';
import '../../../shared/services/victima_service.dart';
import '../controllers/ingreso_controller.dart';

import '../../../shared/models/victima_data.dart';

class VictimasSection extends StatefulWidget {
  const VictimasSection({super.key});

  @override
  State<VictimasSection> createState() => _VictimasSectionState();
}

class _VictimasSectionState extends State<VictimasSection> {
  final _ingresoController = IngresoController();

  final List<String> _etiquetasSintomas = [
    'Dolor de pecho',
    'Convulsiones',
    'Intoxicación',
    'Traumatismo',
    'Dif. respiratoria',
    'Inconsciencia',
  ];

  @override
  void initState() {
    super.initState();
    _ingresoController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
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
    final index = _ingresoController.selectedVictimaIndex;
    
    if (index >= victimas.length) return const Center(child: CircularProgressIndicator());
    final victima = victimas[index];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTriageBanner(theme, index, victima),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: _buildBuscadorEtiquetasColumn(theme, index, victima),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildPreguntasRecomendacionesBox(theme, victima),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
                );

                if (result != null) {
                  setState(() {
                    victima.archivosAdjuntos.addAll(result.files);
                  });
                }
              },
              icon: const Icon(Icons.attach_file, size: 20),
              label: const Text(
                'Adjuntar documentación',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          if (victima.archivosAdjuntos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: victima.archivosAdjuntos.map((file) {
                return Chip(
                  label: Text(
                    file.name,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      victima.archivosAdjuntos.remove(file);
                    });
                  },
                  backgroundColor: theme.colorScheme.surface,
                  side: const BorderSide(color: Colors.white24),
                );
              }).toList().cast<Widget>(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTriageBanner(ThemeData theme, int index, VictimaData victima) {
    Color codeColor;
    String codeText;

    switch (victima.codigoTriage) {
      case 'Rojo':
        codeColor = Colors.red.shade600;
        codeText = 'ROJO - EMERGENCIA CRÍTICA';
        break;
      case 'Amarillo':
        codeColor = Colors.yellow.shade700;
        codeText = 'AMARILLO - URGENCIA';
        break;
      case 'Verde':
        codeColor = Colors.green.shade600;
        codeText = 'VERDE - NO URGENTE';
        break;
      default:
        codeColor = Colors.white24;
        codeText = 'SIN CÓDIGO';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: codeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: codeColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: codeColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'CÓDIGO ACTUAL (V${index + 1}): $codeText',
              style: theme.textTheme.titleMedium?.copyWith(
                color: codeColor == Colors.white24 ? Colors.white : codeColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          _buildTriageSelector(index, victima),
        ],
      ),
    );
  }

  Widget _buildTriageSelector(int index, VictimaData victima) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTriageOptionButton(index, victima, 'Verde', Colors.green),
        const SizedBox(width: 8),
        _buildTriageOptionButton(index, victima, 'Amarillo', Colors.yellow),
        const SizedBox(width: 8),
        _buildTriageOptionButton(index, victima, 'Rojo', Colors.red),
      ],
    );
  }

  Widget _buildTriageOptionButton(int index, VictimaData victima, String code, Color color) {
    final isSelected = victima.codigoTriage == code;
    return GestureDetector(
      onTap: () => _ingresoController.updateVictima(index, codigoTriage: code),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : color.withOpacity(0.2),
          border: Border.all(color: color, width: 2),
        ),
        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
      ),
    );
  }

  Widget _buildBuscadorEtiquetasColumn(ThemeData theme, int index, VictimaData victima) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey('search_${victima.id}'),
          initialValue: victima.busqueda,
          decoration: InputDecoration(
            labelText: 'Buscar síntoma o afección',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: victima.busqueda.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => _ingresoController.updateVictima(index, sintomas: []), // Simplificado
                  )
                : null,
          ),
          onChanged: (val) {
            victima.busqueda = val;
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _etiquetasSintomas.map((etiqueta) {
            bool isSelected = victima.sintomasSeleccionados.contains(etiqueta);
            return ActionChip(
              label: Text(etiqueta),
              backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.surface,
              side: BorderSide(color: isSelected ? theme.colorScheme.primary : Colors.white24),
              onPressed: () {
                final list = List<String>.from(victima.sintomasSeleccionados);
                if (isSelected) {
                  list.remove(etiqueta);
                } else {
                  list.add(etiqueta);
                }
                _ingresoController.updateVictima(index, sintomas: list);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreguntasRecomendacionesBox(ThemeData theme, VictimaData victima) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: victima.sintomasSeleccionados.isNotEmpty || victima.busqueda.isNotEmpty
          ? _buildPreguntasSintomas(theme, victima)
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Seleccione un síntoma o busque\npara ver el proceso de asistencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ),
    );
  }

  Widget _buildPreguntasSintomas(ThemeData theme, VictimaData victima) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment, size: 20, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                'Proceso de asistencia sugerido',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildPreguntaItem(theme, '¿El paciente está consciente?'),
                const SizedBox(height: 8),
                _buildPreguntaItem(theme, '¿Respira con normalidad?'),
                const SizedBox(height: 8),
                _buildPreguntaItem(theme, '¿Tiene pulso palpable?'),
                if (victima.sintomasSeleccionados.contains('Dolor de pecho')) ...[
                  const SizedBox(height: 8),
                  _buildPreguntaItem(theme, '¿El dolor se irradia al brazo o mandíbula?'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreguntaItem(ThemeData theme, String pregunta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(pregunta, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceChip(label: const Text('Sí'), selected: false, onSelected: (_) {}),
              const SizedBox(width: 4),
              ChoiceChip(label: const Text('No'), selected: false, onSelected: (_) {}),
            ],
          ),
        ],
      ),
    );
  }

}
