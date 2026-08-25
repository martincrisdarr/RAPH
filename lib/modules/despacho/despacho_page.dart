import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../shared/theme/app_theme_tokens.dart';
import '../../shared/models/unidad.dart';
import '../../shared/models/movil.dart';
import '../../shared/models/demanda_recibida.dart';
import '../../shared/models/victima.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'controllers/despacho_controller.dart';

class DespachoPage extends StatefulWidget {
  const DespachoPage({super.key});

  @override
  State<DespachoPage> createState() => _DespachoPageState();
}

class _DespachoPageState extends State<DespachoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DespachoController _controller = DespachoController();
  
  // Cache de íconos personalizados de móviles para Google Maps
  final Map<String, BitmapDescriptor> _movilMarkerCache = {};

  Future<BitmapDescriptor> _getMovilMarkerIcon(Color color) async {
    final key = 'movil_cross_${color.toARGB32()}';
    if (_movilMarkerCache.containsKey(key)) {
      return _movilMarkerCache[key]!;
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 36.0;
    final double center = size / 2;

    // Fondo circular oscuro
    final Paint bgPaint = Paint()..color = const Color(0xFF0F172A);
    final Paint borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(center, center), center - 2, bgPaint);
    canvas.drawCircle(Offset(center, center), center - 2, borderPaint);

    // Dibujar Cruz Médica ✚ en el centro con Paint
    final Paint crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const double crossRadius = 6.5;
    canvas.drawLine(Offset(center - crossRadius, center), Offset(center + crossRadius, center), crossPaint);
    canvas.drawLine(Offset(center, center - crossRadius), Offset(center, center + crossRadius), crossPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
    _movilMarkerCache[key] = descriptor;
    return descriptor;
  }
  
  // Estado local de selección
  DemandaRecibida? _selectedIncident;
  Movil? _selectedMovil;
  Timer? _incidentesTimer;
  
  // Controladores de mapa
  GoogleMapController? _mapController;

  String _getCategoriaEstado(String estado) {
    switch (estado) {
      case 'Disponible':
      case 'En sitio':
        return 'Activo';
      case 'Despachado':
      case 'Traslado':
        return 'En tránsito';
      case 'Inactivo':
      default:
        return 'Inactivo';
    }
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria) {
      case 'Activo':
        return AppColors.accentGreen;
      case 'En tránsito':
        return AppColors.accentBlue;
      case 'Inactivo':
      default:
        return Colors.white38;
    }
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _controller.inicializar();
    _controller.cargarIncidentesActivos();
    _iniciarPollingIncidentes();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      _controller.cargarIncidentesActivos();
    } else if (_tabController.index == 1) {
      _controller.cargarMoviles();
    } else if (_tabController.index == 2) {
      _controller.cargarUnidades();
    }
  }

  void _iniciarPollingIncidentes() {
    _incidentesTimer?.cancel();
    _incidentesTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_tabController.index == 0 && _selectedIncident == null) {
        _controller.cargarIncidentesActivos();
      }
    });
  }

  @override
  void dispose() {
    _incidentesTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.accentBlue),
                  SizedBox(height: 16),
                  Text('Cargando módulo de despacho...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera Principal
                _buildHeader(theme),
                const SizedBox(height: 24),
                
                // TabBar de Navegación
                _buildTabBar(theme),
                const SizedBox(height: 24),
                
                // TabBarView Contenido
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(), // Evitar deslizamientos accidentales
                    children: [
                      _buildMonitoreoTab(theme),
                      _buildMovilesTab(theme),
                      _buildUnidadesTab(theme),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard_customize_rounded, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'DESPACHO Y MONITOREO',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Control de incidentes activos, localización de móviles y asignación de unidades.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        // Indicadores rápidos
        Row(
          children: [
            _buildStatusIndicator(
              label: 'Incidentes',
              count: _controller.incidentesActivos.length,
              color: AppColors.accentRed,
            ),
            const SizedBox(width: 16),
            _buildStatusIndicator(
              label: 'Móviles Disp.',
              count: _controller.moviles.where((m) => m.estado == 'Disponible').length,
              color: AppColors.accentGreen,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatusIndicator({required String label, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Text(
            '$count',
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          color: theme.colorScheme.primary.withOpacity(0.12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
        ),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
        tabs: const [
          Tab(text: 'MONITOREO EN VIVO', icon: Icon(Icons.map_rounded, size: 20)),
          Tab(text: 'MÓVILES DE SERVICIO', icon: Icon(Icons.emergency_rounded, size: 20)),
          Tab(text: 'UNIDADES VEHICULARES', icon: Icon(Icons.local_shipping_rounded, size: 20)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: MONITOREO (MAPA Y DESPACHO)
  // ==========================================
  
  Widget _buildMonitoreoTab(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel Izquierdo: Lista de Incidentes
        Expanded(
          flex: 2,
          child: _buildActiveIncidentsPanel(theme),
        ),
        const SizedBox(width: 16),
        // Mapa Central con Panel de Despacho Superpuesto
        Expanded(
          flex: 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _buildMapContainer(theme),
              ),
              if (_selectedIncident != null)
                Positioned(
                  top: 12,
                  bottom: 12,
                  left: 12,
                  width: 380,
                  child: PointerInterceptor(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(4, 0),
                          ),
                        ],
                      ),
                      child: _buildDispatchDetailPanel(theme),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveIncidentsPanel(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.accentRed, size: 18),
                  SizedBox(width: 8),
                  Text('Incidentes Activos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              IconButton(
                icon: _controller.isIncidentesLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentBlue,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18, color: Colors.white60),
                onPressed: _controller.isIncidentesLoading
                    ? null
                    : () => _controller.cargarIncidentesActivos(),
                tooltip: 'Actualizar incidentes',
              ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: _controller.incidentesActivos.isEmpty
                ? const Center(
                    child: Text('No hay incidentes activos', style: TextStyle(color: Colors.white30, fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: _controller.incidentesActivos.length,
                    itemBuilder: (context, index) {
                      final demanda = _controller.incidentesActivos[index];
                      final inc = demanda.incidente;
                      if (inc == null) return const SizedBox.shrink();
                      
                      // Determinar color de prioridad y etiqueta según idconf_codigo / codigoTriage
                      Color priorityColor = AppColors.accentGreen;
                      String priorityLabel = 'BAJA';
                      
                      final code = inc.idConfCodigo;
                      final triage = inc.codigoTriage?.toLowerCase();
                      final descLower = (inc.descripcion ?? '').toLowerCase();

                      if (code == 29 || triage == 'rojo' || descLower.contains('dolor tor') || descLower.contains('trauma') || descLower.contains('atrapado')) {
                        priorityColor = AppColors.accentRed;
                        priorityLabel = 'ROJA';
                      } else if (code == 30 || triage == 'amarillo' || descLower.contains('colisión') || descLower.contains('vial')) {
                        priorityColor = Colors.orangeAccent;
                        priorityLabel = 'AMARILLA';
                      } else if (code == 31 || triage == 'verde') {
                        priorityColor = AppColors.accentGreen;
                        priorityLabel = 'VERDE';
                      }

                      final isSelected = _selectedIncident?.idDemandaRecibida == demanda.idDemandaRecibida;
                      final isRojo = priorityLabel == 'ROJA';
                      
                      // Verificar si tiene móvil despachado
                      final despachados = _controller.moviles.where((m) => m.idIncidenteActivo == (demanda.incidente?.idIncidente ?? demanda.idDemandaRecibida));
                      final hasMovil = despachados.isNotEmpty;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? theme.colorScheme.primary.withOpacity(0.12) 
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : (isRojo ? AppColors.accentRed : AppColors.border.withOpacity(0.6)),
                            width: isSelected ? 1.5 : (isRojo ? 1.5 : 1),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          onTap: () {
                            _controller.cargarMoviles();
                            setState(() {
                              _selectedIncident = demanda;
                              // Si tiene coordenadas, centrar mapa
                              if (inc.latitud != null && inc.longitud != null) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(LatLng(inc.latitud!, inc.longitud!), 15),
                                );
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(AppRadii.xs),
                                        border: Border.all(color: priorityColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        priorityLabel,
                                        style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      demanda.fechaHora != null
                                          ? '${demanda.fechaHora!.hour}:${demanda.fechaHora!.minute.toString().padLeft(2, '0')}'
                                          : 'Hace poco',
                                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  inc.direccion ?? 'Dirección no especificada',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inc.descripcion ?? 'Sin descripción',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (hasMovil) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_shipping_rounded, color: AppColors.accentBlue, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Asignado: ${despachados.map((m) => m.nombre).join(', ')}',
                                        style: const TextStyle(color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

Widget _buildMapContainer(ThemeData theme) {
    final bool mapsSupported = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Stack(
          children: [
            mapsSupported 
                ? _buildRealGoogleMap()
                : SimulatedMapWidget(
                    incidentes: _controller.incidentesActivos,
                    moviles: _controller.moviles,
                    selectedIncident: _selectedIncident,
                    onSelectIncident: (inc) {
                      _controller.cargarMoviles();
                      setState(() {
                        _selectedIncident = inc;
                        _selectedMovil = null;
                      });
                    },
                  ),
            if (_selectedMovil != null) _buildSelectedMovilCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRealGoogleMap() {
    final Set<Marker> markers = {};
    
    // Marcadores de incidentes
    for (var demanda in _controller.incidentesActivos) {
      final inc = demanda.incidente;
      if (inc != null && inc.latitud != null && inc.longitud != null) {
        final isSelected = _selectedIncident?.idDemandaRecibida == demanda.idDemandaRecibida;
        
        markers.add(
          Marker(
            markerId: MarkerId('inc_${demanda.idDemandaRecibida}'),
            position: LatLng(inc.latitud!, inc.longitud!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: 'Incidente: ${inc.direccion ?? 'Sin dirección'}',
            ),
            onTap: () {
              _controller.cargarMoviles();
              setState(() {
                _selectedIncident = demanda;
              });
            },
          ),
        );
      }
    }

    // Marcadores de móviles (Ambulancias con insignia especial)
    for (var m in _controller.moviles) {
      if (m.estado != 'Inactivo') {
        Color stateColor = Colors.cyan;
        if (m.estado == 'Disponible') stateColor = AppColors.accentGreen;
        if (m.estado == 'Despachado') stateColor = AppColors.accentBlue;
        if (m.estado == 'En sitio') stateColor = Colors.cyanAccent;
        if (m.estado == 'Traslado') stateColor = AppColors.accentPurple;

        BitmapDescriptor customIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
        final cached = _movilMarkerCache['movil_cross_${stateColor.toARGB32()}'];
        if (cached != null) {
          customIcon = cached;
        } else {
          _getMovilMarkerIcon(stateColor).then((_) {
            if (mounted) setState(() {});
          });
        }

        markers.add(
          Marker(
            markerId: MarkerId('mov_${m.id}'),
            position: LatLng(m.latitud, m.longitud),
            icon: customIcon,
            onTap: () {
              setState(() {
                _selectedMovil = m;
              });
            },
          ),
        );
      }
    }

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-38.9516, -68.0591),
        zoom: 13.5,
      ),
      markers: markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      onMapCreated: (c) => _mapController = c,
    );
  }

  Widget _buildSelectedMovilCard(ThemeData theme) {
    final m = _selectedMovil!;
    Color stateColor = Colors.grey;
    if (m.estado == 'Disponible') stateColor = AppColors.accentGreen;
    if (m.estado == 'Despachado') stateColor = AppColors.accentBlue;
    if (m.estado == 'En sitio') stateColor = Colors.cyanAccent;
    if (m.estado == 'Traslado') stateColor = AppColors.accentPurple;

    return Positioned(
      top: 16,
      left: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0F172A),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: stateColor, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medical_services_rounded, size: 16, color: stateColor),
              const SizedBox(width: 8),
              Text(
                '${m.nombre} • ${m.estado}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMovil = null),
                  child: const Icon(Icons.close, size: 16, color: Colors.white60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchDetailPanel(ThemeData theme) {
    final demanda = _selectedIncident!;
    final inc = demanda.incidente!;
    final victimas = inc.victimas ?? [];
    
    // Obtener IDs de móviles ya asignados a alguna víctima en cualquier incidente activo
    final assignedMobileIds = _controller.incidentesActivos
        .expand((d) => d.incidente?.victimas ?? <Victima>[])
        .expand((v) => v.idMovilAsignado?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty) ?? <String>[])
        .toSet();

    // Obtener móviles disponibles para despachar (idmovil_estado == 1 o "Disponible", activos y no asignados a otra víctima)
    final despachables = _controller.moviles.where((m) {
      if (m.activo == 0) return false;
      final esDisponible = m.idmovilEstado == 1 || m.estado.toLowerCase() == 'disponible';
      if (!esDisponible) return false;
      
      final cleanId = m.id.replaceAll(RegExp(r'[^0-9]'), '');
      if (assignedMobileIds.contains(m.id) || (cleanId.isNotEmpty && assignedMobileIds.contains(cleanId))) {
        return false;
      }
      return true;
    }).toList();

    final idIncidenteActual = inc.idIncidente ?? demanda.idDemandaRecibida!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CONTROL DE DESPACHO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentBlue)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.white60),
                  onPressed: () {
                    setState(() => _selectedIncident = null);
                    _controller.cargarIncidentesActivos();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(inc.direccion ?? 'Sin Dirección', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
            const SizedBox(height: 8),
            Text(
              inc.descripcion ?? 'Sin descripción disponible.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text('VÍCTIMAS DEL INCIDENTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 12),
            
            if (victimas.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.white38),
                    SizedBox(width: 8),
                    Text(
                      'No hay víctimas registradas.',
                      style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            else
              ...victimas.map((v) {
                final assignedId = v.idMovilAsignado != null && v.idMovilAsignado!.isNotEmpty
                    ? v.idMovilAsignado!.trim()
                    : null;
                final isAssigned = assignedId != null && assignedId.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: isAssigned ? AppColors.accentBlue.withOpacity(0.3) : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado de la víctima
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: v.idConfGenero == 1
                                ? AppColors.accentBlue
                                : v.idConfGenero == 2
                                    ? AppColors.accentRed
                                    : Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.nombresApellidos ?? 'Nombre no registrado',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'DNI: ${v.dni ?? "No informado"} • Edad: ${v.edad != null ? "${v.edad} años" : "No informada"}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (v.observaciones != null && v.observaciones!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          v.observaciones!,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 12),
                      
                      // Gestión de móvil asignado (1 móvil por víctima)
                      if (isAssigned) ...[
                        Builder(
                          builder: (context) {
                            final cleanAssigned = assignedId.replaceAll(RegExp(r'[^0-9]'), '');
                            final mIndex = _controller.moviles.indexWhere((m) {
                              final cleanM = m.id.replaceAll(RegExp(r'[^0-9]'), '');
                              return m.id == assignedId || (cleanM.isNotEmpty && cleanM == cleanAssigned);
                            });
                            if (mIndex == -1) return const SizedBox.shrink();
                            final movilAsignado = _controller.moviles[mIndex];
                            
                            final uIndex = _controller.unidades.indexWhere((u) => u.id == movilAsignado.idUnidadAsignada);
                            final unidadAsignada = uIndex != -1 ? _controller.unidades[uIndex] : null;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                border: Border.all(color: AppColors.accentBlue.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.airport_shuttle, size: 14, color: AppColors.accentBlue),
                                          const SizedBox(width: 6),
                                          Text(
                                            movilAsignado.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getCategoriaColor(_getCategoriaEstado(movilAsignado.estado)).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(AppRadii.xs),
                                              border: Border.all(
                                                color: _getCategoriaColor(_getCategoriaEstado(movilAsignado.estado)).withOpacity(0.3),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              movilAsignado.estado.toUpperCase(),
                                              style: TextStyle(
                                                color: _getCategoriaColor(_getCategoriaEstado(movilAsignado.estado)),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.accentRed,
                                              side: BorderSide(color: AppColors.accentRed.withOpacity(0.6)),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              minimumSize: const Size(0, 26),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            icon: const Icon(Icons.cancel_outlined, size: 13),
                                            label: const Text(
                                              'CANCELAR DESPACHO',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: () {
                                              _controller.removerMovilDeVictima(
                                                idIncidenteActual,
                                                v.idVictima!,
                                                movilAsignado.id,
                                                idDespacho: v.idDespacho,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (unidadAsignada != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Vehículo: ${unidadAsignada.marca} (${unidadAsignada.patente}) • Tipo: ${unidadAsignada.tipo}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.accentRed),
                            const SizedBox(width: 6),
                            const Text(
                              'Sin móvil asignado',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (!isAssigned) ...[
                        if (despachables.isEmpty) ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'No hay móviles disponibles',
                                  style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
                                icon: const Icon(Icons.refresh_rounded, size: 13, color: AppColors.accentBlue),
                                label: const Text('Cargar móviles', style: TextStyle(color: AppColors.accentBlue, fontSize: 11)),
                                onPressed: () => _controller.cargarMoviles(),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Despachar móvil:',
                                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              InkWell(
                                onTap: () => _controller.cargarMoviles(),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 12, color: AppColors.accentBlue),
                                      SizedBox(width: 4),
                                      Text('Actualizar listado', style: TextStyle(color: AppColors.accentBlue, fontSize: 10.5)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...despachables.map((m) {
                            final uList = _controller.unidades.where((u) => u.id == m.idUnidadAsignada).toList();
                            final u = uList.isNotEmpty ? uList.first : null;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                border: Border.all(
                                  color: AppColors.accentBlue.withOpacity(0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                dense: true,
                                leading: const Icon(Icons.airport_shuttle_outlined, size: 16, color: AppColors.accentBlue),
                                title: Text(
                                  m.nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                subtitle: Tooltip(
                                  message: m.descripcion != null && m.descripcion!.isNotEmpty
                                      ? '${m.nombre}: ${m.descripcion}'
                                      : m.nombre,
                                  waitDuration: const Duration(milliseconds: 250),
                                  child: Text(
                                    '${m.descripcion != null && m.descripcion!.isNotEmpty ? "${m.descripcion} • " : ""}${u != null ? "${u.marca} (${u.patente}) • Tipo: ${u.tipo}" : "Sin vehículo asignado"}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 10.5, height: 1.2),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentBlue,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: const Size(60, 26),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadii.xs),
                                    ),
                                  ),
                                  onPressed: () {
                                    _controller.asignarMovilAVictima(
                                      idIncidenteActual,
                                      v.idVictima!,
                                      m.id,
                                    );
                                  },
                                  child: const Text(
                                    'DESPACHAR',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: MÓVILES
  // ==========================================
  
  Widget _buildMovilesTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Móviles Operativos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoAgregarEditarMovil(null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('NUEVO MÓVIL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.accentBlue.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _controller.isMovilesLoading
              ? _buildMovilesSkeletonGrid()
              : (_controller.moviles.isEmpty
                  ? const Center(child: Text('No hay móviles registrados.'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        mainAxisExtent: 235,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _controller.moviles.length,
                      itemBuilder: (context, index) {
                        final m = _controller.moviles[index];
                        
                        // Vehículo asignado
                        final u = _controller.unidades.cast<Unidad?>().firstWhere(
                          (elem) => elem?.id == m.idUnidadAsignada,
                          orElse: () => null,
                        );

                        return _MovilCardItem(
                          movil: m,
                          unidad: u,
                          onAsignarVehiculo: () => _mostrarAsignacionVehiculo(m),
                          onEditar: () => _mostrarDialogoAgregarEditarMovil(m),
                          onEliminar: () => _confirmarEliminarMovil(m),
                        );
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildMovilesSkeletonGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 235,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _MovilCardSkeleton(),
    );
  }

  void _mostrarAsignacionVehiculo(Movil m) {
    showDialog(
      context: context,
      builder: (context) {
        bool isLoadingLocal = true;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            if (isLoadingLocal) {
              _controller.cargarUnidades().then((_) {
                if (mounted) {
                  setStateDialog(() {
                    isLoadingLocal = false;
                  });
                }
              }).catchError((_) {
                if (mounted) {
                  setStateDialog(() {
                    isLoadingLocal = false;
                  });
                }
              });
            }

            final disponibles = _controller.unidades.where((u) {
              return u.estado == 'Activo' && (u.idMovilAsignado == null || u.idMovilAsignado == m.id);
            }).toList();

            return PointerInterceptor(
              child: Dialog(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                ),
                child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accentBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            color: AppColors.accentBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Asignar Vehículo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vincular unidad vehicular a ${m.nombre}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFF334155)),
                    const SizedBox(height: 16),

                    // Lista con indicador de carga durante el GET
                    if (isLoadingLocal)
                      Container(
                        height: 160,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 2.5),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Cargando vehículos disponibles desde el backend...',
                              style: TextStyle(color: Colors.white60, fontSize: 12.5),
                            ),
                          ],
                        ),
                      )
                    else if (disponibles.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.directions_car_outlined, size: 36, color: Colors.white24),
                            SizedBox(height: 10),
                            Text(
                              'No hay vehículos activos y disponibles',
                              style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: disponibles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final u = disponibles[index];
                            final isCurrentlyAssigned = u.idMovilAsignado == m.id;

                            return _UnidadOptionTile(
                              unidad: u,
                              isSelected: isCurrentlyAssigned,
                              onTap: () {
                                _controller.asignarUnidadAMovil(m.id, u.id);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFF334155)),
                    const SizedBox(height: 16),

                    // Footer Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (m.idUnidadAsignada != null)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _controller.asignarUnidadAMovil(m.id, null);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.link_off_rounded, size: 14),
                              label: const Text('DESASOCIAR ACTUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accentRed,
                                side: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  void _mostrarDialogoAgregarEditarMovil(Movil? m) {
    final nombreCtrl = TextEditingController(text: m?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: m?.descripcion ?? '');
    String selectedEstado = (m?.estado == 'Inactivo' || m?.activo == 0) ? 'Inactivo' : 'Disponible';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return PointerInterceptor(
              child: Dialog(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                ),
                child: Container(
                width: 460,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accentBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.airport_shuttle_rounded,
                              color: AppColors.accentBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m == null ? 'Nuevo Móvil' : 'Editar ${m.nombre}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m == null
                                      ? 'Registrar una nueva unidad de atención (SerSienDspMovil)'
                                      : 'Actualizar la información operativa',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFF334155)),
                      const SizedBox(height: 20),

                      // Campo 1: Identificación / Nombre (Requerido)
                      TextFormField(
                        controller: nombreCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el nombre/identificación del móvil';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Nombre / Identificación *',
                          hintText: 'Ej. Móvil 1',
                          hintStyle: const TextStyle(color: Colors.white30),
                          labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.accentBlue, size: 18),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Campo 2: Descripción (Opcional - SerSienDspMovil: descripcion)
                      TextFormField(
                        controller: descripcionCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Ej. Unidad de Alta Complejidad - Base Central',
                          hintStyle: const TextStyle(color: Colors.white30),
                          labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                          prefixIcon: const Icon(Icons.description_outlined, color: AppColors.accentBlue, size: 18),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),



                      // Campo 4: Estado Operativo Dropdown (Mapea a 'activo': 1 / 0)
                      DropdownButtonFormField<String>(
                        value: selectedEstado,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Estado Operativo (Activo)',
                          labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                          prefixIcon: const Icon(Icons.tune_rounded, color: AppColors.accentBlue, size: 18),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                          ),
                        ),
                        items: [
                          _buildDropdownItem('Disponible', 'Activo / Disponible', AppColors.accentGreen),
                          _buildDropdownItem('Inactivo', 'Inactivo', AppColors.accentRed),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              selectedEstado = val;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFF334155)),
                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCELAR', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (formKey.currentState != null && !formKey.currentState!.validate()) return;
                                if (nombreCtrl.text.trim().isEmpty) return;

                                final isActivo = selectedEstado == 'Inactivo' ? 0 : 1;
                                final descripcionVal = descripcionCtrl.text.trim().isEmpty ? null : descripcionCtrl.text.trim();

                                if (m == null) {
                                  final nuevo = Movil(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    nombre: nombreCtrl.text.trim(),
                                    descripcion: descripcionVal,
                                    activo: isActivo,
                                    estado: selectedEstado,
                                    latitud: -38.9515,
                                    longitud: -68.0610,
                                  );
                                  _controller.agregarMovil(nuevo);
                                } else {
                                  final editado = m.copyWith(
                                    nombre: nombreCtrl.text.trim(),
                                    descripcion: descripcionVal,
                                    activo: isActivo,
                                    estado: selectedEstado,
                                  );
                                  if (selectedEstado == 'Disponible' || selectedEstado == 'Inactivo') {
                                    final editadoConIncidenteLimpio = editado.copyWith(
                                      clearIncidente: true,
                                      latitud: m.id == 'm1' ? -38.9515 : (m.id == 'm2' ? -38.9580 : -38.9480),
                                      longitud: m.id == 'm1' ? -68.0610 : (m.id == 'm2' ? -68.0520 : -68.0750),
                                    );
                                    _controller.actualizarMovil(editadoConIncidenteLimpio);
                                  } else {
                                    _controller.actualizarMovil(editado);
                                  }
                                }
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: Text(m == null ? 'CREAR MÓVIL' : 'GUARDAR CAMBIOS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  DropdownMenuItem<String> _buildDropdownItem(String value, String label, Color color) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmarEliminarMovil(Movil m) {
    final bool isActivo = m.activo == 1 && m.estado != 'Inactivo';
    final String titulo = isActivo ? '¿Dar de Baja Móvil?' : '¿Eliminar Móvil Definitivamente?';
    final String subtitulo = isActivo
        ? 'El móvil pasará a estado Inactivo'
        : 'Esta acción eliminará el registro permanentemente';
    final String descripcion = isActivo
        ? '¿Estás seguro de que deseas dar de baja a ${m.nombre}? La unidad pasará a estar inactiva y no podrá ser despachada a emergencias.'
        : '¿Estás seguro de que deseas eliminar permanentemente a ${m.nombre}? No podrás revertir esta acción.';
    final String botonTexto = isActivo ? 'DAR DE BAJA' : 'ELIMINAR DEFINITIVAMENTE';
    final IconData icon = isActivo ? Icons.remove_circle_outline_rounded : Icons.delete_forever_rounded;
    final Color badgeColor = isActivo ? Colors.orangeAccent : AppColors.accentRed;

    showDialog(
      context: context,
      builder: (context) {
        return PointerInterceptor(
          child: Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: badgeColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con Icono de Alerta Adaptativo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: badgeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitulo,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.54),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 20),

                // Card de Confirmación con detalles del móvil
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.airport_shuttle_rounded, color: AppColors.accentBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (m.descripcion != null && m.descripcion!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                m.descripcion!,
                                style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActivo ? AppColors.accentGreen.withValues(alpha: 0.15) : AppColors.accentRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActivo ? AppColors.accentGreen.withValues(alpha: 0.4) : AppColors.accentRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          isActivo ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            color: isActivo ? AppColors.accentGreen : AppColors.accentRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  descripcion,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _controller.eliminarMovil(m.id);
                          Navigator.pop(context);
                        },
                        icon: Icon(isActivo ? Icons.power_settings_new_rounded : Icons.delete_forever_rounded, size: 16),
                        label: Text(botonTexto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: badgeColor,
                          foregroundColor: isActivo ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          shadowColor: badgeColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  // ==========================================
  // TAB 3: UNIDADES
  // ==========================================
  
  Widget _buildUnidadesTab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Unidades Vehiculares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _controller.isUnidadesLoading
              ? _buildUnidadesSkeletonGrid()
              : (_controller.unidades.isEmpty
                  ? const Center(child: Text('No hay unidades vehiculares registradas.'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        mainAxisExtent: 200,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _controller.unidades.length,
                      itemBuilder: (context, index) {
                        final u = _controller.unidades[index];
                        
                        // Móvil asignado
                        final m = _controller.moviles.cast<Movil?>().firstWhere(
                          (elem) => elem?.id == u.idMovilAsignado,
                          orElse: () => null,
                        );

                        return _UnidadCardItem(
                          unidad: u,
                          movil: m,
                        );
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildUnidadesSkeletonGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _UnidadCardSkeleton(),
    );
  }


}

// ==========================================
// SIMULATED MAP FOR DESKTOP PLATFORMS
// ==========================================

class SimulatedMapWidget extends StatelessWidget {
  final List<DemandaRecibida> incidentes;
  final List<Movil> moviles;
  final DemandaRecibida? selectedIncident;
  final ValueChanged<DemandaRecibida> onSelectIncident;

  const SimulatedMapWidget({
    super.key,
    required this.incidentes,
    required this.moviles,
    required this.selectedIncident,
    required this.onSelectIncident,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final W = constraints.maxWidth;
        final H = constraints.maxHeight;

        // Bounding box de Neuquén
        const double minLat = -38.97;
        const double maxLat = -38.93;
        const double minLng = -68.09;
        const double maxLng = -68.04;

        Offset convertCoords(double lat, double lng) {
          final x = (lng - minLng) / (maxLng - minLng) * W;
          final y = (1.0 - (lat - minLat) / (maxLat - minLat)) * H;
          return Offset(x, y);
        }

        final Set<Widget> children = {};

        // 1. Dibuja las líneas de ruta para móviles asignados a incidentes
        for (var m in moviles) {
          if (m.estado != 'Inactivo' && m.idIncidenteActivo != null) {
            final inc = incidentes.cast<DemandaRecibida?>().firstWhere(
              (elem) => (elem?.incidente?.idIncidente == m.idIncidenteActivo || elem?.idDemandaRecibida == m.idIncidenteActivo),
              orElse: () => null,
            );
            if (inc != null && inc.incidente?.latitud != null) {
              final pM = convertCoords(m.latitud, m.longitud);
              final pI = convertCoords(inc.incidente!.latitud!, inc.incidente!.longitud!);
              
              children.add(
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: LineRoutePainter(start: pM, end: pI),
                    ),
                  ),
                ),
              );
            }
          }
        }

        // 2. Coloca marcadores de incidentes
        for (var dema in incidentes) {
          final inc = dema.incidente;
          if (inc != null && inc.latitud != null && inc.longitud != null) {
            final pos = convertCoords(inc.latitud!, inc.longitud!);
            final isSelected = selectedIncident?.idDemandaRecibida == dema.idDemandaRecibida;
            
            Color iconColor = AppColors.accentGreen;
            final descLower = (inc.descripcion ?? '').toLowerCase();
            if (descLower.contains('dolor tor') || descLower.contains('trauma') || descLower.contains('atrapado')) {
              iconColor = AppColors.accentRed;
            } else if (descLower.contains('colisión') || descLower.contains('vial')) {
              iconColor = Colors.orangeAccent;
            }

            children.add(
              Positioned(
                left: pos.dx - 24,
                top: pos.dy - 24,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onSelectIncident(dema),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isSelected)
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: iconColor.withOpacity(0.25),
                                ),
                              ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : AppColors.surface,
                                border: Border.all(color: iconColor, width: isSelected ? 3.5 : 2),
                              ),
                              child: Icon(
                                Icons.emergency_rounded, 
                                size: 13, 
                                color: isSelected ? iconColor : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? iconColor : Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: iconColor, width: 0.5),
                          ),
                          child: Text(
                            inc.direccion ?? 'Incidente',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }

        // 3. Coloca marcadores de móviles (Insignia compacta médica)
        for (var m in moviles) {
          if (m.estado != 'Inactivo') {
            final pos = convertCoords(m.latitud, m.longitud);
            Color stateColor = Colors.grey;
            if (m.estado == 'Disponible') stateColor = AppColors.accentGreen;
            if (m.estado == 'Despachado') stateColor = AppColors.accentBlue;
            if (m.estado == 'En sitio') stateColor = Colors.cyanAccent;
            if (m.estado == 'Traslado') stateColor = AppColors.accentPurple;

            children.add(
              Positioned(
                left: pos.dx - 15,
                top: pos.dy - 15,
                child: Tooltip(
                  message: '${m.nombre}\nEstado: ${m.estado}',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        shape: BoxShape.circle,
                        border: Border.all(color: stateColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: stateColor.withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Icon(Icons.medical_services_rounded, size: 14, color: stateColor),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Stack(
          children: [
            // Fondo de cuadrícula
            Positioned.fill(
              child: CustomPaint(
                painter: MapGridPainter(),
              ),
            ),
            
            // Leyenda e indicación en mapa simulado
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.desktop_mac_outlined, size: 14, color: AppColors.accentBlue),
                        SizedBox(width: 6),
                        Text('Simulador de Mapa (Neuquén)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.emergency_rounded, size: 10, color: AppColors.accentRed),
                        SizedBox(width: 4),
                        Text('Eventos Activos', style: TextStyle(color: Colors.white54, fontSize: 9)),
                        SizedBox(width: 12),
                        Icon(Icons.local_shipping, size: 10, color: AppColors.accentBlue),
                        SizedBox(width: 4),
                        Text('Móviles', style: TextStyle(color: Colors.white54, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            ...children,
          ],
        );
      },
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
      
    final paintStreet = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 3;

    // Cuadrícula básica
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintLine);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintLine);
    }

    // Calles principales de Neuquén simuladas
    // Ruta 22 (Horizontal cerca del bottom)
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), paintStreet);
    // Av. Argentina / Olascoaga (Vertical en el medio)
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), paintStreet);
    // Dr. Ramon (Horizontal arriba)
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), paintStreet);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineRoutePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  LineRoutePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Dibujar línea punteada
    double dashWidth = 5, dashSpace = 4, startY = start.dy, startX = start.dx;
    double endY = end.dy, endX = end.dx;
    
    // Simplificado a una línea directa punteada
    double dx = endX - startX;
    double dy = endY - startY;
    double len = Offset(dx, dy).distance;
    
    if (len > 0) {
      double udx = dx / len;
      double udy = dy / len;
      
      double currentDist = 0.0;
      while (currentDist < len) {
        double nextDist = currentDist + dashWidth;
        if (nextDist > len) nextDist = len;
        canvas.drawLine(
          Offset(startX + udx * currentDist, startY + udy * currentDist),
          Offset(startX + udx * nextDist, startY + udy * nextDist),
          paint,
        );
        currentDist += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineRoutePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}

// ==========================================
// COMPONENTE TARJETA DE MÓVIL OPERATIVO
// ==========================================
class _MovilCardItem extends StatefulWidget {
  final Movil movil;
  final Unidad? unidad;
  final VoidCallback onAsignarVehiculo;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _MovilCardItem({
    required this.movil,
    required this.unidad,
    required this.onAsignarVehiculo,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  State<_MovilCardItem> createState() => _MovilCardItemState();
}

class _MovilCardItemState extends State<_MovilCardItem> {
  bool _isHovered = false;

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Disponible':
        return AppColors.accentGreen;
      case 'Despachado':
        return AppColors.accentBlue;
      case 'En sitio':
        return Colors.cyanAccent;
      case 'Traslado':
        return AppColors.accentPurple;
      case 'Inactivo':
      case 'Mantenimiento':
        return AppColors.accentRed;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.movil;
    final u = widget.unidad;
    final statusColor = _getStatusColor(m.estado);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? statusColor.withValues(alpha: 0.5) : AppColors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? statusColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: _isHovered ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Línea superior indicadora de estado con resplandor
              Container(
                height: 3.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Ícono + Nombre + Badge de Estado con Pulso
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.airport_shuttle_rounded,
                            size: 18,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (m.descripcion != null && m.descripcion!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Tooltip(
                                  message: m.descripcion!,
                                  waitDuration: const Duration(milliseconds: 250),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5), width: 1.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    m.descripcion!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Badge de estado con indicador luminoso
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor,
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                m.estado.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bloque de Vehículo Asignado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            size: 15,
                            color: u != null ? statusColor : AppColors.accentRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: u != null
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${u.marca} ${u.modelo}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          u.patente,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Sin vehículo asignado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accentRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),


                  ],
                ),
              ),

              const Spacer(),

              // Línea divisoria
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

              // Footer de Acciones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onAsignarVehiculo,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                      label: Text(
                        u != null ? 'CAMBIAR VEHÍCULO' : 'ASIGNAR VEHÍCULO',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: statusColor,
                        side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white60),
                          onPressed: widget.onEditar,
                          tooltip: 'Editar móvil',
                          visualDensity: VisualDensity.compact,
                          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRed),
                          onPressed: widget.onEliminar,
                          tooltip: 'Eliminar móvil',
                          visualDensity: VisualDensity.compact,
                          hoverColor: AppColors.accentRed.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENTE TARJETA DE UNIDAD VEHICULAR
// ==========================================
class _UnidadCardItem extends StatefulWidget {
  final Unidad unidad;
  final Movil? movil;

  const _UnidadCardItem({
    required this.unidad,
    required this.movil,
  });

  @override
  State<_UnidadCardItem> createState() => _UnidadCardItemState();
}

class _UnidadCardItemState extends State<_UnidadCardItem> {
  bool _isHovered = false;

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Activo':
        return AppColors.accentGreen;
      case 'Mantenimiento':
        return Colors.orangeAccent;
      case 'Fuera de Servicio':
      case 'Inactivo':
        return AppColors.accentRed;
      default:
        return Colors.grey;
    }
  }

  Widget _buildArgentinaPlate(String patente) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black54, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 4,
            color: const Color(0xFF0038A8),
          ),
          const SizedBox(height: 1),
          Text(
            patente.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unidad;
    final m = widget.movil;
    final statusColor = _getStatusColor(u.estado);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? statusColor.withValues(alpha: 0.5) : AppColors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? statusColor.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: _isHovered ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Línea superior indicadora de estado
              Container(
                height: 3.5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Ícono + Marca/Modelo/Tipo + Patente Argentina
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.directions_car_filled_rounded,
                            size: 18,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${u.marca} ${u.modelo}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                u.tipo.isNotEmpty ? u.tipo : 'Unidad Vehicular',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildArgentinaPlate(u.patente),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bloque Estado de Servicio con LED
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Estado: ',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            u.estado.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bloque Asignación Móvil
                    Row(
                      children: [
                        Icon(
                          Icons.contact_emergency_rounded,
                          size: 15,
                          color: m != null ? AppColors.accentBlue : Colors.white24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m != null ? 'Asignado a: ${m.nombre}' : 'Sin móvil asignado (Disponible)',
                            style: TextStyle(
                              fontSize: 12,
                              color: m != null ? AppColors.accentBlue : Colors.white30,
                              fontWeight: m != null ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ITEM DE OPCIÓN DE VEHÍCULO EN MODAL
// ==========================================
class _UnidadOptionTile extends StatefulWidget {
  final Unidad unidad;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnidadOptionTile({
    required this.unidad,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_UnidadOptionTile> createState() => _UnidadOptionTileState();
}

class _UnidadOptionTileState extends State<_UnidadOptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.unidad;
    final isSelected = widget.isSelected;

    final borderColor = isSelected
        ? AppColors.accentGreen
        : (_isHovered ? AppColors.accentBlue.withValues(alpha: 0.6) : const Color(0xFF334155));

    final bgColor = isSelected
        ? AppColors.accentGreen.withValues(alpha: 0.1)
        : (_isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.2));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentGreen.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.airport_shuttle_rounded,
                  size: 18,
                  color: isSelected ? AppColors.accentGreen : Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${u.marca} ${u.modelo}',
                      style: TextStyle(
                        color: isSelected ? AppColors.accentGreen : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            u.patente,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (u.tipo.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•  ${u.tipo}',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.black),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: _isHovered ? Colors.white70 : Colors.white24,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENTE SKELETON LOADER PARA TARJETA DE MÓVIL
// ==========================================
class _MovilCardSkeleton extends StatefulWidget {
  const _MovilCardSkeleton();

  @override
  State<_MovilCardSkeleton> createState() => _MovilCardSkeletonState();
}

class _MovilCardSkeletonState extends State<_MovilCardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.18).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        final baseColor = Colors.white.withValues(alpha: opacity);

        return Container(
          height: 235,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Línea superior indicadora de estado
                Container(
                  height: 3.5,
                  width: double.infinity,
                  color: AppColors.accentBlue.withValues(alpha: opacity * 2.5),
                ),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Name + Badge Skeleton
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 120,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: baseColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 180,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: baseColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 75,
                            height: 22,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Info Box Skeleton
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 220,
                              height: 12,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 160,
                              height: 12,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 120,
                        height: 28,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// SKELETON LOADER FOR UNIDADES VEHICULARES
// ==========================================
class _UnidadCardSkeleton extends StatefulWidget {
  const _UnidadCardSkeleton();

  @override
  State<_UnidadCardSkeleton> createState() => _UnidadCardSkeletonState();
}

class _UnidadCardSkeletonState extends State<_UnidadCardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 140, height: 16, color: Colors.white12),
                        const SizedBox(height: 6),
                        Container(width: 90, height: 12, color: Colors.white10),
                      ],
                    ),
                  ),
                  Container(width: 70, height: 24, color: Colors.white12),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 32, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 16),
              Container(width: 160, height: 14, color: Colors.white10),
            ],
          ),
        );
      },
    );
  }
}
