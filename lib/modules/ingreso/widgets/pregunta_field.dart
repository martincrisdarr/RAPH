import 'package:flutter/material.dart';
import '../../../shared/models/sintoma_pregunta.dart';

class PreguntaField extends StatefulWidget {
  final SintomaPregunta pregunta;
  final dynamic valorActual;
  final ValueChanged<dynamic> onChanged;

  const PreguntaField({
    super.key,
    required this.pregunta,
    this.valorActual,
    required this.onChanged,
  });

  @override
  State<PreguntaField> createState() => _PreguntaFieldState();
}

class _PreguntaFieldState extends State<PreguntaField> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.valorActual?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant PreguntaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valorActual != widget.valorActual &&
        _textController.text != (widget.valorActual?.toString() ?? '')) {
      _textController.text = widget.valorActual?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.pregunta.pregunta,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.pregunta.obligatoria)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildControl(theme),
        ],
      ),
    );
  }

  Widget _buildControl(ThemeData theme) {
    switch (widget.pregunta.tipo) {
      case 'BOOLEAN':
        return _buildBooleanControl(theme);
      case 'SINGLE_OPTION':
        return _buildSingleOptionControl(theme);
      case 'MULTIPLE_OPTION':
        return _buildMultipleOptionControl(theme);
      case 'NUMBER':
        return _buildNumberControl();
      case 'TIME':
        return _buildTimeControl();
      case 'DURATION':
      case 'TEXT':
      default:
        return _buildTextControl();
    }
  }

  Widget _buildBooleanControl(ThemeData theme) {
    final bool? val = widget.valorActual as bool?;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Sí'),
            style: ElevatedButton.styleFrom(
              backgroundColor: val == true ? theme.colorScheme.primary : Colors.white10,
              foregroundColor: val == true ? Colors.black : Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => widget.onChanged(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.close, size: 16),
            label: const Text('No'),
            style: ElevatedButton.styleFrom(
              backgroundColor: val == false ? Colors.redAccent.withOpacity(0.8) : Colors.white10,
              foregroundColor: val == false ? Colors.white : Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => widget.onChanged(false),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleOptionControl(ThemeData theme) {
    final int? selectedOptionId = widget.valorActual is int ? widget.valorActual as int : null;

    return Column(
      children: widget.pregunta.opciones.map((opc) {
        final isSelected = selectedOptionId == opc.id;
        return InkWell(
          onTap: () => widget.onChanged(opc.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? theme.colorScheme.primary : Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    opc.descripcion,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleOptionControl(ThemeData theme) {
    final List<int> selectedIds = widget.valorActual is List<int> ? widget.valorActual as List<int> : [];

    return Column(
      children: widget.pregunta.opciones.map((opc) {
        final isSelected = selectedIds.contains(opc.id);
        return CheckboxListTile(
          value: isSelected,
          title: Text(opc.descripcion, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: theme.colorScheme.primary,
          onChanged: (checked) {
            final newList = List<int>.from(selectedIds);
            if (checked == true) {
              newList.add(opc.id);
            } else {
              newList.remove(opc.id);
            }
            widget.onChanged(newList);
          },
        );
      }).toList(),
    );
  }

  Widget _buildTextControl() {
    return TextField(
      controller: _textController,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: const InputDecoration(
        hintText: 'Ingrese respuesta...',
        isDense: true,
      ),
      onSubmitted: (val) => widget.onChanged(val),
    );
  }

  Widget _buildNumberControl() {
    return TextField(
      controller: _textController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: const InputDecoration(
        hintText: 'Ingrese un valor numérico...',
        isDense: true,
      ),
      onSubmitted: (val) => widget.onChanged(num.tryParse(val)),
    );
  }

  Widget _buildTimeControl() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          setState(() {
            _textController.text = formatted;
          });
          widget.onChanged(formatted);
        }
      },
      child: IgnorePointer(
        child: TextField(
          controller: _textController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'HH:MM',
            suffixIcon: Icon(Icons.access_time, size: 18),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
