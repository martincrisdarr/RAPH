import 'package:flutter/material.dart';
import '../../shared/theme/app_theme_tokens.dart';
import '../ingreso/controllers/ingreso_controller.dart';
import 'widgets/kanban_column.dart';
import 'widgets/kanban_card.dart';
import 'widgets/kanban_card_skeleton.dart';
import 'widgets/filter_sidebar.dart';
import '../../shared/services/listados_service.dart';

class KanbanItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String? priority;
  final Color priorityColor;
  final List<MovilStatus> moviles;
  String status;

  KanbanItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    this.priority,
    required this.priorityColor,
    required this.moviles,
    required this.status,
  });
}

class ListadosPage extends StatefulWidget {
  final void Function(bool isNew)? onNewIncidentTap;
  const ListadosPage({super.key, this.onNewIncidentTap});

  @override
  State<ListadosPage> createState() => _ListadosPageState();
}

class _ListadosPageState extends State<ListadosPage> {
  // Estado de carga y datos de API
  bool _isLoading = false;
  List<Map<String, dynamic>> _rawDemandas = [];

  // Estado del cursor global
  MouseCursor _boardCursor = SystemMouseCursors.basic;

  // Estado de los filtros
  bool _isFilterVisible = false;
  String? _selectedMovil;
  String? _selectedCodigo;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    debugPrint('🚀 INICIANDO LLAMADA GET: Cargando datos de Demandas...');
    setState(() => _isLoading = true);
    try {
      final resultados = await Future.wait([
        ListadosService.obtenerDemandasRecibidas(),
      ]);

      final demandas = resultados[0];
      setState(() {
        _rawDemandas = demandas;
        // Convert raw demands/incidents to KanbanItem objects (Deduplicados por Incidente)
        final Map<String, KanbanItem> itemsMap = {};

        for (final map in demandas) {
          final incident = (map.containsKey('incidente') && map['incidente'] != null) ? map['incidente'] : map;
          final idIncidente = (map['idincidente'] ?? incident['idincidente'] ?? map['iddemandarecibida'])?.toString() ?? '';

          if (idIncidente.isEmpty) continue;

          final int? idConfCode = int.tryParse((incident['idconf_codigo'] ?? map['idconf_codigo'] ?? '').toString());
          String? priority = map['prioridad'] ?? incident['codigo_triage'] ?? incident['codigoTriage'];

          if (idConfCode == 29) {
            priority = 'ROJA';
          } else if (idConfCode == 30) {
            priority = 'AMARILLA';
          } else if (idConfCode == 31) {
            priority = 'VERDE';
          } else if (idConfCode == null && (priority == null || priority.toString().trim().isEmpty)) {
            priority = 'SIN CÓDIGO';
          }

          Color priorityColor;
          switch (priority?.toUpperCase()) {
            case 'ROJO':
            case 'ROJA':
              priority = 'ROJA';
              priorityColor = AppColors.accentRed;
              break;
            case 'AMARILLO':
            case 'AMARILLA':
              priority = 'AMARILLA';
              priorityColor = Colors.orangeAccent;
              break;
            case 'VERDE':
              priority = 'VERDE';
              priorityColor = AppColors.accentGreen;
              break;
            case 'SIN CÓDIGO':
            case 'SIN CODIGO':
            default:
              priority = 'SIN CÓDIGO';
              priorityColor = Colors.grey;
          }

          List<MovilStatus> moviles = [];

          // 1. Extraer víctimas y sus despachos
          if (incident['victimas'] is List && (incident['victimas'] as List).isNotEmpty) {
            final victimasList = incident['victimas'] as List;
            for (int vIdx = 0; vIdx < victimasList.length; vIdx++) {
              final v = victimasList[vIdx];
              if (v is! Map) continue;

              String vNombre = 'Víctima ${vIdx + 1}';
              if (v['persona'] is Map && v['persona']['apellido'] != null) {
                final p = v['persona'];
                final fullName = '${p['apellido'] ?? ''} ${p['nombre'] ?? ''}'.trim();
                if (fullName.isNotEmpty) vNombre = fullName;
              } else if (v['persona_sin_dni'] is Map && v['persona_sin_dni']['nombre'] != null) {
                final sinDni = v['persona_sin_dni']['nombre'].toString().trim();
                if (sinDni.isNotEmpty) vNombre = sinDni;
              }

              bool tieneDespacho = false;
              if (v['despachos'] is List) {
                for (final d in (v['despachos'] as List)) {
                  if (d is Map && (d['activo'] == null || d['activo'].toString() != '0')) {
                    tieneDespacho = true;
                    String mNombre = 'Móvil';
                    if (d['movilunidad'] is Map) {
                      final mu = d['movilunidad'];
                      if (mu['movil'] is Map && mu['movil']['nombre'] != null) {
                        mNombre = mu['movil']['nombre'].toString();
                      } else if (mu['nombre'] != null) {
                        mNombre = mu['nombre'].toString();
                      } else if (mu['patente'] != null) {
                        mNombre = 'Unidad ${mu['patente']}';
                      }
                    }
                    moviles.add(MovilStatus(
                      nombre: mNombre,
                      status: 'Despachado',
                      victimaNombre: vNombre,
                      tieneMovil: true,
                      lastStatusChange: d['fechahoradespacho'] != null
                          ? DateTime.tryParse(d['fechahoradespacho'].toString()) ?? DateTime.now()
                          : DateTime.now(),
                    ));
                  }
                }
              }

              if (!tieneDespacho) {
                moviles.add(MovilStatus(
                  nombre: 'Sin móvil',
                  status: 'Sin asignar',
                  victimaNombre: vNombre,
                  tieneMovil: false,
                ));
              }
            }
          }

          if (moviles.isEmpty && map['moviles'] is List) {
            moviles = (map['moviles'] as List).map<MovilStatus>((m) {
              return MovilStatus(
                nombre: m['nombre'] ?? 'Desconocido',
                status: m['status'] ?? 'Desconocido',
                victimaNombre: 'Víctima',
                tieneMovil: true,
                lastStatusChange: m['lastStatusChange'] != null
                    ? DateTime.tryParse(m['lastStatusChange'].toString()) ?? DateTime.now()
                    : DateTime.now(),
              );
            }).toList();
          }


          final String direccionStr = (incident['direccion'] != null && incident['direccion'].toString().trim().isNotEmpty)
              ? incident['direccion'].toString().trim()
              : ((incident['direccion_auto'] != null && incident['direccion_auto'].toString().trim().isNotEmpty)
                  ? incident['direccion_auto'].toString().trim()
                  : 'Sin dirección');

          final String descripcionStr = (incident['descripcion'] != null && incident['descripcion'].toString().trim().isNotEmpty)
              ? incident['descripcion'].toString().trim()
              : 'Sin descripción';

          String title = direccionStr;
          String subtitle = descripcionStr;
          String time = _formatFechaCreacion(incident['fechahoraauto'] ?? map['fechahora']);

          // 2. Estado Kanban dinámico
          final int? idEstadoInc = int.tryParse((
            map['idcfg_estado'] ?? 
            (map['ultimoEstadoRel'] != null ? map['ultimoEstadoRel']['idestado'] : null) ?? 
            ''
          ).toString());
          final bool isIncActivo = (incident['activo'] ?? map['activo'] ?? 1).toString() != '0';

          String status = 'Llamada recibida';
          if (!isIncActivo || idEstadoInc == 7 || idEstadoInc == 8) {
            status = 'Finalizado';
          } else if (moviles.any((m) => m.tieneMovil)) {
            status = 'En curso';
          } else {
            status = 'Llamada recibida';
          }

          itemsMap[idIncidente] = KanbanItem(
            id: idIncidente,
            title: title,
            subtitle: subtitle,
            time: time,
            priority: priority,
            priorityColor: priorityColor,
            moviles: moviles,
            status: status,
          );
        }

        _items = itemsMap.values.toList();
        _isLoading = false;
      });
      
      print('Conexión lista: ${_rawDemandas.length} demandas cargadas.');
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al precargar datos de API: $e');
    }
  }

  String _formatFechaCreacion(dynamic fechaRaw) {
    if (fechaRaw == null || fechaRaw.toString().trim().isEmpty) return '';
    final dt = DateTime.tryParse(fechaRaw.toString());
    if (dt == null) return fechaRaw.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    return '$hh:$mm $dd/$mes';
  }

  List<KanbanItem> _items = [];

        

  void _onItemDropped(String itemTitle, String newStatus) {
    setState(() {
      final itemIndex = _items.indexWhere((item) => item.id == itemTitle || item.title == itemTitle);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        item.status = newStatus;
        
        if (newStatus == 'Llamada recibida') {
          for (var m in item.moviles) {
            m.status = 'Llamada recibida';
          }
        } else if (newStatus == 'Finalizado') {
          for (var m in item.moviles) {
            m.status = 'Finalizado';
          }
        } else if (newStatus == 'En curso') {
          for (var m in item.moviles) {
            if (m.status == 'Llamada recibida' || m.status == 'Finalizado') {
              m.status = 'Despachado';
            }
          }
        }
      }
    });
  }

  void _updateGlobalCursor(MouseCursor cursor) {
    setState(() {
      _boardCursor = cursor;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isDesde) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.black,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      cursor: _boardCursor,
      child: Stack(
        children: [
          // Tablero Kanban (Fondo)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Tablero de Seguimiento',
                              style: theme.textTheme.headlineMedium,
                            ),
                            if (_isLoading) ...[
                              const SizedBox(width: 16),
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestión visual de incidentes y despachos activos.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: widget.onNewIncidentTap != null ? () => widget.onNewIncidentTap!(true) : null,
                          icon: const Icon(Icons.add_box_rounded),
                          label: const Text('NUEVO INCIDENTE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _isFilterVisible = !_isFilterVisible),
                          icon: Icon(_isFilterVisible ? Icons.filter_list_off : Icons.filter_list),
                          label: Text(_isFilterVisible ? 'Ocultar Filtros' : 'Mostrar Filtros'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildColumn(
                        title: 'Llamada recibida',
                        statuses: const ['Llamada recibida'],
                        dropStatus: 'Llamada recibida',
                        flex: 1,
                        accentColor: const Color(0xFF38BDF8),
                      ),
                      _buildColumn(
                        title: 'En curso',
                        statuses: const ['En curso', 'Despachado', 'En sitio', 'Traslado', 'Arribado'],
                        dropStatus: 'En curso',
                        flex: 2,
                        accentColor: const Color(0xFFF59E0B),
                      ),
                      _buildColumn(
                        title: 'Finalizado',
                        statuses: const ['Finalizado'],
                        dropStatus: 'Finalizado',
                        flex: 1,
                        accentColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Panel de Filtros Flotante (Derecha)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isFilterVisible ? 0 : -300,
            top: 0,
            bottom: 0,
            child: FilterSidebar(
              selectedMovil: _selectedMovil,
              onMovilChanged: (val) => setState(() => _selectedMovil = val),
              selectedCodigo: _selectedCodigo,
              onCodigoChanged: (val) => setState(() => _selectedCodigo = val),
              fechaDesde: _fechaDesde,
              fechaHasta: _fechaHasta,
              onSelectFechaDesde: () => _selectDate(context, true),
              onSelectFechaHasta: () => _selectDate(context, false),
              onClose: () => setState(() => _isFilterVisible = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required String title,
    required List<String> statuses,
    required String dropStatus,
    int flex = 1,
    Color? accentColor,
  }) {
    final columnItems = _items.where((item) => statuses.contains(item.status)).toList();
    final isEnCurso = title == 'En curso';

    final List<Widget> childrenWidgets;
    if (_isLoading) {
      final skeletonCount = isEnCurso ? 4 : 2;
      childrenWidgets = List.generate(
        skeletonCount,
        (_) => const KanbanCardSkeleton(),
      );
    } else {
      childrenWidgets = columnItems.map((item) {
        // Buscar el raw map correspondiente a este incidente
        final rawMap = _rawDemandas.firstWhere(
          (m) {
            final idInc = (m['idincidente'] ?? (m['incidente'] != null ? m['incidente']['idincidente'] : null) ?? m['iddemandarecibida'])?.toString();
            return idInc == item.id;
          },
          orElse: () => <String, dynamic>{},
        );
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              if (rawMap.isNotEmpty) {
                await IngresoController().cargarIncidenteDirecto(rawMap);
              }
              widget.onNewIncidentTap?.call(false);
            },
            child: KanbanCard(
              title: item.title,
              subtitle: item.subtitle,
              time: item.time,
              moviles: item.moviles,
              globalStatus: item.status,
              priority: item.priority,
              priorityColor: item.priorityColor,
            ),
          ),
        );
      }).toList();
    }
    
    return Expanded(
      flex: flex,
      child: KanbanColumn(
        title: title,
        count: _isLoading ? 0 : columnItems.length,
        isGrid: false,
        accentColor: accentColor,
        onAccept: (itemTitle) => _onItemDropped(itemTitle, dropStatus),
        children: childrenWidgets,
      ),
    );
  }
}
