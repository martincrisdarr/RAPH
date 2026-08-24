import 'package:flutter/material.dart';

class FilterSidebar extends StatelessWidget {
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
            color: Colors.black.withOpacity(0.5),
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
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20, color: Colors.white38),
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Filtro de Móvil
          _buildDropdownFilter(
            theme: theme,
            label: 'Móvil',
            value: selectedMovil,
            hint: 'Seleccionar móvil',
            items: ['Movil 1', 'Movil 2', 'Movil 3', 'Movil 4'],
            onChanged: onMovilChanged,
          ),
          
          const SizedBox(height: 16),

          // Filtro de Código
          _buildDropdownFilter(
            theme: theme,
            label: 'Código',
            value: selectedCodigo,
            hint: 'Seleccionar código',
            items: ['VERDE', 'AMARILLO', 'ROJO'],
            onChanged: onCodigoChanged,
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
            date: fechaDesde,
            onTap: onSelectFechaDesde,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _DateTile(
            label: 'Hasta',
            date: fechaHasta,
            onTap: onSelectFechaHasta,
            theme: theme,
          ),
          
          const Spacer(),
          
          // Botón Limpiar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white10),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // Menos border radius
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
            color: theme.colorScheme.background,
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
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary.withOpacity(0.5)),
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
