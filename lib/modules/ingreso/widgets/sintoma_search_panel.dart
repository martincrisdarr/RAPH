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
  String _selectedColorFilter = 'TODOS'; // 'TODOS', 'ROJO', 'AMARILLO', 'VERDE'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getColorForSeries(String? colorStr) {
    switch (colorStr?.toUpperCase()) {
      case 'ROJO':
        return Colors.redAccent.shade400;
      case 'AMARILLO':
        return Colors.amber.shade600;
      case 'VERDE':
        return Colors.greenAccent.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular contadores por serie
    final int rojoCount = widget.sintomas.where((s) => s.codigoColor?.toUpperCase() == 'ROJO').length;
    final int amarilloCount = widget.sintomas.where((s) => s.codigoColor?.toUpperCase() == 'AMARILLO').length;
    final int verdeCount = widget.sintomas.where((s) => s.codigoColor?.toUpperCase() == 'VERDE').length;
    final int totalCount = widget.sintomas.length;

    // Filtrar por término de búsqueda y por serie seleccionada
    final filteredSintomas = widget.sintomas.where((s) {
      final matchesQuery = _query.isEmpty ||
          s.nombre.toLowerCase().contains(_query.toLowerCase()) ||
          s.codigo.toLowerCase().contains(_query.toLowerCase());

      final matchesColor = _selectedColorFilter == 'TODOS' ||
          s.codigoColor?.toUpperCase() == _selectedColorFilter;

      return matchesQuery && matchesColor;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Buscador de Ficha por Código o Término
        TextFormField(
          controller: _searchController,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Buscar por código ("101", "206") o motivo ("pecho", "paro")',
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
        const SizedBox(height: 10),

        // 2. Filtros Rápidos por Serie de Color
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('TODOS', 'TODAS ($totalCount)', Colors.white70),
              const SizedBox(width: 6),
              _buildFilterChip('ROJO', '1xx ROJO ($rojoCount)', Colors.redAccent.shade200),
              const SizedBox(width: 6),
              _buildFilterChip('AMARILLO', '2xx AMARILLO ($amarilloCount)', Colors.amber.shade300),
              const SizedBox(width: 6),
              _buildFilterChip('VERDE', '3xx VERDE ($verdeCount)', Colors.greenAccent.shade200),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Contenedor con lista de Fichas Oficiales
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (filteredSintomas.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              _query.isEmpty
                  ? 'No hay fichas en esta categoría.'
                  : 'Sin resultados para "$_query".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 460),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: filteredSintomas.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final sintoma = filteredSintomas[index];
                  final isSelected = widget.sintomaSeleccionado?.id == sintoma.id;
                  final seriesColor = _getColorForSeries(sintoma.codigoColor);

                  return Material(
                    color: isSelected
                        ? seriesColor.withOpacity(0.2)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => widget.onSintomaSelected(sintoma),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? seriesColor : Colors.white12,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Badge con el código oficial
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: seriesColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: seriesColor.withOpacity(0.6)),
                              ),
                              child: Text(
                                sintoma.codigo,
                                style: TextStyle(
                                  color: seriesColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Nombre del Motivo / Ficha
                            Expanded(
                              child: Text(
                                sintoma.nombre,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.88),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),

                            // Indicador de selección
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: seriesColor, size: 18)
                            else
                              Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, Color accentColor) {
    final isSelected = _selectedColorFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.black : Colors.white70,
        ),
      ),
      selected: isSelected,
      selectedColor: accentColor,
      backgroundColor: Colors.white.withOpacity(0.06),
      side: BorderSide(
        color: isSelected ? accentColor : Colors.white12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedColorFilter = key;
          });
        }
      },
    );
  }
}
