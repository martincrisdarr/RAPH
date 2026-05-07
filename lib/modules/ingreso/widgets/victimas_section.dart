import 'package:flutter/material.dart';
import '../../../shared/components/custom_select.dart';

class VictimaData {
  String id = UniqueKey().toString();
  String nombre = '';
  String edad = '';
  String genero = '';
  String dni = '';
  String? codigoTriage; 
  List<String> sintomasSeleccionados = [];
  String busqueda = '';
}

class VictimasSection extends StatefulWidget {
  const VictimasSection({super.key});

  @override
  State<VictimasSection> createState() => _VictimasSectionState();
}

class _VictimasSectionState extends State<VictimasSection> with TickerProviderStateMixin {
  late List<VictimaData> _victimas;
  late TabController _tabController;

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
    return Padding(
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
        ],
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
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? color : color.withOpacity(0.2),
        border: Border.all(color: color, width: 2),
      ),
      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
    );
  }



  Widget _buildDatosRow(ThemeData theme, VictimaData victima) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            decoration: _compactDecoration('Nombre y apellido'),
            onChanged: (val) => victima.nombre = val,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            decoration: _compactDecoration('Edad'),
            keyboardType: TextInputType.number,
            onChanged: (val) => victima.edad = val,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: CustomSelect<String>(
            label: 'Género',
            items: const ['Masculino', 'Femenino', 'Otro', 'No especifica'],
            itemLabel: (item) => item,
            initialSelection: victima.genero.isNotEmpty ? victima.genero : null,
            onSelected: (val) {
              if (val != null) {
                victima.genero = val;
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            decoration: _compactDecoration('DNI'),
            keyboardType: TextInputType.number,
            onChanged: (val) => victima.dni = val,
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
