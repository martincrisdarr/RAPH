import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/ingreso_controller.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/components/custom_select.dart';
import '../../../shared/models/configuracion.dart';
import '../../../shared/services/configuracion_service.dart';

class DatosVictimasSection extends StatefulWidget {
  final VoidCallback? onDespacho;
  const DatosVictimasSection({super.key, this.onDespacho});

  @override
  State<DatosVictimasSection> createState() => _DatosVictimasSectionState();
}

class _DatosVictimasSectionState extends State<DatosVictimasSection> with TickerProviderStateMixin {
  final _ingresoController = IngresoController();
  late TabController _victimasTabController;
  int _lastVictimasCount = 0;

  @override
  void initState() {
    super.initState();
    _lastVictimasCount = _ingresoController.victimas.length;
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

    _ingresoController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
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

      if (_victimasTabController.index != _ingresoController.selectedVictimaIndex) {
        _victimasTabController.animateTo(_ingresoController.selectedVictimaIndex);
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    _victimasTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        if (widget.onDespacho != null) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: widget.onDespacho,
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('DESPACHO RÁPIDO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary, width: 1.0),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
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
