import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/components/custom_select.dart';
import '../../../shared/models/configuracion.dart';
import '../../../shared/models/victima.dart';
import '../../../shared/services/configuracion_service.dart';
import '../../../shared/services/victima_service.dart';
import '../controllers/ingreso_controller.dart';

class VictimaData {
  String id = UniqueKey().toString();
  int? idVictima; // ID asignado por el servidor tras el primer POST
  String nombre = '';
  String edad = '';
  int? idConfGenero;
  String dni = '';
  String? codigoTriage; 
  List<String> sintomasSeleccionados = [];
  String busqueda = '';
  List<PlatformFile> archivosAdjuntos = [];

  /// Convierte a Victima (modelo de API) para enviar al backend.
  Victima toVictima(int? idIncidente) {
    return Victima(
      idVictima: idVictima,
      nombresApellidos: nombre.isNotEmpty ? nombre : null,
      dni: int.tryParse(dni),
      idConfGenero: idConfGenero,
      edad: int.tryParse(edad),
      estadoActual: sintomasSeleccionados.isNotEmpty
          ? sintomasSeleccionados.join(', ')
          : null,
      idIncidente: idIncidente,
    );
  }

  /// Serializa para SharedPreferences (sin archivos adjuntos).
  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'idVictima': idVictima,
        'nombre': nombre,
        'edad': edad,
        'idConfGenero': idConfGenero,
        'dni': dni,
        'codigoTriage': codigoTriage,
        'sintomasSeleccionados': sintomasSeleccionados,
      };

  /// Restaura desde SharedPreferences.
  static VictimaData fromStorageJson(Map<String, dynamic> json) {
    final v = VictimaData();
    v.id = json['id'] ?? v.id;
    v.idVictima = json['idVictima'];
    v.nombre = json['nombre'] ?? '';
    v.edad = json['edad'] ?? '';
    v.idConfGenero = json['idConfGenero'];
    v.dni = json['dni'] ?? '';
    v.codigoTriage = json['codigoTriage'];
    v.sintomasSeleccionados = List<String>.from(json['sintomasSeleccionados'] ?? []);
    return v;
  }
}

class VictimasSection extends StatefulWidget {
  const VictimasSection({super.key});

  @override
  State<VictimasSection> createState() => _VictimasSectionState();
}

class _VictimasSectionState extends State<VictimasSection> with TickerProviderStateMixin {
  late List<VictimaData> _victimas;
  late TabController _tabController;

  final _ingresoController = IngresoController();
  final Map<String, Timer> _debounceTimers = {};
  static const String _storageKey = 'victimas_draft';
  bool _localLoaded = false;

  final List<String> _etiquetasSintomas = [
    'Dolor de pecho',
    'Convulsiones',
    'Intoxicación',
    'Traumatismo',
    'Dif. respiratoria',
    'Inconsciencia',
  ];

  @override
  void initState() {
    super.initState();
    _victimas = [VictimaData()];
    _initTabController();
    _cargarLocal();
  }

  // ── Persistencia local ────────────────────────────────────

  Future<void> _cargarLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      if (mounted && decoded.isNotEmpty) {
        setState(() {
          _victimas = decoded
              .map((j) => VictimaData.fromStorageJson(j as Map<String, dynamic>))
              .toList();
          _tabController.dispose();
          _initTabController();
          _localLoaded = true;
        });
      } else if (mounted) {
        setState(() => _localLoaded = true);
      }
    } catch (e) {
      debugPrint('Error al cargar víctimas locales: $e');
    }
  }

  Future<void> _guardarLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_victimas.map((v) => v.toStorageJson()).toList()),
    );
  }

  // ── Sync al backend ───────────────────────────────────────

  /// Programa un sync con debounce de 2 segundos por víctima.
  void _programarSync(VictimaData victima) {
    _debounceTimers[victima.id]?.cancel();
    _debounceTimers[victima.id] = Timer(const Duration(seconds: 2), () async {
      await _sincronizarVictima(victima);
    });
  }

  Future<void> _sincronizarVictima(VictimaData victima) async {
    final idIncidente = _ingresoController.incidenteActual.idIncidente;
    final payload = victima.toVictima(idIncidente);

    if (victima.idVictima == null) {
      // Solo hacer POST si hay algún dato mínimo
      if (victima.nombre.isEmpty && victima.dni.isEmpty && victima.idConfGenero == null) return;

      final creada = await VictimaService.crear(payload);
      if (creada != null && creada.idVictima != null && mounted) {
        setState(() => victima.idVictima = creada.idVictima);
        await _guardarLocal();
      }
    } else {
      await VictimaService.actualizar(payload);
    }
  }

  void _initTabController() {
    _tabController = TabController(length: _victimas.length, vsync: this);
  }

  void _addVictima() {
    setState(() {
      _victimas.add(VictimaData());
      _tabController.dispose();
      _initTabController();
      _tabController.index = _victimas.length - 1;
    });
  }

  void _removeVictima(int index) {
    if (_victimas.length > 1) {
      setState(() {
        _victimas.removeAt(index);
        _tabController.dispose();
        _initTabController();
        if (_tabController.index >= _victimas.length) {
          _tabController.index = _victimas.length - 1;
        }
      });
    }
  }

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.white60,
                    dividerColor: Colors.transparent,
                    tabs: _victimas
                        .asMap()
                        .entries
                        .map((e) => Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Víctima ${e.key + 1}'),
                                  if (_victimas.length > 1) ...[
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _removeVictima(e.key),
                                      child: const Icon(Icons.close, size: 14),
                                    ),
                                  ],
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _addVictima,
                tooltip: 'Agregar víctima',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _victimas.map((v) => _buildVictimaTab(theme, v)).toList(),
          ),
        ),
      ],
    );
  }

  InputDecoration _compactDecoration(String label, {Icon? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildVictimaTab(ThemeData theme, VictimaData victima) {
    return KeyedSubtree(
      key: ValueKey('${victima.id}_$_localLoaded'),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTriageBanner(theme, victima),
          const SizedBox(height: 16),
          _buildDatosRow(theme, victima),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: _buildBuscadorEtiquetasColumn(theme, victima),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildPreguntasRecomendacionesBox(theme, victima),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.pickFiles(
                  allowMultiple: true,
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
                );

                if (result != null) {
                  setState(() {
                    victima.archivosAdjuntos.addAll(result.files);
                  });
                }
              },
              icon: const Icon(Icons.attach_file, size: 20),
              label: const Text(
                'Adjuntar documentación',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          if (victima.archivosAdjuntos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: victima.archivosAdjuntos.map((file) {
                return Chip(
                  label: Text(
                    file.name,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      victima.archivosAdjuntos.remove(file);
                    });
                  },
                  backgroundColor: theme.colorScheme.surface,
                  side: const BorderSide(color: Colors.white24),
                );
              }).toList(),
            ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildTriageBanner(ThemeData theme, VictimaData victima) {
    Color codeColor;
    String codeText;

    switch (victima.codigoTriage) {
      case 'Rojo':
        codeColor = Colors.red.shade600;
        codeText = 'ROJO - EMERGENCIA CRÍTICA';
        break;
      case 'Amarillo':
        codeColor = Colors.yellow.shade700;
        codeText = 'AMARILLO - URGENCIA';
        break;
      case 'Verde':
        codeColor = Colors.green.shade600;
        codeText = 'VERDE - NO URGENTE';
        break;
      default:
        codeColor = Colors.white24;
        codeText = 'SIN CÓDIGO';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: codeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: codeColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: codeColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'CÓDIGO ACTUAL: $codeText',
              style: theme.textTheme.titleMedium?.copyWith(
                color: codeColor == Colors.white24 ? Colors.white : codeColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          if (victima.codigoTriage == 'Rojo') ...[
            ElevatedButton.icon(
              onPressed: () {
              },
              icon: const Icon(Icons.airport_shuttle, size: 18),
              label: const Text('DESPACHO INMEDIATO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
          ],
          _buildTriageSelector(victima),
        ],
      ),
    );
  }

  Widget _buildTriageSelector(VictimaData victima) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTriageOptionButton(victima, 'Verde', Colors.green),
        const SizedBox(width: 8),
        _buildTriageOptionButton(victima, 'Amarillo', Colors.yellow),
        const SizedBox(width: 8),
        _buildTriageOptionButton(victima, 'Rojo', Colors.red),
      ],
    );
  }

  Widget _buildTriageOptionButton(VictimaData victima, String code, Color color) {
    final isSelected = victima.codigoTriage == code;
    return GestureDetector(
      onTap: () {
        setState(() => victima.codigoTriage = code);
        _guardarLocal();
        _programarSync(victima);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : color.withOpacity(0.2),
          border: Border.all(color: color, width: 2),
        ),
        child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
      ),
    );
  }



  Widget _buildDatosRow(ThemeData theme, VictimaData victima) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: victima.nombre,
            decoration: _compactDecoration('Nombre y apellido'),
            onChanged: (val) {
              victima.nombre = val;
              _guardarLocal();
              _programarSync(victima);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            initialValue: victima.edad,
            decoration: _compactDecoration('Edad'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              victima.edad = val;
              _guardarLocal();
              _programarSync(victima);
            },
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
                victima.idConfGenero = val.idconfiguracion;
                _guardarLocal();
                _programarSync(victima);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            initialValue: victima.dni,
            decoration: _compactDecoration('DNI'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              victima.dni = val;
              _guardarLocal();
              _programarSync(victima);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBuscadorEtiquetasColumn(ThemeData theme, VictimaData victima) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          decoration: _compactDecoration(
            'Buscar síntoma o afección',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: victima.busqueda.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        victima.busqueda = '';
                      });
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {
              victima.busqueda = val;
            });
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _etiquetasSintomas.map((etiqueta) {
            bool isSelected = victima.sintomasSeleccionados.contains(etiqueta);
            return ActionChip(
              label: Text(etiqueta),
              backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.surface,
              side: BorderSide(color: isSelected ? theme.colorScheme.primary : Colors.white24),
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    victima.sintomasSeleccionados.remove(etiqueta);
                  } else {
                    victima.sintomasSeleccionados.add(etiqueta);
                  }
                });
                _guardarLocal();
                _programarSync(victima);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreguntasRecomendacionesBox(ThemeData theme, VictimaData victima) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: victima.sintomasSeleccionados.isNotEmpty || victima.busqueda.isNotEmpty
          ? _buildPreguntasSintomas(theme, victima)
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Seleccione un síntoma o busque\npara ver el proceso de asistencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ),
    );
  }

  Widget _buildPreguntasSintomas(ThemeData theme, VictimaData victima) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment, size: 20, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                'Proceso de asistencia sugerido',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPreguntaItem(theme, '¿El paciente está consciente?'),
                  const SizedBox(height: 8),
                  _buildPreguntaItem(theme, '¿Respira con normalidad?'),
                  const SizedBox(height: 8),
                  _buildPreguntaItem(theme, '¿Tiene pulso palpable?'),
                  if (victima.sintomasSeleccionados.contains('Dolor de pecho')) ...[
                    const SizedBox(height: 8),
                    _buildPreguntaItem(theme, '¿El dolor se irradia al brazo o mandíbula?'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreguntaItem(ThemeData theme, String pregunta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(pregunta, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceChip(label: const Text('Sí'), selected: false, onSelected: (_) {}),
              const SizedBox(width: 4),
              ChoiceChip(label: const Text('No'), selected: false, onSelected: (_) {}),
            ],
          ),
        ],
      ),
    );
  }
}
