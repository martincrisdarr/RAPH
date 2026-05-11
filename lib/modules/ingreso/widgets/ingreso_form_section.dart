import 'package:flutter/material.dart';
import '../../../shared/components/custom_select.dart';
import '../../../shared/models/configuracion.dart';
import '../../../shared/services/configuracion_service.dart';
import '../../../shared/services/demanda_recibida_service.dart';
import '../../../shared/models/demanda_recibida.dart';
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
  Future<List<DemandaRecibida>>? _demandasFuture;

  @override
  void initState() {
    super.initState();
    _telefonoController = TextEditingController(text: _ingresoController.demandaActual.nroLlamadaEntrante?.toString() ?? '');
    _nombreController = TextEditingController(text: _ingresoController.demandaActual.apellidoNombre ?? '');
    _ingresoController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      final demanda = _ingresoController.demandaActual;
      
      final nuevoTelefono = demanda.nroLlamadaEntrante?.toString() ?? '';
      if (_telefonoController.text != nuevoTelefono) {
        _telefonoController.text = nuevoTelefono;
      }
      
      final nuevoNombre = demanda.apellidoNombre ?? '';
      if (_nombreController.text != nuevoNombre) {
        _nombreController.text = nuevoNombre;
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

  void _cargarDemandas() {
    setState(() {
      _demandasFuture = DemandaRecibidaService.obtenerRecientes();
    });
  }

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
              onPressed: () {
                setState(() => _isNuevo = false);
                _cargarDemandas();
              },
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
            child: FutureBuilder<List<DemandaRecibida>>(
              future: _demandasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                final demandas = snapshot.data ?? [];
                if (demandas.isEmpty) {
                  return const Center(child: Text('No hay incidentes recientes', style: TextStyle(color: Colors.white38)));
                }

                return ListView.separated(
                  itemCount: demandas.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Colors.white10,
                  ),
                  itemBuilder: (context, index) {
                    final demanda = demandas[index];
                    return _buildIncidenteRow(theme, demanda, _tableColumnFlex);
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidenteRow(
    ThemeData theme,
    DemandaRecibida demanda,
    List<int> flex,
  ) {
    final estado = demanda.estado?.descripcion ?? 'DESCONOCIDO';
    final estadoColor = _estadoColor(estado);
    
    String fechaStr = '--/-- --:--';
    if (demanda.fechaHora != null) {
      final f = demanda.fechaHora!;
      fechaStr = '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')} ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _ingresoController.cargarDemanda(demanda);
          setState(() => _isNuevo = true); // Volvemos a la vista del formulario
        },
        hoverColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ID
              Expanded(
                flex: flex[0],
                child: Text(
                  '#${demanda.idDemandaRecibida ?? '---'}',
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
                  fechaStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ),
              // Tipo
              Expanded(
                flex: flex[2],
                child: Text(
                  demanda.tipoIngreso?.descripcion ?? 'N/A',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.87),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Dirección
              Expanded(
                flex: flex[3],
                child: Text(
                  demanda.incidente?.direccion ?? 'No especificada',
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
    final upperEstado = estado.toUpperCase();
    switch (upperEstado) {
      case 'ABIERTA':
      case 'INGRESO':
        return const Color(0xFF64B5F6); // blue
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
