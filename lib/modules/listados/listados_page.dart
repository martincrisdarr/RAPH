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
  final String movil;
  String status;

  KanbanItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.priority,
    required this.priorityColor,
    required this.movil,
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
  List<Map<String, dynamic>> _rawLlamadas = [];

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
    debugPrint('🚀 INICIANDO LLAMADA GET: Cargando datos de Demandas y Llamadas...');
    setState(() => _isLoading = true);
    try {
      // Dejamos la conexión lista llamando a los endpoints seleccionados
      final results = await Future.wait([
        ListadosService.obtenerDemandasRecibidas(),
        ListadosService.obtenerLlamadas(),
      ]);

      setState(() {
        _rawDemandas = results[0];
        _rawLlamadas = results[1];
        _isLoading = false;
      });
      
      print('Conexión lista: ${_rawDemandas.length} demandas y ${_rawLlamadas.length} llamadas cargadas.');
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
      movil: 'Móvil 1',
      status: 'En curso',
    ),
    KanbanItem(
      id: '2',
      title: 'Dolor Torácico',
      subtitle: 'Calle Mitre 450',
      time: 'Hace 12m',
      priority: 'ROJO',
      priorityColor: Colors.redAccent,
      movil: 'Móvil 3',
      status: 'En curso',
    ),
    KanbanItem(
      id: '3',
      title: 'Caída de Altura',
      subtitle: 'Obra en construcción',
      time: 'Hace 20m',
      priority: 'AMARILLO',
      priorityColor: Colors.orangeAccent,
      movil: 'Móvil 2',
      status: 'En curso',
    ),
    KanbanItem(
      id: '4',
      title: 'Asistencia Médica',
      subtitle: 'B° Confluencia',
      time: 'Hace 15m',
      priority: 'VERDE',
      priorityColor: Colors.greenAccent,
      movil: 'Móvil 5',
      status: 'Despachado',
    ),
    KanbanItem(
      id: '5',
      title: 'Convulsiones',
      subtitle: 'Escuela N° 121',
      time: 'Hace 8m',
      priority: 'ROJO',
      priorityColor: Colors.redAccent,
      movil: 'Móvil 1',
      status: 'En sitio',
    ),
    KanbanItem(
      id: '6',
      title: 'Traslado Programado',
      subtitle: 'Hospital Provincial',
      time: 'Hace 45m',
      priority: 'AMARILLO',
      priorityColor: Colors.orangeAccent,
      movil: 'Móvil 4',
      status: 'Traslado',
    ),
    KanbanItem(
      id: '7',
      title: 'Emergencia Respiratoria',
      subtitle: 'B° San Lorenzo',
      time: 'Hace 30m',
      priority: 'ROJO',
      priorityColor: Colors.redAccent,
      movil: 'Móvil 2',
      status: 'Arribado',
    ),
    KanbanItem(
      id: '8',
      title: 'Control de Signos',
      subtitle: 'Centro Cívico',
      time: 'Hace 1h',
      priority: 'VERDE',
      priorityColor: Colors.greenAccent,
      movil: 'Móvil 6',
      status: 'Finalizado',
    ),
  ];

  void _onItemDropped(String itemTitle, String newStatus) {
    setState(() {
      final itemIndex = _items.indexWhere((item) => item.title == itemTitle);
      if (itemIndex != -1) {
        _items[itemIndex].status = newStatus;
      }
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
    
    return Stack(
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
                    _buildColumn('En curso'),
                    _buildColumn('Despachado'),
                    _buildColumn('En sitio'),
                    _buildColumn('Traslado'),
                    _buildColumn('Arribado'),
                    _buildColumn('Finalizado'),
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
    );
  }

  Widget _buildColumn(String status) {
    final columnItems = _items.where((item) => item.status == status).toList();
    
    return Expanded(
      child: KanbanColumn(
        title: status,
        count: columnItems.length,
        onAccept: (itemTitle) => _onItemDropped(itemTitle, status),
        children: columnItems.map((item) => KanbanCard(
          title: item.title,
          subtitle: item.subtitle,
          time: item.time,
          movil: item.movil,
          priority: item.priority,
          priorityColor: item.priorityColor,
        )).toList(),
      ),
    );
  }
}
