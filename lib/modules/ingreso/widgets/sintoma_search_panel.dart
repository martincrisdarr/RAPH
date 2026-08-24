import 'package:flutter/material.dart';
import '../../../shared/models/sintoma.dart';

class SintomaSearchPanel extends StatefulWidget {
  final List<Sintoma> sintomas;
  final Sintoma? sintomaSeleccionado;
  final bool isLoading;
  final ValueChanged<Sintoma> onSintomaSelected;

  const SintomaSearchPanel({
    super.key,
    required this.sintomas,
    this.sintomaSeleccionado,
    required this.isLoading,
    required this.onSintomaSelected,
  });

  @override
  State<SintomaSearchPanel> createState() => _SintomaSearchPanelState();
}

class _SintomaSearchPanelState extends State<SintomaSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredSintomas = widget.sintomas.where((s) {
      if (_query.isEmpty) return true;
      return s.nombre.toLowerCase().contains(_query.toLowerCase()) ||
          s.codigo.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Buscador de síntoma
        TextFormField(
          controller: _searchController,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Buscar síntoma o afección',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                      });
                    },
                  )
                : null,
            isDense: true,
          ),
          onChanged: (val) {
            setState(() {
              _query = val;
            });
          },
        ),
        const SizedBox(height: 14),

        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (filteredSintomas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              _query.isEmpty ? 'No hay síntomas configurados.' : 'Sin resultados para "$_query"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredSintomas.map((sintoma) {
              final isSelected = widget.sintomaSeleccionado?.id == sintoma.id;

              return SizedBox(
                width: 160,
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onSintomaSelected(sintoma),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : (sintoma.categoria?.icono != null
                                    ? Icons.medical_services_outlined
                                    : Icons.circle_outlined),
                            size: 16,
                            color: isSelected
                                ? Colors.black
                                : (sintoma.categoria?.icono != null
                                    ? theme.colorScheme.primary
                                    : Colors.white38),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sintoma.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
