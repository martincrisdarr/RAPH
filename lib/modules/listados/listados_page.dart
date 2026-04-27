import 'package:flutter/material.dart';
import '../../shared/services/listados_service.dart';

class ListadosPage extends StatefulWidget {
  const ListadosPage({super.key});

  @override
  State<ListadosPage> createState() => _ListadosPageState();
}

enum _ListadoTab { llamados, incidentes }

class _ListadosPageState extends State<ListadosPage> {
  static const _llamadosColumns = [
    'Tipo de ingreso',
    'Fecha y Hora',
    'Usuario del Sistema',
    'Contacto de llamada',
    'Tipo de incidente',
    'Dirección',
    'Cantidad de Vícimas',
    'Código',
    'Acciones',
  ];

  static const _llamadosColumnKeys = [
    'tipoIngreso',
    'fechaHora',
    'usuarioSistema',
    'contactoLlamada',
    'tipoIncidente',
    'direccion',
    'cantidadVictimas',
    'codigo',
    'acciones',
  ];

  static const _llamadosColumnFlex = [3, 3, 3, 3, 3, 3, 3, 3, 2];

  static const _incidentesColumns = [
    'Fecha y Hora',
    'Usuario del Sistema',
    'Tipo de incidente',
    'Cantidad de Víctimas',
    'Estado',
    'Novedades',
    'Acciones',
  ];

  static const _incidentesColumnKeys = [
    'fechaHora',
    'usuarioSistema',
    'tipoIncidente',
    'cantidadVictimas',
    'estado',
    'novedades',
    'acciones',
  ];

  static const _incidentesColumnFlex = [2, 2, 2, 2, 2, 2, 1];

  static const _rowHeight = 40.0;
  _ListadoTab _activeTab = _ListadoTab.llamados;
  bool _isLoading = true;
  String? _llamadosError;
  String? _incidentesError;

  List<Map<String, String>> _llamados = const [];
  List<Map<String, String>> _incidentes = const [];

  List<String> get _activeColumns {
    return _activeTab == _ListadoTab.llamados ? _llamadosColumns : _incidentesColumns;
  }

  List<String> get _activeColumnKeys {
    return _activeTab == _ListadoTab.llamados ? _llamadosColumnKeys : _incidentesColumnKeys;
  }

  List<int> get _activeColumnFlex {
    return _activeTab == _ListadoTab.llamados ? _llamadosColumnFlex : _incidentesColumnFlex;
  }

  List<Map<String, String>> get _activeRows {
    return _activeTab == _ListadoTab.llamados ? _llamados : _incidentes;
  }

  String? get _activeError {
    return _activeTab == _ListadoTab.llamados ? _llamadosError : _incidentesError;
  }

  @override
  void initState() {
    super.initState();
    _cargarLlamados();
  }

  Future<void> _cargarLlamados() async {
    setState(() {
      _isLoading = true;
      _llamadosError = null;
    });

    try {
      final demandas = await ListadosService.obtenerDemandasRecibidas();
      setState(() {
        _llamados = demandas
            .map(_mapDemandaToLlamado)
            .toList();
      });
    } catch (e) {
      setState(() {
        _llamados = const [];
        _llamadosError = 'No se pudo cargar Llamados.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cargarIncidentes() async {
    setState(() {
      _isLoading = true;
      _incidentesError = null;
    });

    try {
      final incidentes = await ListadosService.obtenerIncidentes();
      setState(() {
        _incidentes = incidentes.map(_mapIncidenteToIncidenteRow).toList();
      });
    } catch (e) {
      setState(() {
        _incidentes = const [];
        _incidentesError = 'No se pudo cargar Incidentes.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onTabChanged(_ListadoTab tab) async {
    if (_activeTab == tab) return;

    setState(() {
      _activeTab = tab;
    });

    if (tab == _ListadoTab.incidentes && _incidentes.isEmpty && _incidentesError == null) {
      await _cargarIncidentes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activeTab == _ListadoTab.llamados ? 'Llamados' : 'Incidentes',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Listado de llamadas con datos operativos.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _onTabChanged(_ListadoTab.llamados),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activeTab == _ListadoTab.llamados
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  foregroundColor: _activeTab == _ListadoTab.llamados
                      ? Colors.black
                      : Colors.white70,
                  side: BorderSide(
                    color: _activeTab == _ListadoTab.llamados
                        ? Colors.transparent
                        : Colors.white24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Llamados'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _onTabChanged(_ListadoTab.incidentes),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activeTab == _ListadoTab.incidentes
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  foregroundColor: _activeTab == _ListadoTab.incidentes
                      ? Colors.black
                      : Colors.white70,
                  side: BorderSide(
                    color: _activeTab == _ListadoTab.incidentes
                        ? Colors.transparent
                        : Colors.white24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Incidentes'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_activeError != null)
            Expanded(
              child: Center(
                child: Text(
                  _activeError!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildTableHeader(theme),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.maxHeight;
                        final visibleRows = (availableHeight / _rowHeight).ceil();
                        final rows = visibleRows > _activeRows.length ? visibleRows : _activeRows.length;

                        return Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white12),
                            ),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: rows,
                            itemBuilder: (context, index) {
                              final rowData = index < _activeRows.length ? _activeRows[index] : null;
                              return _buildTableRow(theme, rowData);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Map<String, String> _mapDemandaToLlamado(Map<String, dynamic> demanda) {
    final incidente = demanda['incidente'] is Map<String, dynamic>
        ? demanda['incidente'] as Map<String, dynamic>
        : null;

    final tipoIngreso = _readValue(demanda, const ['tipo_ingreso.descripcion', 'tipo_ingreso.nombre']);
    final fechaHora = _readValue(demanda, const ['fechahora', 'fecha_hora', 'fechaHora', 'fecha']);
    final usuarioSistema = _readValue(demanda, const ['usuario', 'usuario_sistema', 'usuarioSistema']);
    final contacto = _readValue(demanda, const ['nro_llamada_entrante', 'contacto_llamada', 'contactoLlamada', 'telefono']);
    final tipoIncidente = _readValue(incidente ?? const {}, const ['descripcion']);
    final direccion = _readValue(incidente ?? const {}, const ['direccion']);
    final cantidadVictimas = incidente?['victimas'] is List
        ? (incidente!['victimas'] as List).length.toString()
        : _readValue(demanda, const ['cantidad_victimas', 'cantidadVictimas']);
    final codigo = _readValue(demanda, const ['iddemandarecibida', 'codigo', 'id', 'id_demanda']);

    return {
      'tipoIngreso': tipoIngreso,
      'fechaHora': fechaHora,
      'usuarioSistema': usuarioSistema,
      'contactoLlamada': contacto,
      'tipoIncidente': tipoIncidente,
      'direccion': direccion,
      'cantidadVictimas': cantidadVictimas,
      'codigo': codigo,
    };
  }

  Map<String, String> _mapIncidenteToIncidenteRow(Map<String, dynamic> incidente) {
    final fechaHora = _readValue(incidente, const ['fechahoraauto', 'fecha_hora', 'fechaHora', 'fecha']);
    final usuarioSistema = _readValue(incidente, const ['usuario_sistema', 'usuarioSistema', 'usuario']);
    final tipoIncidente = _readValue(incidente, const ['tipo_incidente', 'tipoIncidente', 'descripcion']);
    final estado = _readValue(incidente, const ['estado.descripcion', 'estado']);
    final novedades = _readValue(incidente, const ['novedades', 'observaciones', 'demanda_recibidas.0.novedades']);

    final victimasRaw = incidente['victimas'];
    final cantidadVictimas = victimasRaw is List ? victimasRaw.length.toString() : _readValue(incidente, const ['cantidad_victimas', 'cantidadVictimas']);

    return {
      'fechaHora': fechaHora,
      'usuarioSistema': usuarioSistema,
      'tipoIncidente': tipoIncidente,
      'cantidadVictimas': cantidadVictimas,
      'estado': estado,
      'novedades': novedades,
    };
  }

  String _readValue(Map<String, dynamic> data, List<String> candidates) {
    for (final candidate in candidates) {
      final value = _getNestedValue(data, candidate);
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else if (current is List) {
        final index = int.tryParse(key);
        if (index == null || index < 0 || index >= current.length) {
          return null;
        }
        current = current[index];
      } else {
        return null;
      }
    }
    return current;
  }

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white10,
      ),
      height: _rowHeight,
      child: Row(
        children: [
          for (int i = 0; i < _activeColumns.length; i++)
            Expanded(
              flex: _activeColumnFlex[i],
              child: Container(
                alignment: _activeColumnKeys[i] == 'acciones' ? Alignment.center : Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: i == _activeColumns.length - 1 ? Colors.transparent : Colors.white12,
                    ),
                  ),
                ),
                child: Text(
                  _activeColumns[i],
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(ThemeData theme, Map<String, String>? llamado) {
    return Container(
      height: _rowHeight,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _activeColumns.length; i++)
            _activeColumnKeys[i] == 'acciones'
                ? Expanded(
                    flex: _activeColumnFlex[i],
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: i == _activeColumns.length - 1
                                ? Colors.transparent
                                : Colors.white12,
                          ),
                        ),
                      ),
                      child: llamado == null
                          ? const SizedBox.shrink()
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.visibility_outlined, size: 20, color: Colors.white54),
                                SizedBox(width: 12),
                                Icon(Icons.edit_outlined, size: 20, color: Colors.white54),
                                SizedBox(width: 12),
                                Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              ],
                            ),
                    ),
                  )
                : _buildCell(
                    theme,
                    _activeColumnFlex[i],
                    llamado?[_activeColumnKeys[i]] ?? '',
                    withRightBorder: i != _activeColumns.length - 1,
                  ),
        ],
      ),
    );
  }

  Widget _buildCell(
    ThemeData theme,
    int flex,
    String value, {
    TextAlign textAlign = TextAlign.left,
    bool withRightBorder = true,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: withRightBorder ? Colors.white12 : Colors.transparent,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final style = theme.textTheme.bodySmall?.copyWith(color: Colors.white70);
            final painter = TextPainter(
              text: TextSpan(text: value, style: style),
              maxLines: 1,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);
            final isOverflowing = painter.didExceedMaxLines;

            final text = Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: style,
            );

            if (!isOverflowing || value.trim().isEmpty) return text;
            return Tooltip(
              message: value,
              waitDuration: const Duration(milliseconds: 250),
              child: text,
            );
          },
        ),
      ),
    );
  }
}
