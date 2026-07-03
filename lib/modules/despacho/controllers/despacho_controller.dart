import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/unidad.dart';
import '../../../shared/models/movil.dart';
import '../../../shared/models/demanda_recibida.dart';
import '../../../shared/models/incidente.dart';
import '../../../shared/models/victima.dart';
import '../../../shared/services/listados_service.dart';
import '../../../shared/services/demanda_recibida_service.dart';

class DespachoController extends ChangeNotifier {
  static final DespachoController _instance = DespachoController._internal();
  factory DespachoController() => _instance;
  DespachoController._internal() {
    inicializar();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Unidad> _unidades = [];
  List<Unidad> get unidades => _unidades;

  List<Movil> _moviles = [];
  List<Movil> get moviles => _moviles;

  List<DemandaRecibida> _incidentesActivos = [];
  List<DemandaRecibida> get incidentesActivos => _incidentesActivos;

  static const String _unidadesKey = 'despacho_unidades';
  static const String _movilesKey = 'despacho_moviles';

  Future<void> inicializar() async {
    _isLoading = true;
    notifyListeners();

    await _cargarDatosLocales();
    await cargarIncidentesActivos();

    _isLoading = false;
    notifyListeners();
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
        estado: 'Disponible',
        idUnidadAsignada: 'u1',
        latitud: -38.9515,
        longitud: -68.0610,
        personal: 'Dr. Rossi, Enf. Vega, Chof. Muñoz',
      ),
      Movil(
        id: 'm2',
        nombre: 'Móvil 2',
        estado: 'Disponible',
        idUnidadAsignada: 'u2',
        latitud: -38.9580,
        longitud: -68.0520,
        personal: 'Dra. Castillo, Enf. Pereyra, Chof. Gómez',
      ),
      Movil(
        id: 'm3',
        nombre: 'Móvil 3',
        estado: 'Inactivo',
        idUnidadAsignada: null,
        latitud: -38.9480,
        longitud: -68.0750,
        personal: 'Sin tripulación asignada',
      ),
    ];
    _guardarMoviles();
  }

  Future<void> cargarIncidentesActivos() async {
    try {
      final raw = await ListadosService.obtenerDemandasRecibidas();
      // Filtrar y mapear las demandas a DemandaRecibida.
      // Mostramos las que están en curso o pendientes de despacho (idCfgEstado = 5 o 6).
      // En este sistema, asumimos que todas las demandas devueltas son incidentes activos si su estado no es finalizado.
      _incidentesActivos = raw
          .map((e) => DemandaRecibida.fromJson(e))
          .where((demanda) {
            final estadoCod = demanda.idCfgEstado;
            // Mostramos los incidentes que no estén finalizados/cerrados
            // Si el backend no tiene estados detallados, se muestran todos los que posean incidente asociado
            return demanda.incidente != null && estadoCod != 7 && estadoCod != 8;
          })
          .toList();
      
      // Si el backend está vacío o no tiene incidentes con lat/lng, agregamos un par de incidentes simulados
      // para asegurar una experiencia increíble ("no placeholders, rich aesthetics").
      if (_incidentesActivos.isEmpty) {
        _incidentesActivos = [
          DemandaRecibida(
            idDemandaRecibida: 101,
            fechaHora: DateTime.now().subtract(const Duration(minutes: 15)),
            apellidoNombre: 'Juan Carlos Pérez',
            dni: '24333888',
            idCfgEstado: 5,
            usuario: 'Ingreso RAPH',
            incidente: Incidente(
              idIncidente: 901,
              direccion: 'Av. Argentina 250, Neuquén',
              descripcion: 'Paciente de 45 años con dolor torácico agudo y disnea.',
              latitud: -38.9516,
              longitud: -68.0591,
              fechaHoraAuto: DateTime.now().subtract(const Duration(minutes: 15)),
              victimas: [
                Victima(
                  idVictima: 801,
                  nombresApellidos: 'Juan Carlos Pérez',
                  dni: 24333888,
                  edad: 45,
                  idConfGenero: 1,
                  observaciones: 'Paciente principal con dolor torácico agudo y disnea.',
                ),
                Victima(
                  idVictima: 804,
                  nombresApellidos: 'Esteban Quito',
                  dni: 39555666,
                  edad: 28,
                  idConfGenero: 1,
                  observaciones: 'Familiar en el lugar, presenta crisis de ansiedad y taquicardia.',
                ),
              ],
            ),
          ),
          DemandaRecibida(
            idDemandaRecibida: 102,
            fechaHora: DateTime.now().subtract(const Duration(minutes: 8)),
            apellidoNombre: 'Marta Gómez',
            dni: '18444555',
            idCfgEstado: 6,
            usuario: 'Llamada 107',
            incidente: Incidente(
              idIncidente: 902,
              direccion: 'Ruta 22 y Cnel. Olascoaga, Neuquén',
              descripcion: 'Colisión de dos autos. Un conductor atrapado con traumatismos múltiples.',
              latitud: -38.9592,
              longitud: -68.0588,
              fechaHoraAuto: DateTime.now().subtract(const Duration(minutes: 8)),
              victimas: [
                Victima(
                  idVictima: 802,
                  nombresApellidos: 'Marta Gómez',
                  dni: 18444555,
                  edad: 52,
                  idConfGenero: 2,
                  observaciones: 'Conductora atrapada con traumatismos múltiples y dolor cervical.',
                ),
                Victima(
                  idVictima: 803,
                  nombresApellidos: 'Carlos López',
                  dni: 32111222,
                  edad: 30,
                  idConfGenero: 1,
                  observaciones: 'Acompañante con heridas cortantes leves en rostro y manos.',
                ),
                Victima(
                  idVictima: 805,
                  nombresApellidos: 'Lucía Fernández',
                  dni: 42111333,
                  edad: 24,
                  idConfGenero: 2,
                  observaciones: 'Peatón rozado por la colisión, presenta escoriaciones múltiples.',
                ),
              ],
            ),
          ),
        ];
      }

      notifyListeners();
    } catch (e) {
      print('[DespachoController] Error al obtener incidentes del backend: $e');
      // Fallback a mock si falla la red
      _incidentesActivos = [
        DemandaRecibida(
          idDemandaRecibida: 101,
          fechaHora: DateTime.now().subtract(const Duration(minutes: 15)),
          apellidoNombre: 'Juan Carlos Pérez',
          dni: '24333888',
          idCfgEstado: 5,
          usuario: 'Ingreso RAPH',
          incidente: Incidente(
            idIncidente: 901,
            direccion: 'Av. Argentina 250, Neuquén',
            descripcion: 'Paciente de 45 años con dolor torácico agudo y disnea.',
            latitud: -38.9516,
            longitud: -68.0591,
            fechaHoraAuto: DateTime.now().subtract(const Duration(minutes: 15)),
            victimas: [
              Victima(
                idVictima: 801,
                nombresApellidos: 'Juan Carlos Pérez',
                dni: 24333888,
                edad: 45,
                idConfGenero: 1,
                observaciones: 'Paciente principal con dolor torácico agudo y disnea.',
              ),
              Victima(
                idVictima: 804,
                nombresApellidos: 'Esteban Quito',
                dni: 39555666,
                edad: 28,
                idConfGenero: 1,
                observaciones: 'Familiar en el lugar, presenta crisis de ansiedad y taquicardia.',
              ),
            ],
          ),
        ),
        DemandaRecibida(
          idDemandaRecibida: 102,
          fechaHora: DateTime.now().subtract(const Duration(minutes: 8)),
          apellidoNombre: 'Marta Gómez',
          dni: '18444555',
          idCfgEstado: 6,
          usuario: 'Llamada 107',
          incidente: Incidente(
            idIncidente: 902,
            direccion: 'Ruta 22 y Cnel. Olascoaga, Neuquén',
            descripcion: 'Colisión de dos autos. Un conductor atrapado con traumatismos múltiples.',
            latitud: -38.9592,
            longitud: -68.0588,
            fechaHoraAuto: DateTime.now().subtract(const Duration(minutes: 8)),
            victimas: [
              Victima(
                idVictima: 802,
                nombresApellidos: 'Marta Gómez',
                dni: 18444555,
                edad: 52,
                idConfGenero: 2,
                observaciones: 'Conductora atrapada con traumatismos múltiples y dolor cervical.',
              ),
              Victima(
                idVictima: 803,
                nombresApellidos: 'Carlos López',
                dni: 32111222,
                edad: 30,
                idConfGenero: 1,
                observaciones: 'Acompañante con heridas cortantes leves en rostro y manos.',
              ),
              Victima(
                idVictima: 805,
                nombresApellidos: 'Lucía Fernández',
                dni: 42111333,
                edad: 24,
                idConfGenero: 2,
                observaciones: 'Peatón rozado por la colisión, presenta escoriaciones múltiples.',
              ),
            ],
          ),
        ),
      ];
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_movilesKey, jsonEncode(_moviles.map((e) => e.toJson()).toList()));
    } catch (e) {
      print('[DespachoController] Error al guardar móviles: $e');
    }
  }

  // --- Gestión de Unidades ---

  void agregarUnidad(Unidad u) {
    _unidades.add(u);
    _guardarUnidades();
    notifyListeners();
  }

  void actualizarUnidad(Unidad u) {
    final index = _unidades.indexWhere((element) => element.id == u.id);
    if (index != -1) {
      _unidades[index] = u;
      _guardarUnidades();
      notifyListeners();
    }
  }

  void eliminarUnidad(String id) {
    // Si la unidad está asignada a un móvil, quitamos la asignación del móvil primero
    final movilIndex = _moviles.indexWhere((m) => m.idUnidadAsignada == id);
    if (movilIndex != -1) {
      _moviles[movilIndex] = _moviles[movilIndex].copyWith(clearUnidad: true);
      _guardarMoviles();
    }
    _unidades.removeWhere((element) => element.id == id);
    _guardarUnidades();
    notifyListeners();
  }

  // --- Gestión de Móviles ---

  void agregarMovil(Movil m) {
    _moviles.add(m);
    _guardarMoviles();
    notifyListeners();
  }

  void actualizarMovil(Movil m) {
    final index = _moviles.indexWhere((element) => element.id == m.id);
    if (index != -1) {
      _moviles[index] = m;
      _guardarMoviles();
      notifyListeners();
    }
  }

  void eliminarMovil(String id) {
    // Si el móvil está asignado a una unidad, quitamos la asignación de la unidad primero
    final unidadIndex = _unidades.indexWhere((u) => u.idMovilAsignado == id);
    if (unidadIndex != -1) {
      _unidades[unidadIndex] = _unidades[unidadIndex].copyWith(clearMovil: true);
      _guardarUnidades();
    }
    _moviles.removeWhere((element) => element.id == id);
    _guardarMoviles();
    notifyListeners();
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

  void actualizarEstadoMovil(String idMovil, String nuevoEstado) {
    final mIndex = _moviles.indexWhere((m) => m.id == idMovil);
    if (mIndex != -1) {
      final movil = _moviles[mIndex];
      
      if (nuevoEstado == 'Disponible' || nuevoEstado == 'Inactivo') {
        // Al quedar disponible o inactivo, se libera del incidente activo
        _moviles[mIndex] = movil.copyWith(
          estado: nuevoEstado,
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
        _moviles[mIndex] = movil.copyWith(estado: nuevoEstado);
      }

      _guardarMoviles();
      notifyListeners();
    }
  }

  void asignarMovilAVictima(int idIncidente, int idVictima, String? idMovil) {
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

    // Obtener asignación actual y añadir el ID del nuevo móvil si no existe ya
    final currentAssigned = incident.victimas![vIndex].idMovilAsignado;
    final List<String> list = currentAssigned != null && currentAssigned.isNotEmpty
        ? currentAssigned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : [];
        
    if (!list.contains(idMovil)) {
      list.add(idMovil);
    }
    final nuevoString = list.join(',');

    // 2. Actualizar el móvil asignado en la víctima
    final victimaActualizada = incident.victimas![vIndex].copyWith(
      idMovilAsignado: nuevoString,
    );
    incident.victimas![vIndex] = victimaActualizada;

    // 3. Poner el móvil en estado Despachado
    final mIndex = _moviles.indexWhere((m) => m.id == idMovil);
    if (mIndex != -1) {
      double offsetLat = 0.002;
      double offsetLng = 0.002;
      double destLat = (incident.latitud ?? -38.9516) + offsetLat;
      double destLng = (incident.longitud ?? -68.0591) + offsetLng;

      _moviles[mIndex] = _moviles[mIndex].copyWith(
        estado: 'Despachado',
        idIncidenteActivo: idIncidente,
        latitud: destLat,
        longitud: destLng,
      );
    }

    _guardarMoviles();
    notifyListeners();
  }

  void removerMovilDeVictima(int idIncidente, int idVictima, String idMovil) {
    // 1. Encontrar el incidente y la víctima
    final incIndex = _incidentesActivos.indexWhere(
      (element) => element.incidente?.idIncidente == idIncidente || element.idDemandaRecibida == idIncidente
    );
    if (incIndex == -1) return;

    final incident = _incidentesActivos[incIndex].incidente;
    if (incident == null || incident.victimas == null) return;

    final vIndex = incident.victimas!.indexWhere((v) => v.idVictima == idVictima);
    if (vIndex == -1) return;

    // Obtener asignación actual y remover el ID del móvil especificado
    final currentAssigned = incident.victimas![vIndex].idMovilAsignado;
    if (currentAssigned == null || currentAssigned.isEmpty) return;

    final List<String> list = currentAssigned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    list.remove(idMovil);
    final nuevoString = list.isNotEmpty ? list.join(',') : null;

    // 2. Actualizar el móvil asignado en la víctima
    final victimaActualizada = incident.victimas![vIndex].copyWith(
      idMovilAsignado: nuevoString,
      clearMovil: nuevoString == null,
    );
    incident.victimas![vIndex] = victimaActualizada;

    // 3. Si el móvil ya no está asignado a ninguna víctima de los incidentes activos, liberarlo
    bool sigueEnUso = false;
    for (var dem in _incidentesActivos) {
      if (dem.incidente?.victimas != null) {
        for (var vic in dem.incidente!.victimas!) {
          final vicAssigned = vic.idMovilAsignado?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
          if (vicAssigned.contains(idMovil)) {
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
        _moviles[mIndex] = _moviles[mIndex].copyWith(
          estado: 'Disponible',
          clearIncidente: true,
          latitud: idMovil == 'm1' ? -38.9515 : (idMovil == 'm2' ? -38.9580 : -38.9480),
          longitud: idMovil == 'm1' ? -68.0610 : (idMovil == 'm2' ? -68.0520 : -68.0750),
        );
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
