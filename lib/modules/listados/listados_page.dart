import 'package:flutter/material.dart';
import 'widgets/kanban_column.dart';
import 'widgets/kanban_card.dart';
import 'widgets/filter_sidebar.dart';
import '../../shared/services/listados_service.dart';

class KanbanItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String priority;
  final Color priorityColor;
  final List<MovilStatus> moviles;
  String status;

  KanbanItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.priority,
    required this.priorityColor,
    required this.moviles,
    required this.status,
  });
}

class ListadosPage extends StatefulWidget {
  const ListadosPage({super.key});

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
      final results = await Future.wait([
        ListadosService.obtenerDemandasRecibidas(),
      ]);

      setState(() {
        _rawDemandas = results[0];
        _isLoading = false;
      });
      
      print('Conexión lista: ${_rawDemandas.length} demandas cargadas.');
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al precargar datos de API: $e');
    }
  }

  final List<KanbanItem> _items = [
    KanbanItem(
      id: '1',
      title: 'Accidente Vial',
      subtitle: 'Ruta 22 y Av. Argentina',
      time: 'Hace 5m',
      priority: 'ROJO',
      priorityColor: Colors.redAccent,
      moviles: [
        MovilStatus(nombre: 'Móvil 1', status: 'Despacho'),
        MovilStatus(nombre: 'Móvil 3', status: 'Despacho'),
        MovilStatus(nombre: 'Móvil 10', status: 'Despacho'),
      ],
      status: 'Despacho',
    ),
    KanbanItem(
      id: '2',
      title: 'Dolor Torácico',
      subtitle: 'Calle Mitre 450',
      time: 'Hace 12m',
      priority: 'ROJO',
      priorityColor: Colors.redAccent,
      moviles: [MovilStatus(nombre: 'Móvil 3', status: 'Despacho')],
      status: 'Despacho',
    ),
    KanbanItem(
      id: '3',
      title: 'Caída de Altura',
      subtitle: 'Obra en construcción',
      time: 'Hace 20m',
      priority: 'AMARILLO',
      priorityColor: Colors.orangeAccent,
      moviles: [MovilStatus(nombre: 'Móvil 2', status: 'Despacho')],
      status: 'Despacho',
    ),
    KanbanItem(
      id: '4',
      title: 'Asistencia Médica',
      subtitle: 'B° Confluencia',
      time: 'Hace 15m',
      priority: 'VERDE',
      priorityColor: Colors.greenAccent,
      moviles: [
        MovilStatus(nombre: 'Móvil 5', status: 'Despachado'),
        MovilStatus(nombre: 'Móvil 2', status: 'En sitio'),
        MovilStatus(nombre: 'Móvil 1', status: 'Traslado'),
        MovilStatus(nombre: 'Móvil 7', status: 'Arribado'),
      ],
      status: 'En curso',
    ),
    KanbanItem(
      id: '5',
      title: 'Convulsiones',
      subtitle: 'Escuela N° 121',
      time: 'Hace 8m',
      priority: 'ROJO',
      priorityColor: Colors.redAccent,
      moviles: [MovilStatus(nombre: 'Móvil 1', status: 'En sitio')],
      status: 'En curso',
    ),
    KanbanItem(
      id: '6',
      title: 'Traslado Programado',
      subtitle: 'Hospital Provincial',
      time: 'Hace 45m',
      priority: 'AMARILLO',
      priorityColor: Colors.orangeAccent,
      moviles: [
        MovilStatus(nombre: 'Móvil 4', status: 'Traslado'),
        MovilStatus(nombre: 'Móvil 6', status: 'Despachado'),
        MovilStatus(nombre: 'Móvil 3', status: 'En sitio'),
        MovilStatus(nombre: 'Móvil 8', status: 'Arribado'),
      ],
      status: 'En curso',
    ),
    KanbanItem(
      id: '7',
      title: 'Emergencia Respiratoria',
      subtitle: 'B° San Lorenzo',
      time: 'Hace 30m',
      priority: 'ROJO',
      priorityColor: Colors.redAccent,
      moviles: [MovilStatus(nombre: 'Móvil 2', status: 'Arribado')],
      status: 'En curso',
    ),
    KanbanItem(
      id: '8',
      title: 'Control de Signos',
      subtitle: 'Centro Cívico',
      time: 'Hace 1h',
      priority: 'VERDE',
      priorityColor: Colors.greenAccent,
      moviles: [
        MovilStatus(nombre: 'Móvil 6', status: 'Finalizado'),
        MovilStatus(nombre: 'Móvil 9', status: 'Finalizado'),
      ],
      status: 'Finalizado',
    ),
  ];

  void _onItemDropped(String itemTitle, String newStatus) {
    setState(() {
      final itemIndex = _items.indexWhere((item) => item.title == itemTitle);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        item.status = newStatus;
        
        if (newStatus == 'Despacho') {
          for (var m in item.moviles) {
            m.status = 'Despacho';
          }
        } else if (newStatus == 'Finalizado') {
          for (var m in item.moviles) {
            m.status = 'Finalizado';
          }
        } else if (newStatus == 'En curso') {
          for (var m in item.moviles) {
            if (m.status == 'Despacho' || m.status == 'Finalizado') {
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
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _isFilterVisible = !_isFilterVisible),
                      icon: Icon(_isFilterVisible ? Icons.filter_list_off : Icons.filter_list),
                      label: Text(_isFilterVisible ? 'Ocultar Filtros' : 'Mostrar Filtros'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildColumn(
                        title: 'Despacho',
                        statuses: const ['Despacho'],
                        dropStatus: 'Despacho',
                        flex: 1,
                      ),
                      _buildColumn(
                        title: 'En curso',
                        statuses: const ['En curso', 'Despachado', 'En sitio', 'Traslado', 'Arribado'],
                        dropStatus: 'En curso',
                        flex: 2,
                      ),
                      _buildColumn(
                        title: 'Finalizado',
                        statuses: const ['Finalizado'],
                        dropStatus: 'Finalizado',
                        flex: 1,
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
  }) {
    final columnItems = _items.where((item) => statuses.contains(item.status)).toList();
    final isEnCurso = title == 'En curso';
    
    return Expanded(
      flex: flex,
      child: KanbanColumn(
        title: title,
        count: columnItems.length,
        isGrid: isEnCurso,
        onAccept: (itemTitle) => _onItemDropped(itemTitle, dropStatus),
        children: columnItems.map((item) => KanbanCard(
          title: item.title,
          subtitle: item.subtitle,
          time: item.time,
          moviles: item.moviles,
          globalStatus: item.status,
          priority: item.priority,
          priorityColor: item.priorityColor,
          onCursorChange: _updateGlobalCursor,
        )).toList(),
      ),
    );
  }
}
