import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/unidad.dart';
import '../../../shared/models/movil.dart';
import '../../../shared/models/movil_estado.dart';
import '../../../shared/models/demanda_recibida.dart';
import '../../../shared/models/incidente.dart';
import '../../../shared/models/victima.dart';
import '../../../shared/services/listados_service.dart';
import '../../../shared/services/demanda_recibida_service.dart';
import '../../../shared/services/geocoding_service.dart';
import '../../../shared/services/movil_service.dart';
import '../../../shared/services/movil_estado_service.dart';
import '../../../shared/services/despacho_service.dart';
import '../../../shared/services/unidad_service.dart';

class DespachoController extends ChangeNotifier {
  static final DespachoController _instance = DespachoController._internal();
  factory DespachoController() => _instance;
  DespachoController._internal();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  List<Unidad> _unidades = [];
  List<Unidad> get unidades => _unidades;

  List<Movil> _moviles = [];
  List<Movil> get moviles => _moviles;

  List<MovilEstado> _estadosMovil = [];
  List<MovilEstado> get estadosMovil => _estadosMovil;

  List<DemandaRecibida> _incidentesActivos = [];
  List<DemandaRecibida> get incidentesActivos => _incidentesActivos;

  static const String _unidadesKey = 'despacho_unidades';
  static const String _movilesKey = 'despacho_moviles';

  void _ordenarMoviles() {
    _moviles.sort((a, b) {
      int getPrioridad(Movil m) {
        final estadoLower = m.estado.trim().toLowerCase();
        if (m.idmovilEstado == 1 || estadoLower == 'disponible') {
          return 1;
        }
        if (m.idIncidenteActivo != null ||
            m.idmovilEstado == 2 ||
            estadoLower == 'despachado' ||
            estadoLower == 'en sitio' ||
            estadoLower == 'traslado' ||
            estadoLower == 'arribado') {
          return 2;
        }
        return 3;
      }

      final pA = getPrioridad(a);
      final pB = getPrioridad(b);
      if (pA != pB) {
        return pA.compareTo(pB);
      }
      return a.nombre.compareTo(b.nombre);
    });
  }

  int? getIdEstadoPorNombre(String estadoNombre) {
    if (_estadosMovil.isEmpty) return null;
    final found = _estadosMovil.firstWhere(
      (e) => e.nombre.toLowerCase().trim() == estadoNombre.toLowerCase().trim(),
      orElse: () => _estadosMovil.first,
    );
    return found.idmovilEstado;
  }

  Future<void> inicializar({bool force = false}) async {
    if (_isInitialized && !force) return;
    _isInitialized = true;
    _isLoading = true;
    notifyListeners();

    await _cargarDatosLocales();
    await Future.wait([
      cargarIncidentesActivos(),
      cargarMoviles(),
      cargarUnidades(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  bool _isMovilesLoading = false;
  bool get isMovilesLoading => _isMovilesLoading;

  bool _isUnidadesLoading = false;
  bool get isUnidadesLoading => _isUnidadesLoading;

  Future<void> cargarMoviles() async {
    _isMovilesLoading = true;
    notifyListeners();

    try {
      if (_estadosMovil.isEmpty) {
        _estadosMovil = await MovilEstadoService.obtenerEstados();
      }
      final remoteMoviles = await MovilService.obtenerMoviles();
      if (remoteMoviles.isNotEmpty) {
        _moviles = remoteMoviles;
        _guardarMoviles();
      }
    } catch (e) {
      print('[DespachoController] Error al obtener móviles del backend: $e');
    } finally {
      _isMovilesLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarUnidades() async {
    _isUnidadesLoading = true;
    notifyListeners();

    try {
      final remoteUnidades = await UnidadService.obtenerUnidades();
      if (remoteUnidades.isNotEmpty) {
        _unidades = remoteUnidades;
        _guardarUnidades();
      }
    } catch (e) {
      print('[DespachoController] Error al obtener unidades del backend: $e');
    } finally {
      _isUnidadesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarDatosLocales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unidadesJson = prefs.getString(_unidadesKey);
      final movilesJson = prefs.getString(_movilesKey);

      if (unidadesJson != null) {
        final List<dynamic> decoded = jsonDecode(unidadesJson);
        _unidades = decoded.map((e) => Unidad.fromJson(e)).toList();
      } else {
        _cargarUnidadesPredeterminadas();
      }

      if (movilesJson != null) {
        final List<dynamic> decoded = jsonDecode(movilesJson);
        _moviles = decoded.map((e) => Movil.fromJson(e)).toList();
        _ordenarMoviles();
      } else {
        _cargarMovilesPredeterminados();
      }
    } catch (e) {
      print('[DespachoController] Error al cargar datos de SharedPreferences: $e');
      _cargarUnidadesPredeterminadas();
      _cargarMovilesPredeterminados();
    }
  }

  void _cargarUnidadesPredeterminadas() {
    _unidades = [
      Unidad(
        id: 'u1',
        patente: 'AA 123 BC',
        marca: 'Mercedes-Benz',
        modelo: 'Sprinter 415',
        tipo: 'Alta Complejidad',
        estado: 'Activo',
        idMovilAsignado: 'm1',
      ),
      Unidad(
        id: 'u2',
        patente: 'AB 456 CD',
        marca: 'Toyota',
        modelo: 'Hilux 4x4',
        tipo: 'Alta Complejidad Zonal',
        estado: 'Activo',
        idMovilAsignado: 'm2',
      ),
      Unidad(
        id: 'u3',
        patente: 'AD 789 EF',
        marca: 'Renault',
        modelo: 'Master L2H2',
        tipo: 'Baja Complejidad',
        estado: 'Activo',
        idMovilAsignado: null,
      ),
      Unidad(
        id: 'u4',
        patente: 'AE 555 AA',
        marca: 'Ford',
        modelo: 'Transit',
        tipo: 'Móvil de Apoyo/Logístico',
        estado: 'Mantenimiento',
        idMovilAsignado: null,
      ),
    ];
    _guardarUnidades();
  }

  void _cargarMovilesPredeterminados() {
    _moviles = [
      Movil(
        id: 'm1',
        nombre: 'Móvil 1',
        descripcion: 'Unidad de Alta Complejidad - Base Central',
        activo: 1,
        estado: 'Disponible',
        idUnidadAsignada: 'u1',
        latitud: -38.9515,
        longitud: -68.0610,
      ),
      Movil(
        id: 'm2',
        nombre: 'Móvil 2',
        descripcion: 'Unidad 4x4 de Rescate - Base Zonal',
        activo: 1,
        estado: 'Disponible',
        idUnidadAsignada: 'u2',
        latitud: -38.9580,
        longitud: -68.0520,
      ),
      Movil(
        id: 'm3',
        nombre: 'Móvil 3',
        descripcion: 'Unidad de Reserva',
        activo: 0,
        estado: 'Inactivo',
        idUnidadAsignada: null,
        latitud: -38.9480,
        longitud: -68.0750,
      ),
    ];
    _guardarMoviles();
  }

  bool _isIncidentesLoading = false;
  bool get isIncidentesLoading => _isIncidentesLoading;

  int _getPrioridadPeso(DemandaRecibida d) {
    final inc = d.incidente;
    if (inc == null) return 4;
    final code = inc.idConfCodigo;
    final triage = inc.codigoTriage?.toLowerCase();

    if (code == 29 || triage == 'rojo') return 1;
    if (code == 30 || triage == 'amarillo') return 2;
    if (code == 31 || triage == 'verde') return 3;

    final desc = (inc.descripcion ?? '').toLowerCase();
    if (desc.contains('dolor tor') || desc.contains('trauma') || desc.contains('atrapado')) return 1;
    if (desc.contains('colisión') || desc.contains('vial')) return 2;

    return 3;
  }

  Future<void> cargarIncidentesActivos() async {
    if (_isIncidentesLoading) return;
    _isIncidentesLoading = true;
    notifyListeners();
    try {
      final raw = await ListadosService.obtenerIncidentesParaDespacho();
      final list = <DemandaRecibida>[];
      for (var e in raw) {
        Incidente? inc;
        int? idDemanda;
        int? estadoCod;

        if (e.containsKey('incidente') && e['incidente'] is Map) {
          inc = Incidente.fromJson(e['incidente']);
          idDemanda = int.tryParse(e['iddemandarecibida']?.toString() ?? '');
          estadoCod = int.tryParse(e['idcfg_estado']?.toString() ?? '');
        } else if (e.containsKey('idincidente') || e.containsKey('direccion')) {
          inc = Incidente.fromJson(e);
          idDemanda = int.tryParse(e['idincidente']?.toString() ?? '');
          if (e['ultimoEstadoRel'] is Map) {
            estadoCod = int.tryParse(e['ultimoEstadoRel']['idestado']?.toString() ?? '');
          }
        }

        if (inc != null && inc.activo != 0 && estadoCod != 7 && estadoCod != 8) {
          list.add(DemandaRecibida(
            idDemandaRecibida: idDemanda,
            idIncidente: inc.idIncidente,
            incidente: inc,
            idCfgEstado: estadoCod,
          ));
        }
      }
      
      // Geocodificar automáticamente las direcciones que no tengan latitud/longitud
      for (int i = 0; i < list.length; i++) {
        final d = list[i];
        if (d.incidente != null && (d.incidente!.latitud == null || d.incidente!.longitud == null)) {
          final dir = d.incidente!.direccion;
          if (dir != null && dir.trim().isNotEmpty) {
            final coords = await GeocodingService.getCoordinatesFromAddress(dir);
            if (coords != null) {
              list[i] = d.copyWith(
                incidente: d.incidente!.copyWith(
                  latitud: coords.latitude,
                  longitud: coords.longitude,
                ),
              );
            } else {
              // Asignar coordenadas centro Neuquén con offset si no se encuentra geocodificación
              final offset = ((d.idDemandaRecibida ?? 1) % 5) * 0.003;
              list[i] = d.copyWith(
                incidente: d.incidente!.copyWith(
                  latitud: -38.9516 + offset,
                  longitud: -68.0591 + offset,
                ),
              );
            }
          }
        }
      }

      // Ordenar por prioridad (Rojo -> Amarillo -> Verde) y fecha reciente
      list.sort((a, b) {
        final pA = _getPrioridadPeso(a);
        final pB = _getPrioridadPeso(b);
        if (pA != pB) return pA.compareTo(pB);
        final dateA = a.incidente?.fechaHoraAuto ?? a.fechaHora ?? DateTime(1970);
        final dateB = b.incidente?.fechaHoraAuto ?? b.fechaHora ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      _incidentesActivos = list;

      // Sincronizar estado de móviles según las víctimas y sus despachos activos en la BD
      for (var demanda in _incidentesActivos) {
        final inc = demanda.incidente;
        if (inc?.victimas != null) {
          for (var vic in inc!.victimas!) {
            if (vic.idMovilAsignado != null && vic.idMovilAsignado!.isNotEmpty) {
              final mId = vic.idMovilAsignado!;
              final cleanAssigned = mId.replaceAll(RegExp(r'[^0-9]'), '');
              final mIndex = _moviles.indexWhere((m) {
                final cleanM = m.id.replaceAll(RegExp(r'[^0-9]'), '');
                return m.id == mId || (cleanM.isNotEmpty && cleanM == cleanAssigned);
              });

              if (mIndex != -1) {
                final m = _moviles[mIndex];
                if (m.estado == 'Disponible') {
                  double offsetLat = 0.002;
                  double offsetLng = 0.002;
                  double destLat = (inc.latitud ?? -38.9516) + offsetLat;
                  double destLng = (inc.longitud ?? -68.0591) + offsetLng;

                  _moviles[mIndex] = m.copyWith(
                    estado: 'Despachado',
                    idmovilEstado: getIdEstadoPorNombre('Despachado'),
                    idIncidenteActivo: inc.idIncidente ?? demanda.idDemandaRecibida,
                    latitud: destLat,
                    longitud: destLng,
                  );
                }
              }
            }
          }
        }
      }
      _ordenarMoviles();
      notifyListeners();
    } catch (e) {
      print('[DespachoController] Error al obtener incidentes del backend: $e');
      notifyListeners();
    } finally {
      _isIncidentesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _guardarUnidades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_unidadesKey, jsonEncode(_unidades.map((e) => e.toJson()).toList()));
    } catch (e) {
      print('[DespachoController] Error al guardar unidades: $e');
    }
  }

  Future<void> _guardarMoviles() async {
    try {
      _ordenarMoviles();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_movilesKey, jsonEncode(_moviles.map((e) => e.toJson()).toList()));
    } catch (e) {
      print('[DespachoController] Error al guardar móviles: $e');
    }
  }



  // --- Gestión de Móviles ---

  Future<void> agregarMovil(Movil m) async {
    try {
      final creado = await MovilService.crearMovil(m);
      if (creado != null) {
        _moviles.add(creado);
      } else {
        _moviles.add(m);
      }
    } catch (e) {
      print('[DespachoController] Error al agregar móvil en backend: $e');
      _moviles.add(m);
    }
    _guardarMoviles();
    notifyListeners();
  }

  Future<void> actualizarMovil(Movil m) async {
    final index = _moviles.indexWhere((element) => element.id == m.id);
    if (index != -1) {
      try {
        final editado = await MovilService.actualizarMovil(m);
        _moviles[index] = editado ?? m;
      } catch (e) {
        print('[DespachoController] Error al actualizar móvil en backend: $e');
        _moviles[index] = m;
      }
      _guardarMoviles();
      notifyListeners();
    }
  }

  Future<void> eliminarMovil(String id) async {
    // Si el móvil está asignado a una unidad, quitamos la asignación de la unidad primero
    final unidadIndex = _unidades.indexWhere((u) => u.idMovilAsignado == id);
    if (unidadIndex != -1) {
      _unidades[unidadIndex] = _unidades[unidadIndex].copyWith(clearMovil: true);
      _guardarUnidades();
    }
    try {
      await MovilService.eliminarMovil(id);
      await cargarMoviles();
    } catch (e) {
      print('[DespachoController] Error al eliminar móvil en backend: $e');
      _moviles.removeWhere((element) => element.id == id);
      _guardarMoviles();
      notifyListeners();
    }
  }

  // --- Asignación Unidad <-> Móvil ---

  void asignarUnidadAMovil(String idMovil, String? idUnidad) {
    // 1. Quitar asignación previa de este móvil en cualquier unidad
    for (int i = 0; i < _unidades.length; i++) {
      if (_unidades[i].idMovilAsignado == idMovil) {
        _unidades[i] = _unidades[i].copyWith(clearMovil: true);
      }
    }

    // 2. Si se asigna una unidad específica
    if (idUnidad != null) {
      // Quitar cualquier móvil que estuviese usando esa unidad previamente
      for (int i = 0; i < _moviles.length; i++) {
        if (_moviles[i].idUnidadAsignada == idUnidad) {
          _moviles[i] = _moviles[i].copyWith(clearUnidad: true);
        }
      }
      
      // Asignar en la unidad
      final uIndex = _unidades.indexWhere((u) => u.id == idUnidad);
      if (uIndex != -1) {
        _unidades[uIndex] = _unidades[uIndex].copyWith(idMovilAsignado: idMovil);
      }
    }

    // 3. Asignar en el móvil
    final mIndex = _moviles.indexWhere((m) => m.id == idMovil);
    if (mIndex != -1) {
      if (idUnidad == null) {
        _moviles[mIndex] = _moviles[mIndex].copyWith(clearUnidad: true);
      } else {
        _moviles[mIndex] = _moviles[mIndex].copyWith(idUnidadAsignada: idUnidad);
      }
    }

    _guardarUnidades();
    _guardarMoviles();
    notifyListeners();
  }

  // --- Operaciones de Despacho ---

  void despacharMovil(String idMovil, int idIncidente) {
    final mIndex = _moviles.indexWhere((m) => m.id == idMovil);
    if (mIndex != -1) {
      final incidente = _incidentesActivos.firstWhere(
        (inc) => (inc.incidente?.idIncidente == idIncidente || inc.idDemandaRecibida == idIncidente),
      );
      
      // Colocar el móvil en la ubicación del incidente con un ligero desfase
      double offsetLat = 0.002;
      double offsetLng = 0.002;
      double destLat = (incidente.incidente?.latitud ?? -38.9516) + offsetLat;
      double destLng = (incidente.incidente?.longitud ?? -68.0591) + offsetLng;

      _moviles[mIndex] = _moviles[mIndex].copyWith(
        estado: 'Despachado',
        idIncidenteActivo: idIncidente,
        latitud: destLat,
        longitud: destLng,
      );

      _guardarMoviles();
      notifyListeners();
    }
  }

  void actualizarEstadoMovil(String idMovil, String nuevoEstado) async {
    final mIndex = _moviles.indexWhere((m) => m.id == idMovil);
    if (mIndex != -1) {
      final movil = _moviles[mIndex];
      final idEstado = getIdEstadoPorNombre(nuevoEstado);
      
      Movil movilActualizado;
      if (nuevoEstado == 'Disponible' || nuevoEstado == 'Inactivo') {
        // Al quedar disponible o inactivo, se libera del incidente activo
        movilActualizado = movil.copyWith(
          estado: nuevoEstado,
          idmovilEstado: idEstado,
          clearIncidente: true,
          // Volver a la base/coordenadas por defecto
          latitud: movil.id == 'm1' ? -38.9515 : (movil.id == 'm2' ? -38.9580 : -38.9480),
          longitud: movil.id == 'm1' ? -68.0610 : (movil.id == 'm2' ? -68.0520 : -68.0750),
        );
        // Limpiar la asignación de este móvil en cualquier víctima de los incidentes activos (split por comas)
        for (var dem in _incidentesActivos) {
          if (dem.incidente?.victimas != null) {
            for (int i = 0; i < dem.incidente!.victimas!.length; i++) {
              final currentAssigned = dem.incidente!.victimas![i].idMovilAsignado;
              if (currentAssigned != null && currentAssigned.isNotEmpty) {
                final List<String> list = currentAssigned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                if (list.contains(idMovil)) {
                  list.remove(idMovil);
                  final nuevoString = list.isNotEmpty ? list.join(',') : null;
                  dem.incidente!.victimas![i] = dem.incidente!.victimas![i].copyWith(
                    idMovilAsignado: nuevoString,
                    clearMovil: nuevoString == null,
                  );
                }
              }
            }
          }
        }
      } else {
        movilActualizado = movil.copyWith(
          estado: nuevoEstado,
          idmovilEstado: idEstado,
        );
      }

      _moviles[mIndex] = movilActualizado;
      _guardarMoviles();
      notifyListeners();

      try {
        await MovilService.actualizarMovil(movilActualizado);
      } catch (e) {
        print('[DespachoController] Error al sincronizar estado de móvil con backend: $e');
      }
    }
  }

  void asignarMovilAVictima(int idIncidente, int idVictima, String? idMovil) async {
    if (idMovil == null) return;

    // 1. Encontrar el incidente y la víctima
    final incIndex = _incidentesActivos.indexWhere(
      (element) => element.incidente?.idIncidente == idIncidente || element.idDemandaRecibida == idIncidente
    );
    if (incIndex == -1) return;

    final incident = _incidentesActivos[incIndex].incidente;
    if (incident == null || incident.victimas == null) return;

    final vIndex = incident.victimas!.indexWhere((v) => v.idVictima == idVictima);
    if (vIndex == -1) return;

    final victima = incident.victimas![vIndex];
    final previousMovilId = victima.idMovilAsignado;

    // Si la víctima ya tenía un móvil asignado anterior (diferente al nuevo), liberarlo si no está en uso en otro lado
    if (previousMovilId != null && previousMovilId.isNotEmpty && previousMovilId != idMovil) {
      bool sigueEnUso = false;
      for (var dem in _incidentesActivos) {
        if (dem.incidente?.victimas != null) {
          for (var vic in dem.incidente!.victimas!) {
            if (vic.idVictima != idVictima && vic.idMovilAsignado == previousMovilId) {
              sigueEnUso = true;
              break;
            }
          }
        }
        if (sigueEnUso) break;
      }

      if (!sigueEnUso) {
        final prevMIndex = _moviles.indexWhere((m) => m.id == previousMovilId);
        if (prevMIndex != -1) {
          _moviles[prevMIndex] = _moviles[prevMIndex].copyWith(
            estado: 'Disponible',
            clearIncidente: true,
            latitud: previousMovilId == 'm1' ? -38.9515 : (previousMovilId == 'm2' ? -38.9580 : -38.9480),
            longitud: previousMovilId == 'm1' ? -68.0610 : (previousMovilId == 'm2' ? -68.0520 : -68.0750),
          );
        }
      }
    }

    // 2. Asignar ÚNICAMENTE el nuevo móvil (1 móvil por víctima)
    final victimaActualizada = victima.copyWith(
      idMovilAsignado: idMovil,
    );
    incident.victimas![vIndex] = victimaActualizada;

    // 3. Poner el móvil en estado Despachado y persistir
    final mIndex = _moviles.indexWhere((m) => m.id == idMovil);
    if (mIndex != -1) {
      double offsetLat = 0.002;
      double offsetLng = 0.002;
      double destLat = (incident.latitud ?? -38.9516) + offsetLat;
      double destLng = (incident.longitud ?? -68.0591) + offsetLng;
      final idEstadoDespachado = getIdEstadoPorNombre('Despachado');

      final movilActualizado = _moviles[mIndex].copyWith(
        estado: 'Despachado',
        idmovilEstado: idEstadoDespachado,
        idIncidenteActivo: idIncidente,
        latitud: destLat,
        longitud: destLng,
      );

      _moviles[mIndex] = movilActualizado;

      try {
        await MovilService.actualizarMovil(movilActualizado);
      } catch (e) {
        print('[DespachoController] Error al sincronizar despacho con backend: $e');
      }

      // 4. Crear registro en la tabla ser_sien_dsp_despacho enviando el idmovil en el campo idmovilunidad
      final cleanIdMovil = movilActualizado.id.replaceAll(RegExp(r'[^0-9]'), '');
      final idMovilInt = cleanIdMovil.isNotEmpty ? int.tryParse(cleanIdMovil) : null;

      if (idMovilInt != null) {
        try {
          final res = await DespachoService.registrarDespacho(
            idVictima: idVictima,
            idIncidente: idIncidente,
            idMovilUnidad: idMovilInt,
            observacion: 'Despacho asignado desde RAPH Web para víctima #$idVictima',
          );
          if (res != null && res['iddespacho'] != null) {
            final idDespachoCreated = int.tryParse(res['iddespacho'].toString());
            if (idDespachoCreated != null) {
              incident.victimas![vIndex] = victimaActualizada.copyWith(idDespacho: idDespachoCreated);
            }
          }
        } catch (e) {
          print('[DespachoController] Error al registrar despacho en la tabla ser_sien_dsp_despacho: $e');
        }
      }
    }

      _guardarMoviles();
    notifyListeners();
  }

  void despacharMovilAIncidenteSinVictima(int idIncidente, String idMovil) async {
    final incIndex = _incidentesActivos.indexWhere(
      (element) => element.incidente?.idIncidente == idIncidente || element.idDemandaRecibida == idIncidente
    );
    if (incIndex == -1) return;

    final incident = _incidentesActivos[incIndex].incidente;
    if (incident == null) return;

    final mIndex = _moviles.indexWhere((m) => m.id == idMovil);
    if (mIndex != -1) {
      double offsetLat = 0.002;
      double offsetLng = 0.002;
      double destLat = (incident.latitud ?? -38.9516) + offsetLat;
      double destLng = (incident.longitud ?? -68.0591) + offsetLng;
      final idEstadoDespachado = getIdEstadoPorNombre('Despachado');

      final movilActualizado = _moviles[mIndex].copyWith(
        estado: 'Despachado',
        idmovilEstado: idEstadoDespachado,
        idIncidenteActivo: idIncidente,
        latitud: destLat,
        longitud: destLng,
      );

      _moviles[mIndex] = movilActualizado;

      try {
        await MovilService.actualizarMovil(movilActualizado);
      } catch (e) {
        print('[DespachoController] Error al sincronizar despacho con backend: $e');
      }

      final cleanIdMovil = movilActualizado.id.replaceAll(RegExp(r'[^0-9]'), '');
      final idMovilInt = cleanIdMovil.isNotEmpty ? int.tryParse(cleanIdMovil) : null;

      if (idMovilInt != null) {
        try {
          await DespachoService.registrarDespacho(
            idIncidente: idIncidente,
            idMovilUnidad: idMovilInt,
            observacion: 'Despacho Rápido emitido desde pantalla Despachos',
          );
        } catch (e) {
          print('[DespachoController] Error al registrar despacho sin víctima: $e');
        }
      }
    }

    _guardarMoviles();
    notifyListeners();
  }

  void removerMovilDeVictima(int idIncidente, int idVictima, String idMovil, {int? idDespacho}) async {
    // 1. Encontrar el incidente y la víctima
    final incIndex = _incidentesActivos.indexWhere(
      (element) => element.incidente?.idIncidente == idIncidente || element.idDemandaRecibida == idIncidente
    );
    if (incIndex == -1) return;

    final incident = _incidentesActivos[incIndex].incidente;
    if (incident == null || incident.victimas == null) return;

    final vIndex = incident.victimas!.indexWhere((v) => v.idVictima == idVictima);
    if (vIndex == -1) return;

    final idDespachoAEliminar = idDespacho ?? incident.victimas![vIndex].idDespacho;

    // 2. Desasignar móvil de la víctima
    final victimaActualizada = incident.victimas![vIndex].copyWith(
      clearMovil: true,
    );
    incident.victimas![vIndex] = victimaActualizada;

    // 3. Eliminar el despacho de la BD si tenemos su ID
    if (idDespachoAEliminar != null) {
      try {
        await DespachoService.cancelarDespacho(idDespachoAEliminar);
      } catch (e) {
        print('[DespachoController] Error al cancelar despacho $idDespachoAEliminar: $e');
      }
    }

    // 4. Si el móvil ya no está asignado a ninguna otra víctima de los incidentes activos, liberarlo
    bool sigueEnUso = false;
    for (var dem in _incidentesActivos) {
      if (dem.incidente?.victimas != null) {
        for (var vic in dem.incidente!.victimas!) {
          if (vic.idMovilAsignado == idMovil) {
            sigueEnUso = true;
            break;
          }
        }
      }
      if (sigueEnUso) break;
    }

    if (!sigueEnUso) {
      final mIndex = _moviles.indexWhere((m) => m.id == idMovil);
      if (mIndex != -1) {
        final movilLibre = _moviles[mIndex].copyWith(
          estado: 'Disponible',
          clearIncidente: true,
          latitud: idMovil == 'm1' ? -38.9515 : (idMovil == 'm2' ? -38.9580 : -38.9480),
          longitud: idMovil == 'm1' ? -68.0610 : (idMovil == 'm2' ? -68.0520 : -68.0750),
        );
        _moviles[mIndex] = movilLibre;
        try {
          await MovilService.actualizarMovil(movilLibre);
        } catch (e) {
          print('[DespachoController] Error al actualizar estado del móvil $idMovil: $e');
        }
      }
    }

    _guardarMoviles();
    notifyListeners();
  }

  void liberarMovilDeIncidente(String idMovil) {
    actualizarEstadoMovil(idMovil, 'Disponible');
  }

  Future<void> cerrarIncidente(int idDemandaRecibida, String reporteIncidente, Map<int, String> reportesVictimas) async {
    // 1. Encontrar la demanda/incidente activo en la lista local
    final index = _incidentesActivos.indexWhere((element) => element.idDemandaRecibida == idDemandaRecibida);
    if (index == -1) return;

    final demanda = _incidentesActivos[index];
    final incidente = demanda.incidente;
    if (incidente == null) return;

    // 2. Liberar todos los móviles que estuviesen asignados a las víctimas de este incidente
    if (incidente.victimas != null) {
      for (var vic in incidente.victimas!) {
        final assignedIds = vic.idMovilAsignado?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
        for (var mId in assignedIds) {
          final mIndex = _moviles.indexWhere((m) => m.id == mId);
          if (mIndex != -1) {
            _moviles[mIndex] = _moviles[mIndex].copyWith(
              estado: 'Disponible',
              clearIncidente: true,
              latitud: mId == 'm1' ? -38.9515 : (mId == 'm2' ? -38.9580 : -38.9480),
              longitud: mId == 'm1' ? -68.0610 : (mId == 'm2' ? -68.0520 : -68.0750),
            );
          }
        }
      }
    }

    // 3. Crear el nuevo Incidente y las nuevas Víctimas con sus reportes cargados
    List<Victima>? victimasActualizadas;
    if (incidente.victimas != null) {
      victimasActualizadas = incidente.victimas!.map((v) {
        final reporte = reportesVictimas[v.idVictima] ?? '';
        return v.copyWith(
          reporte: reporte.isNotEmpty ? reporte : null,
          clearMovil: true, // Liberar móvil
        );
      }).toList();
    }

    final incidenteActualizado = incidente.copyWith(
      reporte: reporteIncidente.isNotEmpty ? reporteIncidente : null,
      victimas: victimasActualizadas,
    );

    // 4. Actualizar la demanda recibida con el nuevo estado (7 = Finalizado)
    final demandaActualizada = demanda.copyWith(
      idCfgEstado: 7,
      incidente: incidenteActualizado,
    );

    // 5. Enviar actualización al backend
    await DemandaRecibidaService.actualizar(demandaActualizada);

    // 6. Remover de la lista de incidentes activos y notificar
    _incidentesActivos.removeAt(index);
    _guardarMoviles();
    notifyListeners();
  }
}
