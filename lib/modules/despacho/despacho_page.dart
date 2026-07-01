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
  
  // Estado local de selección
  DemandaRecibida? _selectedIncident;
  
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
    _controller.inicializar();
  }

  @override
  void dispose() {
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
                icon: const Icon(Icons.refresh, size: 18, color: Colors.white60),
                onPressed: () => _controller.cargarIncidentesActivos(),
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
                      
                      // Determinar color de prioridad (simulado a partir de descripción o id)
                      Color priorityColor = AppColors.accentGreen;
                      String priorityLabel = 'BAJA';
                      
                      final descLower = (inc.descripcion ?? '').toLowerCase();
                      if (descLower.contains('dolor tor') || descLower.contains('trauma') || descLower.contains('atrapado')) {
                        priorityColor = AppColors.accentRed;
                        priorityLabel = 'ROJA';
                      } else if (descLower.contains('colisión') || descLower.contains('vial')) {
                        priorityColor = Colors.orangeAccent;
                        priorityLabel = 'AMARILLA';
                      }

                      final isSelected = _selectedIncident?.idDemandaRecibida == demanda.idDemandaRecibida;
                      
                      // Verificar si tiene móvil despachado
                      final despachados = _controller.moviles.where((m) => m.idIncidenteActivo == (demanda.incidente?.idIncidente ?? demanda.idDemandaRecibida));
                      final hasMovil = despachados.isNotEmpty;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? theme.colorScheme.primary.withOpacity(0.08) 
                              : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: isSelected 
                                ? theme.colorScheme.primary.withOpacity(0.6) 
                                : AppColors.border.withOpacity(0.6),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          onTap: () {
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
        child: mapsSupported 
            ? _buildRealGoogleMap()
            : SimulatedMapWidget(
                incidentes: _controller.incidentesActivos,
                moviles: _controller.moviles,
                selectedIncident: _selectedIncident,
                onSelectIncident: (inc) {
                  setState(() {
                    _selectedIncident = inc;
                  });
                },
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
              title: inc.direccion ?? 'Incidente',
              snippet: inc.descripcion ?? '',
            ),
            onTap: () {
              setState(() {
                _selectedIncident = demanda;
              });
            },
          ),
        );
      }
    }

    // Marcadores de móviles
    for (var m in _controller.moviles) {
      if (m.estado != 'Inactivo') {
        markers.add(
          Marker(
            markerId: MarkerId('mov_${m.id}'),
            position: LatLng(m.latitud, m.longitud),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: m.nombre,
              snippet: 'Estado: ${m.estado}',
            ),
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

  Widget _buildDispatchDetailPanel(ThemeData theme) {
    final demanda = _selectedIncident!;
    final inc = demanda.incidente!;
    final victimas = inc.victimas ?? [];
    
    // Obtener IDs de móviles ya asignados a alguna víctima en cualquier incidente activo
    final assignedMobileIds = _controller.incidentesActivos
        .expand((d) => d.incidente?.victimas ?? <Victima>[])
        .map((v) => v.idMovilAsignado)
        .whereType<String>()
        .toSet();

    // Obtener móviles disponibles para despachar (tienen vehículo asignado, no están inactivos y no están ocupados por otra víctima)
    final despachables = _controller.moviles.where((m) {
      return m.idUnidadAsignada != null && m.estado != 'Inactivo' && !assignedMobileIds.contains(m.id);
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
                  onPressed: () => setState(() => _selectedIncident = null),
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
                final isAssigned = v.idMovilAsignado != null;
                
                Movil? movilAsignado;
                Unidad? unidadAsignada;
                if (isAssigned) {
                  final mIndex = _controller.moviles.indexWhere((m) => m.id == v.idMovilAsignado);
                  if (mIndex != -1) {
                    movilAsignado = _controller.moviles[mIndex];
                    final uIndex = _controller.unidades.indexWhere((u) => u.id == movilAsignado!.idUnidadAsignada);
                    if (uIndex != -1) {
                      unidadAsignada = _controller.unidades[uIndex];
                    }
                  }
                }

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
                      
                      if (v.descripcion != null && v.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          v.descripcion!,
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
                      
                      // Gestión del móvil asignado
                      if (movilAsignado != null) ...[
                        Container(
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
                                ],
                              ),
                              if (unidadAsignada != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Vehículo: ${unidadAsignada.marca} (${unidadAsignada.patente}) • Tipo: ${unidadAsignada.tipo}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                              if (movilAsignado.personal != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Tripulación: ${movilAsignado.personal}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Estado:',
                                    style: TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: movilAsignado.estado,
                                      dropdownColor: AppColors.surface,
                                      icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                      isDense: true,
                                      onChanged: (val) {
                                        if (val != null) {
                                          if (val == 'Finalizado') {
                                            _controller.asignarMovilAVictima(
                                              idIncidenteActual,
                                              v.idVictima!,
                                              null,
                                            );
                                          } else {
                                            _controller.actualizarEstadoMovil(movilAsignado!.id, val);
                                          }
                                        }
                                      },
                                      items: const [
                                        DropdownMenuItem(value: 'Despachado', child: Text('Despachado')),
                                        DropdownMenuItem(value: 'En sitio', child: Text('En sitio')),
                                        DropdownMenuItem(value: 'Traslado', child: Text('Traslado')),
                                        DropdownMenuItem(value: 'Finalizado', child: Text('Finalizar (Liberar)')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                        const SizedBox(height: 10),
                        if (despachables.isEmpty)
                          const Text(
                            'No hay móviles disponibles',
                            style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
                          )
                        else ...[
                          const Text(
                            'Despachar rápido:',
                            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
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
                                subtitle: Text(
                                  '${u != null ? "${u.marca} (${u.patente}) • Tipo: ${u.tipo}" : "Sin vehículo"}\nTripulación: ${m.personal ?? "No informada"}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10.5, height: 1.2),
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
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoAgregarEditarMovil(null),
              icon: const Icon(Icons.add),
              label: const Text('AGREGAR MÓVIL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _controller.moviles.isEmpty
              ? const Center(child: Text('No hay móviles registrados.'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 220,
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
                    
                    Color statusColor = Colors.grey;
                    if (m.estado == 'Disponible') statusColor = AppColors.accentGreen;
                    if (m.estado == 'Despachado') statusColor = AppColors.accentBlue;
                    if (m.estado == 'En sitio') statusColor = Colors.cyanAccent;
                    if (m.estado == 'Traslado') statusColor = AppColors.accentPurple;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getCategoriaColor(_getCategoriaEstado(m.estado)).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(AppRadii.xs),
                                      border: Border.all(
                                        color: _getCategoriaColor(_getCategoriaEstado(m.estado)).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _getCategoriaEstado(m.estado).toUpperCase(),
                                      style: TextStyle(
                                        color: _getCategoriaColor(_getCategoriaEstado(m.estado)),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (m.estado != _getCategoriaEstado(m.estado)) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${m.estado})',
                                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Vehículo
                          Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 16, color: Colors.white38),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  u != null ? '${u.marca} ${u.modelo} (${u.patente})' : 'Sin vehículo asignado',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: u != null ? Colors.white70 : AppColors.accentRed,
                                    fontWeight: u != null ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Tripulación
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.people_outline, size: 16, color: Colors.white38),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  m.personal != null && m.personal!.isNotEmpty 
                                      ? m.personal! 
                                      : 'Sin tripulación cargada',
                                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Divider(),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _mostrarAsignacionVehiculo(m),
                                child: const Text('ASIGNAR VEHÍCULO', style: TextStyle(fontSize: 11)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white54),
                                onPressed: () => _mostrarDialogoAgregarEditarMovil(m),
                                tooltip: 'Editar móvil',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.accentRed),
                                onPressed: () => _confirmarEliminarMovil(m),
                                tooltip: 'Eliminar móvil',
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _mostrarAsignacionVehiculo(Movil m) {
    final disponibles = _controller.unidades.where((u) => u.estado == 'Activo' && (u.idMovilAsignado == null || u.idMovilAsignado == m.id)).toList();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Asignar Vehículo a ${m.nombre}', style: const TextStyle(color: Colors.white)),
          content: disponibles.isEmpty
              ? const Text('No hay vehículos activos y disponibles.', style: TextStyle(color: Colors.white54))
              : SizedBox(
                  width: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: disponibles.length,
                    itemBuilder: (context, index) {
                      final u = disponibles[index];
                      final isCurrentlyAsigned = u.idMovilAsignado == m.id;
                      
                      return ListTile(
                        title: Text('${u.marca} ${u.modelo}', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Patente: ${u.patente} | Tipo: ${u.tipo}', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                        trailing: isCurrentlyAsigned 
                            ? const Icon(Icons.check_circle, color: AppColors.accentGreen)
                            : null,
                        onTap: () {
                          _controller.asignarUnidadAMovil(m.id, u.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
          actions: [
            if (m.idUnidadAsignada != null)
              TextButton(
                onPressed: () {
                  _controller.asignarUnidadAMovil(m.id, null);
                  Navigator.pop(context);
                },
                child: const Text('DESASOCIAR ACTUAL', style: TextStyle(color: AppColors.accentRed)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoAgregarEditarMovil(Movil? m) {
    final nombreCtrl = TextEditingController(text: m?.nombre ?? '');
    final personalCtrl = TextEditingController(text: m?.personal ?? '');
    String selectedEstado = m?.estado ?? 'Disponible';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(m == null ? 'Nuevo Móvil' : 'Editar ${m.nombre}', style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Identificación (ej. Móvil 1)',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: personalCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tripulación (separados por coma)',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedEstado,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Estado Operativo',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Disponible', child: Text('Activo (Disponible)')),
                      DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
                      DropdownMenuItem(value: 'Despachado', child: Text('En tránsito (Despachado)')),
                      DropdownMenuItem(value: 'En sitio', child: Text('Activo (En sitio)')),
                      DropdownMenuItem(value: 'Traslado', child: Text('En tránsito (Traslado)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          selectedEstado = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    
                    if (m == null) {
                      final nuevo = Movil(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nombre: nombreCtrl.text.trim(),
                        estado: selectedEstado,
                        latitud: -38.9515,
                        longitud: -68.0610,
                        personal: personalCtrl.text.trim(),
                      );
                      _controller.agregarMovil(nuevo);
                    } else {
                      final editado = m.copyWith(
                        nombre: nombreCtrl.text.trim(),
                        personal: personalCtrl.text.trim(),
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
                  child: const Text('GUARDAR'),
                )
              ],
            );
          }
        );
      },
    );
  }

  void _confirmarEliminarMovil(Movil m) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Eliminar Móvil?', style: TextStyle(color: Colors.white)),
        content: Text('¿Estás seguro de que deseas eliminar a ${m.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed, foregroundColor: Colors.white),
            onPressed: () {
              _controller.eliminarMovil(m.id);
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR'),
          )
        ],
      ),
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
          children: [
            const Text('Unidades Vehiculares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoAgregarEditarUnidad(null),
              icon: const Icon(Icons.add),
              label: const Text('AGREGAR UNIDAD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _controller.unidades.isEmpty
              ? const Center(child: Text('No hay unidades vehiculares registradas.'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 220,
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
                    
                    Color statusColor = Colors.grey;
                    if (u.estado == 'Activo') statusColor = AppColors.accentGreen;
                    if (u.estado == 'Mantenimiento') statusColor = Colors.orangeAccent;
                    if (u.estado == 'Fuera de Servicio') statusColor = AppColors.accentRed;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${u.marca} ${u.modelo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(u.tipo, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                                ],
                              ),
                              // Patente Argentina Estilo Patente
                              _buildArgentinaPlate(u.patente),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Estado de Servicio
                          Row(
                            children: [
                              const Icon(Icons.settings_suggest_outlined, size: 16, color: Colors.white38),
                              const SizedBox(width: 8),
                              Text('Estado: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(u.estado, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Asignación Móvil
                          Row(
                            children: [
                              const Icon(Icons.contact_emergency_outlined, size: 16, color: Colors.white38),
                              const SizedBox(width: 8),
                              Text(
                                m != null ? 'Asignado a: ${m.nombre}' : 'Sin móvil asignado (Disponible)',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: m != null ? AppColors.accentBlue : Colors.white38,
                                  fontWeight: m != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Divider(),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white54),
                                onPressed: () => _mostrarDialogoAgregarEditarUnidad(u),
                                tooltip: 'Editar unidad',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.accentRed),
                                onPressed: () => _confirmarEliminarUnidad(u),
                                tooltip: 'Eliminar unidad',
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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
          // Barra azul superior
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

  void _mostrarDialogoAgregarEditarUnidad(Unidad? u) {
    final patenteCtrl = TextEditingController(text: u?.patente ?? '');
    final marcaCtrl = TextEditingController(text: u?.marca ?? '');
    final modeloCtrl = TextEditingController(text: u?.modelo ?? '');
    
    String tipoSeleccionado = u?.tipo ?? 'Alta Complejidad';
    String estadoSeleccionado = u?.estado ?? 'Activo';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(u == null ? 'Nueva Unidad Vehicular' : 'Editar Unidad', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: patenteCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Patente (ej. AA 123 BC)',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: marcaCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Marca (ej. Mercedes-Benz)',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modeloCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Modelo (ej. Sprinter 415)',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Complejidad',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Alta Complejidad', child: Text('Alta Complejidad')),
                        DropdownMenuItem(value: 'Alta Complejidad Zonal', child: Text('Alta Complejidad Zonal')),
                        DropdownMenuItem(value: 'Baja Complejidad', child: Text('Baja Complejidad')),
                        DropdownMenuItem(value: '4x4 de Rescate', child: Text('4x4 de Rescate')),
                        DropdownMenuItem(value: 'Móvil de Apoyo/Logístico', child: Text('Móvil de Apoyo/Logístico')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => tipoSeleccionado = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: estadoSeleccionado,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Estado de Servicio',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                        DropdownMenuItem(value: 'Mantenimiento', child: Text('Mantenimiento')),
                        DropdownMenuItem(value: 'Fuera de Servicio', child: Text('Fuera de Servicio')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => estadoSeleccionado = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (patenteCtrl.text.trim().isEmpty || marcaCtrl.text.trim().isEmpty || modeloCtrl.text.trim().isEmpty) return;
                    
                    if (u == null) {
                      final nueva = Unidad(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        patente: patenteCtrl.text.trim().toUpperCase(),
                        marca: marcaCtrl.text.trim(),
                        modelo: modeloCtrl.text.trim(),
                        tipo: tipoSeleccionado,
                        estado: estadoSeleccionado,
                      );
                      _controller.agregarUnidad(nueva);
                    } else {
                      final editada = u.copyWith(
                        patente: patenteCtrl.text.trim().toUpperCase(),
                        marca: marcaCtrl.text.trim(),
                        modelo: modeloCtrl.text.trim(),
                        tipo: tipoSeleccionado,
                        estado: estadoSeleccionado,
                      );
                      _controller.actualizarUnidad(editada);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('GUARDAR'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarEliminarUnidad(Unidad u) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Eliminar Unidad?', style: TextStyle(color: Colors.white)),
        content: Text('¿Estás seguro de que deseas eliminar la unidad ${u.marca} patente ${u.patente}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed, foregroundColor: Colors.white),
            onPressed: () {
              _controller.eliminarUnidad(u.id);
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR'),
          )
        ],
      ),
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
                left: pos.dx - 18,
                top: pos.dy - 18,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onSelectIncident(dema),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo de pulsación animada simulada (glow)
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
                  ),
                ),
              ),
            );
          }
        }

        // 3. Coloca marcadores de móviles
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
                left: pos.dx - 14,
                top: pos.dy - 14,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                    border: Border.all(color: stateColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: stateColor.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Icon(Icons.local_shipping, size: 14, color: stateColor),
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
