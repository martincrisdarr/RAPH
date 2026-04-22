import 'package:flutter/material.dart';
import '../../shared/components/custom_stepper.dart';
import '../../shared/components/custom_select.dart';
import '../../shared/models/configuracion.dart';
import '../../shared/services/configuracion_service.dart';
import '../../shared/models/localidad.dart';
import '../../shared/services/localidad_service.dart';
import '../../shared/components/autocomplete_select.dart';

class IngresoPage extends StatefulWidget {
  const IngresoPage({super.key});

  @override
  State<IngresoPage> createState() => _IngresoPageState();
}

class _IngresoPageState extends State<IngresoPage> {
  int _currentStep = 0;
  bool _isNuevo = true;
  bool _isLinkMode = false;
  final TextEditingController _domicilioController = TextEditingController();

  static const _tableColumns = ['ID', 'Fecha', 'Tipo', 'Dirección', 'Estado'];
  static const _tableColumnFlex = [1, 2, 2, 4, 2];

  final List<String> _steps = [
    'Incidente',
    'Despacho',
    'En sitio',
    'Traslado',
    'Fin',
    'Cierre',
  ];

  // Mock: últimos incidentes en curso (en producción vendrá de la API)
  final List<Map<String, String>> _incidentesEnCurso = const [
    {'id': '#001241', 'fecha': '21/04 14:18', 'tipo': 'Médico', 'direccion': 'Av. Corrientes 1580, CABA', 'estado': 'DESPACHO'},
    {'id': '#001238', 'fecha': '21/04 13:55', 'tipo': 'Accidente vial', 'direccion': 'Belgrano y Tucumán', 'estado': 'EN SITIO'},
    {'id': '#001236', 'fecha': '21/04 13:40', 'tipo': 'Incendio', 'direccion': 'Mitre 340, Ramos Mejía', 'estado': 'TRASLADO'},
    {'id': '#001233', 'fecha': '21/04 13:20', 'tipo': 'Médico', 'direccion': 'San Martín 890, Morón', 'estado': 'DESPACHO'},
    {'id': '#001229', 'fecha': '21/04 12:58', 'tipo': 'Médico', 'direccion': 'Rivadavia 2200, CABA', 'estado': 'EN SITIO'},
  ];

  @override
  void dispose() {
    _domicilioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomStepper(
            steps: _steps,
            currentStep: _currentStep,
            onStepTapped: (index) {
              setState(() {
                _currentStep = index;
              });
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 380,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 1, child: _buildSection(context, 'INGRESO', child: _buildIngresoContent())),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildSection(context, 'UBICACIÓN', child: _buildUbicacionContent())),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Expanded(child: _buildSection(context, 'INCIDENTE')),
                            const SizedBox(height: 16),
                            Expanded(child: _buildSection(context, 'VÍCTIMAS')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _buildSection(context, 'NOVEDADES')),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIngresoContent() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: () => setState(() => _isNuevo = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: !_isNuevo ? theme.colorScheme.primary : theme.colorScheme.surface,
                foregroundColor: !_isNuevo ? Colors.black : Colors.white,
                side: BorderSide(color: !_isNuevo ? Colors.transparent : Colors.white24),
              ),
              child: const Text('INCIDENTE EN CURSO'),
            ),
          ],
        ),

        // --- Formulario NUEVO ---
        if (_isNuevo) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomSelect<Configuracion>(
                  label: 'Ingreso',
                  fetchItems: () => ConfiguracionService.obtenerTiposIngreso(),
                  itemLabel: (item) => item.descripcion,
                  onSelected: (val) {
                    if (val != null) {
                      debugPrint('Seleccionado: ${val.idconfiguracion}');
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  keyboardType: TextInputType.name,
                ),
              ),
            ],
          ),
        ],

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
            child: ListView.separated(
              itemCount: _incidentesEnCurso.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: Colors.white10,
              ),
              itemBuilder: (context, index) {
                final inc = _incidentesEnCurso[index];
                return _buildIncidenteRow(theme, inc, _tableColumnFlex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidenteRow(
    ThemeData theme,
    Map<String, String> inc,
    List<int> flex,
  ) {
    final estado = inc['estado']!;
    final estadoColor = _estadoColor(estado);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => debugPrint('Editar incidente ${inc['id']}'),
        hoverColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // ID
              Expanded(
                flex: flex[0],
                child: Text(
                  inc['id']!,
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
                  inc['fecha']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ),
              // Tipo
              Expanded(
                flex: flex[2],
                child: Text(
                  inc['tipo']!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.87),
                  ),
                ),
              ),
              // Dirección
              Expanded(
                flex: flex[3],
                child: Text(
                  inc['direccion']!,
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
    switch (estado) {
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

  Widget _buildUbicacionContent() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Campo Domicilio con modo toggle ---
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _domicilioController,
                decoration: InputDecoration(
                  labelText: _isLinkMode ? 'Pegá el link de WhatsApp...' : 'Domicilio *',
                  labelStyle: TextStyle(
                    color: _isLinkMode ? primary : Colors.white54,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _isLinkMode ? primary : Colors.white24,
                      width: _isLinkMode ? 1.5 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: primary,
                      width: 2,
                    ),
                  ),
                  fillColor: _isLinkMode
                      ? primary.withValues(alpha: 0.06)
                      : Theme.of(context).inputDecorationTheme.fillColor,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLinkMode)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'LINK',
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.link_rounded,
                          color: _isLinkMode ? primary : Colors.white38,
                          size: 20,
                        ),
                        tooltip: _isLinkMode ? 'Volver a modo manual' : 'Pegar link de WhatsApp',
                        onPressed: () {
                          setState(() {
                            _isLinkMode = !_isLinkMode;
                            _domicilioController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: AutocompleteSelect<Localidad>(
                label: 'Buscar localidad...',
                fetchSuggestions: (query) => LocalidadService.buscar(query),
                itemLabel: (item) => item.descripcion,
                onSelected: (item) {
                  if (item != null) {
                    debugPrint('Localidad seleccionada: ${item.id} - ${item.nombreCompleto}');
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver en el mapa'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  side: BorderSide(color: theme.colorScheme.primary),
                  foregroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, color: Colors.white24, size: 40),
                  SizedBox(height: 8),
                  Text('Google Maps', style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, {Widget? child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Este Expanded asegura que el área interior crezca y pueda contener más cosas en el futuro
          Expanded(
            child: child ?? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                 color: Colors.transparent,
                 borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        ],
      ),
    );
  }
}

