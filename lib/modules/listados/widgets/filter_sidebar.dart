import 'package:flutter/material.dart';
import '../../../shared/services/movil_service.dart';

class FilterSidebar extends StatefulWidget {
  final String? selectedMovil;
  final ValueChanged<String?> onMovilChanged;
  final String? selectedCodigo;
  final ValueChanged<String?> onCodigoChanged;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final VoidCallback onSelectFechaDesde;
  final VoidCallback onSelectFechaHasta;
  final VoidCallback? onClose;

  const FilterSidebar({
    super.key,
    required this.selectedMovil,
    required this.onMovilChanged,
    required this.selectedCodigo,
    required this.onCodigoChanged,
    required this.fechaDesde,
    required this.fechaHasta,
    required this.onSelectFechaDesde,
    required this.onSelectFechaHasta,
    this.onClose,
  });

  @override
  State<FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<FilterSidebar> {
  List<String> _movilesList = ['Móvil 1', 'Móvil 2', 'Móvil 3', 'Móvil 4'];

  @override
  void initState() {
    super.initState();
    _cargarMovilesReales();
  }

  Future<void> _cargarMovilesReales() async {
    try {
      final moviles = await MovilService.obtenerMoviles();
      if (moviles.isNotEmpty) {
        final nombres = moviles.map((m) => m.nombre).where((n) => n.isNotEmpty).toList();
        if (nombres.isNotEmpty && mounted) {
          setState(() {
            _movilesList = nombres;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
        border: const Border(left: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'FILTROS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 20, color: Colors.white38),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Filtro de Móvil
          _buildDropdownFilter(
            theme: theme,
            label: 'Móvil',
            value: widget.selectedMovil,
            hint: 'Seleccionar móvil',
            items: _movilesList,
            onChanged: widget.onMovilChanged,
          ),
          
          const SizedBox(height: 16),

          // Filtro de Código
          _buildDropdownFilter(
            theme: theme,
            label: 'Código',
            value: widget.selectedCodigo,
            hint: 'Seleccionar código',
            items: const ['VERDE', 'AMARILLO', 'ROJO'],
            onChanged: widget.onCodigoChanged,
          ),
          
          const SizedBox(height: 16),

          // Filtro de Fechas
          Text(
            'Rango de Fechas',
            style: theme.textTheme.titleSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          _DateTile(
            label: 'Desde',
            date: widget.fechaDesde,
            onTap: widget.onSelectFechaDesde,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _DateTile(
            label: 'Hasta',
            date: widget.fechaHasta,
            onTap: widget.onSelectFechaHasta,
            theme: theme,
          ),
          
          const Spacer(),
          
          // Botón Limpiar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                widget.onMovilChanged(null);
                widget.onCodigoChanged(null);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white10),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Limpiar Filtros',
                style: TextStyle(
                  color: Colors.white54,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required ThemeData theme,
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (value != null && items.contains(value)) ? value : null,
              hint: Text(hint, style: const TextStyle(color: Colors.white30, fontSize: 14)),
              isExpanded: true,
              dropdownColor: theme.colorScheme.surface,
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final ThemeData theme;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                Text(
                  date != null ? '${date!.day}/${date!.month}/${date!.year}' : '--/--/----',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
