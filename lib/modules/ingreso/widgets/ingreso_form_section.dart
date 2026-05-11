import 'package:flutter/material.dart';
import '../../../shared/components/custom_select.dart';
import '../../../shared/models/configuracion.dart';
import '../../../shared/services/configuracion_service.dart';
import '../controllers/ingreso_controller.dart';

class IngresoFormSection extends StatefulWidget {
  const IngresoFormSection({super.key});

  @override
  State<IngresoFormSection> createState() => _IngresoFormSectionState();
}

class _IngresoFormSectionState extends State<IngresoFormSection> {
  bool _isNuevo = true;
  
  final _ingresoController = IngresoController();
  late final TextEditingController _telefonoController;
  late final TextEditingController _nombreController;

  @override
  void initState() {
    super.initState();
    _telefonoController = TextEditingController(text: _ingresoController.demandaActual.nroLlamadaEntrante?.toString() ?? '');
    _nombreController = TextEditingController(text: _ingresoController.demandaActual.apellidoNombre ?? '');
    _ingresoController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      if (_telefonoController.text.isEmpty && _ingresoController.demandaActual.nroLlamadaEntrante != null) {
        _telefonoController.text = _ingresoController.demandaActual.nroLlamadaEntrante.toString();
      }
      if (_nombreController.text.isEmpty && _ingresoController.demandaActual.apellidoNombre != null && _ingresoController.demandaActual.apellidoNombre!.isNotEmpty) {
        _nombreController.text = _ingresoController.demandaActual.apellidoNombre!;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    _telefonoController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  static const _tableColumns = ['ID', 'Fecha', 'Tipo', 'Dirección', 'Estado'];
  static const _tableColumnFlex = [1, 2, 2, 4, 2];

  // Mock: últimos incidentes en curso (en producción vendrá de la API)
  final List<Map<String, String>> _incidentesEnCurso = const [
    {'id': '#001241', 'fecha': '21/04 14:18', 'tipo': 'Médico', 'direccion': 'Av. Corrientes 1580, CABA', 'estado': 'DESPACHO'},
    {'id': '#001238', 'fecha': '21/04 13:55', 'tipo': 'Accidente vial', 'direccion': 'Belgrano y Tucumán', 'estado': 'EN SITIO'},
    {'id': '#001236', 'fecha': '21/04 13:40', 'tipo': 'Incendio', 'direccion': 'Mitre 340, Ramos Mejía', 'estado': 'TRASLADO'},
    {'id': '#001233', 'fecha': '21/04 13:20', 'tipo': 'Médico', 'direccion': 'San Martín 890, Morón', 'estado': 'DESPACHO'},
    {'id': '#001229', 'fecha': '21/04 12:58', 'tipo': 'Médico', 'direccion': 'Rivadavia 2200, CABA', 'estado': 'EN SITIO'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Datos de Llamada (Siempre visibles) ---
        Row(
          children: [
            Expanded(
              child: CustomSelect<Configuracion>(
                label: 'Ingreso',
                fetchItems: () => ConfiguracionService.obtenerTiposIngreso(),
                itemLabel: (item) => item.descripcion,
                initialSelectionId: _ingresoController.demandaActual.idCfgTipoIngreso,
                matchById: (item) => item.idconfiguracion,
                onSelected: (val) {
                  if (val != null) {
                    _ingresoController.updateDemanda(idCfgTipoIngreso: val.idconfiguracion);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                onChanged: (val) => _ingresoController.updateDemanda(nroLlamadaEntrante: int.tryParse(val)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(labelText: 'Nombre'),
          keyboardType: TextInputType.name,
          onChanged: (val) => _ingresoController.updateDemanda(apellidoNombre: val),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 24),

        // --- Botones toggle ---
        Row(
          children: [
            ElevatedButton(
              onPressed: () => setState(() => _isNuevo = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isNuevo ? theme.colorScheme.primary : theme.colorScheme.surface,
                foregroundColor: _isNuevo ? Colors.black : Colors.white,
                side: BorderSide(color: _isNuevo ? Colors.transparent : Colors.white24),
              ),
              child: const Text('NUEVO'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => setState(() => _isNuevo = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: !_isNuevo ? theme.colorScheme.primary : theme.colorScheme.surface,
                foregroundColor: !_isNuevo ? Colors.black : Colors.white,
                side: BorderSide(color: !_isNuevo ? Colors.transparent : Colors.white24),
              ),
              child: const Text('INCIDENTE EN CURSO'),
            ),
          ],
        ),

        // --- Tabla INCIDENTE EN CURSO ---
        if (!_isNuevo) ...[
          const SizedBox(height: 16),
          Expanded(child: _buildIncidentesTable(theme)),
        ],
      ],
    );
  }

  Widget _buildIncidentesTable(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                for (int i = 0; i < _tableColumns.length; i++)
                  Expanded(
                    flex: _tableColumnFlex[i],
                    child: Text(
                      _tableColumns[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white38,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: _incidentesEnCurso.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: Colors.white10,
              ),
              itemBuilder: (context, index) {
                final inc = _incidentesEnCurso[index];
                return _buildIncidenteRow(theme, inc, _tableColumnFlex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidenteRow(
    ThemeData theme,
    Map<String, String> inc,
    List<int> flex,
  ) {
    final estado = inc['estado']!;
    final estadoColor = _estadoColor(estado);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => debugPrint('Editar incidente ${inc['id']}'),
        hoverColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ID
              Expanded(
                flex: flex[0],
                child: Text(
                  inc['id']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Fecha
              Expanded(
                flex: flex[1],
                child: Text(
                  inc['fecha']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ),
              // Tipo
              Expanded(
                flex: flex[2],
                child: Text(
                  inc['tipo']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.87),
                  ),
                ),
              ),
              // Dirección
              Expanded(
                flex: flex[3],
                child: Text(
                  inc['direccion']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Estado
              Expanded(
                flex: flex[4],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  constraints: const BoxConstraints(maxWidth: 100),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    estado,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'DESPACHO':
        return const Color(0xFFFFB74D); // amber
      case 'EN SITIO':
        return const Color(0xFF4FC3F7); // light blue
      case 'TRASLADO':
        return const Color(0xFF81C784); // green
      case 'ACTIVO':
        return const Color(0xFFE57373); // red
      default:
        return Colors.white38;
    }
  }
}
