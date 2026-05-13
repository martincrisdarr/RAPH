import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/models/localidad.dart';
import '../../../shared/services/localidad_service.dart';
import '../../../shared/components/autocomplete_select.dart';
import '../controllers/ingreso_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/services/geocoding_service.dart';
import '../../../shared/services/demanda_recibida_service.dart';

class UbicacionSection extends StatefulWidget {
  const UbicacionSection({super.key});

  @override
  State<UbicacionSection> createState() => _UbicacionSectionState();
}

class _UbicacionSectionState extends State<UbicacionSection> {
  bool _isLinkMode = false;
  final _ingresoController = IngresoController();
  late final TextEditingController _domicilioController;
  GoogleMapController? _mapController;
  bool _isLoadingMap = false;
  Localidad? _localidadSeleccionada = _neuquenDefault;

  static final Localidad _neuquenDefault = Localidad(
    id: 580056,
    descripcion: "Neuquén",
    nombreCompleto: "Municipio Neuquén",
    categoria: "Municipio",
    provinciaId: "58",
    provinciaNombre: "Neuquén",
  );

  /// Parsea coordenadas del parámetro ?q=lat,lng de un link de Google Maps.
  /// Soporta formatos como:
  ///   https://www.google.com/maps?q=-38.95,-68.06&z=17&hl=es
  ///   https://maps.google.com/?q=-38.95,-68.06
  LatLng? _parseCoordsFromUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      final q = uri.queryParameters['q'];
      if (q != null && q.contains(',')) {
        final parts = q.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) return LatLng(lat, lng);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _buscarDireccionEnMapa() async {
    final texto = _domicilioController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _isLoadingMap = true);

    LatLng? coords;

    if (_isLinkMode) {
      // Modo link: parsear coordenadas del URL de WhatsApp/Google Maps
      coords = _parseCoordsFromUrl(texto);
      if (coords == null) {
        setState(() => _isLoadingMap = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo leer el link. Verificá que sea un link de Google Maps válido.')),
          );
        }
        return;
      }
    } else {
      // Modo normal: geocoding por texto de dirección
      coords = await GeocodingService.getCoordinatesFromAddress(
        texto,
        localidad: _localidadSeleccionada?.descripcion,
      );
    }

    if (coords != null) {
      // Mover la cámara del mapa
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(coords, 16));
      _ingresoController.updateIncidente(
        latitud: coords.latitude,
        longitud: coords.longitude,
      );

      setState(() => _isLoadingMap = false);

      if (_isLinkMode) {
        final address = await GeocodingService.getAddressFromCoordinates(
          coords.latitude,
          coords.longitude,
        );
        if (address != null) {
          _domicilioController.text = address;
          _ingresoController.updateIncidente(direccion: address);
          setState(() => _isLinkMode = false);
        }
      } else {
        _ingresoController.updateIncidente(direccion: texto);
      }
      // Sincronizar con el backend con los datos finales del mapa
      await _ingresoController.syncIncidenteDesdeGoogleMaps();
    } else {
      setState(() => _isLoadingMap = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _localidadSeleccionada != null
                  ? 'No se encontró la dirección en ${_localidadSeleccionada!.descripcion}'
                  : 'No se encontró la dirección',
            ),
          ),
        );
      }
    }
  }

  Future<void> _buscarDireccionPorCoordenadas(LatLng coords) async {
    _ingresoController.updateIncidente(
      latitud: coords.latitude,
      longitud: coords.longitude,
    );
    
    setState(() => _isLoadingMap = true);
    final address = await GeocodingService.getAddressFromCoordinates(coords.latitude, coords.longitude);
    setState(() => _isLoadingMap = false);

    if (address != null) {
      _domicilioController.text = address;
      _ingresoController.updateIncidente(direccion: address);
    }

    // Sincronizar con el backend: se tiene latitud y longitud confirmadas del mapa
    await _ingresoController.syncIncidenteDesdeGoogleMaps();
  }

  @override
  void initState() {
    super.initState();
    _domicilioController = TextEditingController(text: _ingresoController.incidenteActual.direccion ?? '');
    _ingresoController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      final incidente = _ingresoController.incidenteActual;
      
      final nuevaDireccion = incidente.direccion ?? '';
      if (_domicilioController.text != nuevaDireccion && !_isLinkMode) {
        _domicilioController.text = nuevaDireccion;
      }

      // Si cargamos una demanda con coordenadas, movemos el mapa
      if (incidente.latitud != null && incidente.longitud != null) {
        final pos = LatLng(incidente.latitud!, incidente.longitud!);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _ingresoController.removeListener(_onControllerUpdate);
    _domicilioController.dispose();
    super.dispose();
  }

  /// Muestra el mapa real en web/móvil. En Windows/Linux/macOS (dev desktop)
  /// muestra un placeholder ya que el plugin no soporta esas plataformas.
  Widget _buildMapWidget() {
    final bool mapsSupported = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!mapsSupported) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 36, color: Colors.white24),
            const SizedBox(height: 8),
            const Text(
              'Mapa disponible solo en web y móvil',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final Set<Marker> markers = {};

    // 1. Marcador del incidente actual (Rojo)
    if (_ingresoController.incidenteActual.latitud != null &&
        _ingresoController.incidenteActual.longitud != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('incidente_location'),
          position: LatLng(
            _ingresoController.incidenteActual.latitud!,
            _ingresoController.incidenteActual.longitud!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndex: 2, // Por encima de los otros
        ),
      );
    }

    // 2. Marcadores de incidentes recientes (Azul / Celeste)
    final incidentes = _ingresoController.incidentesRecientes;
    if (incidentes != null) {
      for (var demanda in incidentes) {
      final inc = demanda.incidente;
      if (inc != null && inc.latitud != null && inc.longitud != null) {
        // Evitamos duplicar el marcador si es el mismo id que el actual
        if (inc.idIncidente != null && inc.idIncidente == _ingresoController.incidenteActual.idIncidente) continue;

        markers.add(
          Marker(
            markerId: MarkerId('recent_${inc.idIncidente ?? demanda.idDemandaRecibida}'),
            position: LatLng(inc.latitud!, inc.longitud!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            alpha: 0.7,
            infoWindow: InfoWindow(
              title: inc.direccion ?? 'Sin dirección',
              snippet: demanda.fechaHora != null 
                  ? 'Fecha: ${demanda.fechaHora!.day}/${demanda.fechaHora!.month} ${demanda.fechaHora!.hour}:${demanda.fechaHora!.minute}' 
                  : null,
            ),
            onTap: () async {
              if (inc.idIncidente != null) {
                final fullDemanda = await DemandaRecibidaService.obtenerPorIncidente(inc.idIncidente!);
                if (fullDemanda != null) {
                  _ingresoController.cargarDemanda(fullDemanda);
                }
              }
            },
          ),
        );
      }
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _ingresoController.incidenteActual.latitud ?? -38.9516,
          _ingresoController.incidenteActual.longitud ?? -68.0591,
        ),
        zoom: 13,
      ),
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: true,
      markers: markers,
      onMapCreated: (controller) => _mapController = controller,
      onTap: _buscarDireccionPorCoordenadas,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                onChanged: (val) => _ingresoController.updateIncidente(direccion: val),
                onFieldSubmitted: (_) => _buscarDireccionEnMapa(),
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
                initialSelection: _ingresoController.incidenteActual.idLocalidad == 580056 
                    ? _neuquenDefault 
                    : null,
                debounceMs: 500,
                fetchSuggestions: (query) => LocalidadService.buscar(query),
                itemLabel: (item) => item.descripcion,
                onSelected: (item) {
                  if (item != null) {
                    setState(() => _localidadSeleccionada = item);
                    _ingresoController.updateIncidente(idLocalidad: item.id);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _buscarDireccionEnMapa,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildMapWidget(),
            ),
          ),
        ),
        if (_isLoadingMap)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Center(
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
