import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  final _ingresoController = IngresoController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _filtroDireccionController = TextEditingController();
  DateTime? _filtroFecha;
  List<DemandaRecibida> _demandasRecientes = [];
  bool _cargandoListado = false;

  String? _errorTelefono;

  @override
  void initState() {
    super.initState();
    _ingresoController.addListener(_onControllerUpdate);
    // Sincronizar estado inicial
    _onControllerUpdate();
  }

  void _onControllerUpdate() {
    if (mounted) {
      final demanda = _ingresoController.demandaActual;
      
      final nuevoTelefono = demanda.nroLlamadaEntrante?.toString() ?? '';
      if (_telefonoController.text != nuevoTelefono) {
        if (_errorTelefono == null) {
          _telefonoController.text = nuevoTelefono;
        }
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
    _filtroDireccionController.dispose();
    super.dispose();
  }

  static const _tableColumns = ['ID', 'Fecha', 'Tipo', 'Dirección', 'Estado'];
  static const _tableColumnFlex = [1, 2, 2, 4, 2];

  Timer? _debounceTimer;

  Future<void> _cargarDemandas() async {
    setState(() => _cargandoListado = true);
    try {
      final data = await DemandaRecibidaService.obtenerRecientes(
        fecha: _filtroFecha,
        direccion: _filtroDireccionController.text,
      );
      if (mounted) {
        setState(() {
          _demandasRecientes = data;
          _cargandoListado = false;
        });
        _ingresoController.incidentesRecientes = data;
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoListado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  errorText: _errorTelefono,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (val) {
                  if (val.isNotEmpty && val.length < 6) {
                    setState(() {
                      _errorTelefono = 'Mínimo 6 números';
                    });
                  } else {
                    setState(() {
                      _errorTelefono = null;
                    });
                    _ingresoController.updateDemanda(
                      nroLlamadaEntrante: int.tryParse(val),
                      clearNroLlamada: val.isEmpty,
                    );
                  }
                },
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
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  _ingresoController.vistaFormulario = true;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _ingresoController.vistaFormulario ? theme.colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _ingresoController.vistaFormulario ? theme.colorScheme.primary : Colors.white12,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'NUEVO',
                      style: TextStyle(
                        color: _ingresoController.vistaFormulario ? theme.colorScheme.primary : Colors.white60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  _ingresoController.vistaFormulario = false;
                  _cargarDemandas();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_ingresoController.vistaFormulario ? theme.colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !_ingresoController.vistaFormulario ? theme.colorScheme.primary : Colors.white12,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'INCIDENTES',
                      style: TextStyle(
                        color: !_ingresoController.vistaFormulario ? theme.colorScheme.primary : Colors.white60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_ingresoController.vistaFormulario) ...[
          if (_ingresoController.incidenteActual.idIncidente != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vinculado a Incidente #${_ingresoController.incidenteActual.idIncidente}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dirección: ${_ingresoController.incidenteActual.direccion ?? "No especificada"}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  if (_ingresoController.llamadasDelIncidente.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Llamadas registradas: ${_ingresoController.llamadasDelIncidente.length}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _ingresoController.prepararNuevoIncidente();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Se desvinculó del incidente y se inició uno nuevo.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.link_off_rounded, size: 16),
                    label: const Text(
                      'DESVINCULAR / CREAR NUEVO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white10,
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nuevo incidente (Aún no guardado en mapa/vinculado)',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

        ],
        if (!_ingresoController.vistaFormulario) ...[
          Row(
            children: [
              FilterChip(
                label: const Text('Hoy', style: TextStyle(fontSize: 12)),
                selected: _filtroFecha != null && 
                          _filtroFecha!.day == DateTime.now().day &&
                          _filtroFecha!.month == DateTime.now().month,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _filtroFecha = DateTime.now();
                    } else {
                      _filtroFecha = null;
                    }
                  });
                  _cargarDemandas();
                },
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: _filtroFecha != null ? theme.colorScheme.primary : Colors.white38,
                ),
              ),
              const SizedBox(width: 8),
              MenuAnchor(
                builder: (context, controller, child) {
                  return IconButton(
                    icon: Icon(
                      Icons.calendar_month_outlined, 
                      size: 20, 
                      color: _filtroFecha != null && _filtroFecha!.day != DateTime.now().day 
                          ? theme.colorScheme.primary 
                          : Colors.white38
                    ),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                  );
                },
                style: MenuStyle(
                  backgroundColor: const MaterialStatePropertyAll(Color(0xFF1A1F24)),
                  elevation: const MaterialStatePropertyAll(16),
                  padding: const MaterialStatePropertyAll(EdgeInsets.zero),
                  shape: MaterialStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white12, width: 1),
                    ),
                  ),
                ),
                menuChildren: [
                  Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        surface: const Color(0xFF1A1F24),
                        onSurface: Colors.white,
                      ),
                      dividerColor: Colors.white10,
                    ),
                    child: SizedBox(
                      width: 300,
                      height: 350,
                      child: CalendarDatePicker(
                        initialDate: _filtroFecha ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        onDateChanged: (picked) {
                          setState(() => _filtroFecha = picked);
                          _cargarDemandas();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_filtroFecha != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 14, color: Colors.white38),
                  onPressed: () {
                    setState(() => _filtroFecha = null);
                    _cargarDemandas();
                  },
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _filtroDireccionController,
                    onChanged: (val) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                        _cargarDemandas();
                      });
                      setState(() {});
                    },
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar dirección...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white38),
                      suffixIcon: _filtroDireccionController.text.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 14),
                              onPressed: () {
                                _filtroDireccionController.clear();
                                _cargarDemandas();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildIncidentesTable(theme)),
        ],
      ],
    ));
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
            child: _cargandoListado
                ? const Center(child: CircularProgressIndicator())
                : _demandasRecientes.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay incidentes que coincidan',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _demandasRecientes.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Colors.white10,
                        ),
                        itemBuilder: (context, index) {
                          return _buildIncidenteRow(
                            theme,
                            _demandasRecientes[index],
                            _tableColumnFlex,
                          );
                        },
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

    final isSelected = demanda.idDemandaRecibida != null && 
                       demanda.idDemandaRecibida == _ingresoController.incidenteActual.idIncidente;

    return Material(
      color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (demanda.idDemandaRecibida != null) {
            final allCalls = await DemandaRecibidaService.obtenerTodasPorIncidente(demanda.idDemandaRecibida!);
            if (allCalls.isNotEmpty) {
              _ingresoController.cargarIncidenteYListarLlamadas(allCalls.first, allCalls);
            } else {
              _ingresoController.cargarIncidenteYListarLlamadas(demanda, []);
            }
          } else {
            _ingresoController.cargarIncidenteYListarLlamadas(demanda, []);
          }
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
