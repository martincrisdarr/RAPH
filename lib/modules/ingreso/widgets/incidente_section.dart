import 'package:flutter/material.dart';

class IncidenteSection extends StatefulWidget {
  const IncidenteSection({super.key});

  @override
  State<IncidenteSection> createState() => _IncidenteSectionState();
}

class _IncidenteSectionState extends State<IncidenteSection> {
  final TextEditingController _descripcionIncidenteController = TextEditingController();

  @override
  void dispose() {
    _descripcionIncidenteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }
}
