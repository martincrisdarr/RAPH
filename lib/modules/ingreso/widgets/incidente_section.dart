import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/ingreso_controller.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/components/custom_select.dart';
import '../../../shared/models/configuracion.dart';
import '../../../shared/services/configuracion_service.dart';

class IncidenteSection extends StatefulWidget {
  const IncidenteSection({super.key});

  @override
  State<IncidenteSection> createState() => _IncidenteSectionState();
}

class _IncidenteSectionState extends State<IncidenteSection> with TickerProviderStateMixin {
  final _ingresoController = IngresoController();
  late final TextEditingController _descripcionIncidenteController;
  late TabController _mainTabController;
  late TabController _victimasTabController;
  
  final List<Map<String, dynamic>> _protocolosSugeridos = [
    {'nombre': 'Accidente Vehicular', 'color': Colors.red.shade400},
    {'nombre': 'Derrumbe', 'color': Colors.red.shade400},
    {'nombre': 'Catástrofe', 'color': Colors.red.shade400},
    {'nombre': 'Gases Tóxicos', 'color': Colors.red.shade400},
    {'nombre': 'Incendio', 'color': Colors.red.shade400},
    {'nombre': 'Accidente Industrial', 'color': Colors.red.shade400},
  ];
  final List<String> _protocolosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    _descripcionIncidenteController = TextEditingController(text: _ingresoController.incidenteActual.descripcion ?? '');
    _mainTabController = TabController(length: 2, vsync: this);
    _victimasTabController = TabController(length: _ingresoController.victimas.length, vsync: this);
    
    _victimasTabController.addListener(() {
      if (!_victimasTabController.indexIsChanging) {
        _ingresoController.selectedVictimaIndex = _victimasTabController.index;
      }
    });

    _ingresoController.addListener(_onControllerUpdate);
  }

  int? _lastIncidenteId;
  int _lastVictimasCount = 0;

  void _onControllerUpdate() {
    if (mounted) {
      final incidente = _ingresoController.incidenteActual;
      
      // Sincronización de descripción
      if (incidente.idIncidente != _lastIncidenteId) {
        _lastIncidenteId = incidente.idIncidente;
        _descripcionIncidenteController.text = incidente.descripcion ?? '';
      } else {
        final nuevaDesc = incidente.descripcion ?? '';
        if (_descripcionIncidenteController.text != nuevaDesc) {
          _descripcionIncidenteController.text = nuevaDesc;
        }
      }

      // Sincronización de cantidad de víctimas para el TabController
      if (_ingresoController.victimas.length != _lastVictimasCount) {
        _lastVictimasCount = _ingresoController.victimas.length;
        _victimasTabController.dispose();
        _victimasTabController = TabController(
          length: _lastVictimasCount, 
          vsync: this,
          initialIndex: _ingresoController.selectedVictimaIndex.clamp(0, _lastVictimasCount - 1),
        );
        _victimasTabController.addListener(() {
          if (!_victimasTabController.indexIsChanging) {
            _ingresoController.selectedVictimaIndex = _victimasTabController.index;
          }
        });
      }

      // Asegurar que el índice visual coincida con el del controlador
      if (_victimasTabController.index != _ingresoController.selectedVictimaIndex) {
        _victimasTabController.animateTo(_ingresoController.selectedVictimaIndex);
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    _descripcionIncidenteController.dispose();
    _mainTabController.dispose();
    _victimasTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _mainTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.white60,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'INCIDENTE'),
            Tab(text: 'VÍCTIMAS'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _mainTabController,
            children: [
              _buildIncidenteTab(theme),
              _buildVictimasTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncidenteTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextFormField(
              controller: _descripcionIncidenteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (val) => _ingresoController.updateIncidente(descripcion: val),
              decoration: const InputDecoration(
                labelText: 'Descripción del incidente',
                alignLabelWithHint: true,
                hintText: 'Ingresá los detalles del incidente...',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Protocolos rápidos:', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _protocolosSugeridos.map((protoData) {
                final protocolo = protoData['nombre'] as String;
                final color = protoData['color'] as Color;
                final isSelected = _protocolosSeleccionados.contains(protocolo);
                
                return ActionChip(
                  label: Text(
                    protocolo, 
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : color.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isSelected 
                      ? color.withOpacity(0.4) 
                      : color.withOpacity(0.1),
                  side: BorderSide(
                    color: isSelected ? color : color.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    setState(() {
                      if (isSelected) {
                        _protocolosSeleccionados.remove(protocolo);
                      } else {
                        _protocolosSeleccionados.add(protocolo);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictimasTab(ThemeData theme) {
    final victimas = _ingresoController.victimas;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              Flexible(
                child: IntrinsicWidth(
                  child: TabBar(
                    controller: _victimasTabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.white60,
                    dividerColor: Colors.transparent,
                    tabs: victimas.asMap().entries.map((e) {
                      final victima = e.value;
                      final nombre = victima.nombre.trim();
                      String tabLabel = 'Víctima ${e.key + 1}';
                      
                      if (nombre.isNotEmpty) {
                        tabLabel = nombre.split(' ').first;
                        if (tabLabel.length > 10) tabLabel = '${tabLabel.substring(0, 8)}..';
                      }

                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tabLabel),
                            if (victimas.length > 1) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _ingresoController.removeVictima(e.key),
                                child: const Icon(Icons.close, size: 14),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _ingresoController.addVictima(),
                tooltip: 'Agregar víctima',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _victimasTabController,
            children: victimas.asMap().entries.map((e) => _buildVictimaForm(theme, e.key, e.value)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVictimaForm(ThemeData theme, int index, VictimaData victima) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            initialValue: victima.nombre,
            decoration: const InputDecoration(labelText: 'Nombre y apellido'),
            onChanged: (val) => _ingresoController.updateVictima(index, nombre: val),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: victima.edad,
                  decoration: const InputDecoration(labelText: 'Edad'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) => _ingresoController.updateVictima(index, edad: val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: CustomSelect<Configuracion>(
                  label: 'Género',
                  fetchItems: () => ConfiguracionService.obtenerGeneros(),
                  itemLabel: (item) => item.descripcion,
                  initialSelectionId: victima.idConfGenero,
                  matchById: (item) => item.idconfiguracion,
                  onSelected: (val) {
                    if (val != null) {
                      _ingresoController.updateVictima(index, idConfGenero: val.idconfiguracion);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: victima.dni,
            decoration: const InputDecoration(labelText: 'DNI'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) => _ingresoController.updateVictima(index, dni: val),
          ),
        ],
      ),
    );
  }
}
