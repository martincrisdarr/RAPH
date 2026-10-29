import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/demanda_recibida.dart';
import '../../../shared/services/demanda_recibida_service.dart';
import '../../../shared/models/incidente.dart';
import '../../../shared/services/incidente_service.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/services/victima_service.dart';
import '../../../shared/services/socket_service.dart';
import '../../../shared/services/configuracion_service.dart';
import '../../../shared/services/despacho_service.dart';
import '../../despacho/controllers/despacho_controller.dart';

class IngresoController extends ChangeNotifier {
  static final IngresoController _instance = IngresoController._internal();
  factory IngresoController() => _instance;
  IngresoController._internal() {
    _cargarBorrador();
  }

  DemandaRecibida _demandaActual = DemandaRecibida(idCfgEstado: 5);
  DemandaRecibida get demandaActual => _demandaActual;

  Incidente _incidenteActual = Incidente(idLocalidad: 580056);
  Incidente get incidenteActual => _incidenteActual;

  int _pasoIncidente = 0;
  int get pasoIncidente => _pasoIncidente;

  List<Map<String, dynamic>> _despachosActivos = [];
  List<Map<String, dynamic>> get despachosActivos => _despachosActivos;

  void setPasoIncidente(int paso) {
    _pasoIncidente = paso.clamp(0, 5);
    notifyListeners();
  }

  bool _tieneBorrador = false;


  Timer? _debounceTimer;
  Timer? _debounceIncidenteTimer;
  static const String _draftKey = 'demanda_draft';
  static const String _incidenteDraftKey = 'incidente_draft';

  int? _lastJoinedIncidenteId;
  final Map<String, void Function(String)> _registeredCallbacks = {};
  void Function(String)? _actionCallback;

  void _sincronizarSocketRoom() {
    final currentId = _incidenteActual.idIncidente;
    if (currentId != _lastJoinedIncidenteId) {
      _lastJoinedIncidenteId = currentId;
      if (currentId != null) {
        SocketService().joinRecord('incidente', currentId);
        _registrarOyentesSocketVictimas();
      } else {
        _limpiarOyentesSocketVictimas();
      }
    }
  }

  void _registrarOyenteEspecifico(String fieldId, void Function(String) callback) {
    if (_registeredCallbacks.containsKey(fieldId)) {
      SocketService().unregisterFieldListener(fieldId, _registeredCallbacks[fieldId]!);
    }
    _registeredCallbacks[fieldId] = callback;
    SocketService().registerFieldListener(fieldId, callback);
  }

  void _limpiarOyentesSocketVictimas() {
    releaseVictimaLock();
    _registeredCallbacks.forEach((fieldId, callback) {
      SocketService().unregisterFieldListener(fieldId, callback);
    });
    _registeredCallbacks.clear();
    
    if (_actionCallback != null) {
      SocketService().unregisterFieldListener('victimas_action', _actionCallback!);
      _actionCallback = null;
    }
  }

  void _registrarOyentesSocketVictimas() {
    _limpiarOyentesSocketVictimas();
    
    // Escuchar acciones estructurales (agregar/eliminar víctimas)
    _actionCallback = (val) {
      if (val == 'add') {
        addVictima(emitirSocket: false);
      } else if (val.startsWith('remove:')) {
        final parts = val.split(':');
        if (parts.length > 1) {
          final index = int.tryParse(parts[1]);
          if (index != null) {
            removeVictima(index, emitirSocket: false);
          }
        }
      }
    };
    SocketService().registerFieldListener('victimas_action', _actionCallback!);

    // Registrar oyentes para cada víctima actual
    for (int i = 0; i < _victimas.length; i++) {
      _registrarOyentesParaVictimaIndex(i);
    }
  }

  void _registrarOyentesParaVictimaIndex(int index) {
    _registrarOyenteEspecifico('victima_${index}_nombre', (val) {
      updateVictima(index, nombre: val, emitirSocket: false);
    });
    _registrarOyenteEspecifico('victima_${index}_dni', (val) {
      updateVictima(index, dni: val, emitirSocket: false);
    });
    _registrarOyenteEspecifico('victima_${index}_edad', (val) {
      updateVictima(index, edad: val, emitirSocket: false);
    });
    _registrarOyenteEspecifico('victima_${index}_observaciones', (val) {
      updateVictima(index, observaciones: val, emitirSocket: false);
    });
    _registrarOyenteEspecifico('victima_${index}_genero', (val) {
      final id = int.tryParse(val);
      updateVictima(index, idConfGenero: id, emitirSocket: false);
    });
    _registrarOyenteEspecifico('victima_${index}_triage', (val) {
      updateVictima(index, codigoTriage: val, emitirSocket: false);
    });
    _registrarOyenteEspecifico('victima_${index}_sintomas', (val) {
      final sintomasList = val.isEmpty ? <String>[] : val.split(',');
      updateVictima(index, sintomas: sintomasList, emitirSocket: false);
    });
  }

  List<DemandaRecibida> _incidentesRecientes = [];
  List<DemandaRecibida> get incidentesRecientes => _incidentesRecientes;
  set incidentesRecientes(List<DemandaRecibida> value) {
    _incidentesRecientes = value;
    notifyListeners();
  }

  bool _vistaFormulario = true;
  bool get vistaFormulario => _vistaFormulario;
  set vistaFormulario(bool value) {
    _vistaFormulario = value;
    notifyListeners();
  }

  List<DemandaRecibida> _llamadasDelIncidente = [];
  List<DemandaRecibida> get llamadasDelIncidente => _llamadasDelIncidente;
  set llamadasDelIncidente(List<DemandaRecibida> value) {
    _llamadasDelIncidente = value;
    notifyListeners();
  }

  List<String> get protocolosSeleccionados {
    if (_incidenteActual.protocolosIds == null || _incidenteActual.protocolosIds!.isEmpty) {
      return [];
    }
    return _incidenteActual.protocolosIds!.split(',');
  }

  set protocolosSeleccionados(List<String> value) {
    final newIds = value.join(',');
    updateIncidente(protocolosIds: newIds, syncInmediato: false);
    
    if (value.isEmpty) {
      if (_incidenteActual.codigoTriage?.toLowerCase() == 'rojo' ||
          _incidenteActual.idConfCodigo == 29 ||
          _incidenteActual.idConfCodigo == 135) {
        updateIncidente(
          codigoTriage: 'Sin código',
          idConfCodigo: ConfiguracionService.idSinCodigoConst,
          clearCodigo: true,
          syncInmediato: true,
        );
        updateTodasLasVictimas(codigoTriage: '');
      }
    } else {
      _asegurarTriageRojoVictimas();
    }
    _guardarBorrador();
    notifyListeners();
  }

  List<String> _etiquetasSeleccionadas = [];
  List<String> get etiquetasSeleccionadas => _etiquetasSeleccionadas;
  set etiquetasSeleccionadas(List<String> value) {
    _etiquetasSeleccionadas = value;
    _guardarBorrador();
    notifyListeners();
  }

  bool get tieneBorrador {
    final tieneIdIncidente = _incidenteActual.idIncidente != null;
    final tieneIdDemanda = _demandaActual.idDemandaRecibida != null;
    final tieneTelefono = _demandaActual.nroLlamadaEntrante != null;
    final tieneNombre = _demandaActual.apellidoNombre != null && _demandaActual.apellidoNombre!.trim().isNotEmpty;
    final tieneDireccion = _incidenteActual.direccion != null && _incidenteActual.direccion!.trim().isNotEmpty;
    final tieneDescripcion = _incidenteActual.descripcion != null && _incidenteActual.descripcion!.trim().isNotEmpty;
    final tieneProtocolos = protocolosSeleccionados.isNotEmpty;

    final tieneContenidoReal = tieneIdIncidente || tieneIdDemanda || tieneTelefono || tieneNombre || tieneDireccion || tieneDescripcion || tieneProtocolos;
    return _tieneBorrador && tieneContenidoReal;
  }

  Future<void> _cargarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    final incDraftJson = prefs.getString(_incidenteDraftKey);
    final victimasDraftJson = prefs.getString('victimas_draft');

    if (draftJson != null) {
      try {
        final decoded = jsonDecode(draftJson);
        _demandaActual = DemandaRecibida.fromJson(decoded);
      } catch (e) {
        print('Error al cargar borrador de demanda: $e');
      }
    }

    if (incDraftJson != null) {
      try {
        final decoded = jsonDecode(incDraftJson);
        _incidenteActual = Incidente.fromJson(decoded);
        _sincronizarSocketRoom();
      } catch (e) {
        print('Error al cargar borrador de incidente: $e');
      }
    }

    if (victimasDraftJson != null) {
      try {
        final List decodedV = jsonDecode(victimasDraftJson);
        if (decodedV.isNotEmpty) {
          _victimas = decodedV.map((v) => VictimaData.fromStorageJson(v)).toList();
        }
      } catch (e) {
        print('Error al cargar borrador de víctimas: $e');
      }
    }


    _tieneBorrador = _incidenteActual.idIncidente != null ||
        _demandaActual.idDemandaRecibida != null ||
        _demandaActual.nroLlamadaEntrante != null ||
        (_demandaActual.apellidoNombre != null && _demandaActual.apellidoNombre!.trim().isNotEmpty) ||
        (_incidenteActual.direccion != null && _incidenteActual.direccion!.trim().isNotEmpty) ||
        (_incidenteActual.descripcion != null && _incidenteActual.descripcion!.trim().isNotEmpty) ||
        protocolosSeleccionados.isNotEmpty;
    
    _asegurarTriageRojoVictimas();
    if (_incidenteActual.idIncidente != null) {
      _cargarDatosDiferidosIncidente(_incidenteActual.idIncidente!);
    }
    actualizarPasoIncidente();
    notifyListeners();
  }

  Future<void> _guardarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    
    final tieneContenidoReal = _incidenteActual.idIncidente != null ||
        _demandaActual.idDemandaRecibida != null ||
        _demandaActual.nroLlamadaEntrante != null ||
        (_demandaActual.apellidoNombre != null && _demandaActual.apellidoNombre!.trim().isNotEmpty) ||
        (_incidenteActual.direccion != null && _incidenteActual.direccion!.trim().isNotEmpty) ||
        (_incidenteActual.descripcion != null && _incidenteActual.descripcion!.trim().isNotEmpty) ||
        protocolosSeleccionados.isNotEmpty;

    if (!tieneContenidoReal) {
      await prefs.remove(_draftKey);
      await prefs.remove(_incidenteDraftKey);
      await prefs.remove('novedades_draft');
      await prefs.remove('victimas_draft');
      await prefs.remove('protocolos_draft');
      if (_tieneBorrador) {
        _tieneBorrador = false;
        notifyListeners();
      }
      return;
    }

    await prefs.setString(_draftKey, jsonEncode(_demandaActual.toJson()));
    await prefs.setString(_incidenteDraftKey, jsonEncode(_incidenteActual.toJson()));
    final victimasJson = _victimas.map((v) => v.toStorageJson()).toList();
    await prefs.setString('victimas_draft', jsonEncode(victimasJson));
    if (!_tieneBorrador) {
      _tieneBorrador = true;
      notifyListeners();
    }
  }

  Future<void> limpiarBorrador() async {
    _debounceTimer?.cancel();
    _debounceIncidenteTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_incidenteDraftKey);
    await prefs.remove('novedades_draft');
    await prefs.remove('victimas_draft');
    await prefs.remove('protocolos_draft');
    _demandaActual = DemandaRecibida(idCfgEstado: 5);
    _incidenteActual = Incidente(idLocalidad: 580056);
    _victimas = [VictimaData()];
    _selectedVictimaIndex = 0;
    _llamadasDelIncidente = [];
    _tieneBorrador = false;
    _vistaFormulario = true;
    _pasoIncidente = 0;
    _despachosActivos.clear();
    _sincronizarSocketRoom();
    notifyListeners();
  }

  /// Prepara el formulario de ingreso para registrar una nueva llamada sobre el MISMO incidente activo
  Future<void> prepararNuevaLlamadaParaIncidente() async {
    final currentIncId = _incidenteActual.idIncidente;
    final currentInc = _incidenteActual;

    // Se resetea la demanda (teléfono, nombre del llamante, etc.) manteniendo la vinculación con el incidente activo
    _demandaActual = DemandaRecibida(
      idCfgEstado: 5,
      idIncidente: currentIncId,
      incidente: currentInc,
      fechaHora: DateTime.now(),
    );

    _vistaFormulario = true;
    _sincronizarSocketRoom();
    await _guardarBorrador();
    notifyListeners();
  }

  Future<void> prepararNuevoIncidente() async {
    // Preservar datos de la llamada/demanda
    final tipoIngreso = _demandaActual.idCfgTipoIngreso;
    final nroLlamada = _demandaActual.nroLlamadaEntrante;
    final nombre = _demandaActual.apellidoNombre;
    final dni = _demandaActual.dni;

    // Resetear demanda a borrador limpio pero con los datos de la llamada
    _demandaActual = DemandaRecibida(
      idCfgEstado: 5,
      idCfgTipoIngreso: tipoIngreso,
      nroLlamadaEntrante: nroLlamada,
      apellidoNombre: nombre,
      dni: dni,
      fechaHora: DateTime.now(),
    );

    // Resetear incidente a uno nuevo
    _incidenteActual = Incidente(idLocalidad: 580056);
    
    // Resetear víctimas a una vacía
    _victimas = [VictimaData()];
    _selectedVictimaIndex = 0;
    _llamadasDelIncidente = [];
    _vistaFormulario = true;

    _sincronizarSocketRoom();
    await _guardarBorrador();
    notifyListeners();
  }

  void updateDemanda({
    int? idCfgTipoIngreso,
    int? nroLlamadaEntrante,
    String? apellidoNombre,
    String? dni,
    int? idCfgEstado,
    bool clearNroLlamada = false,
  }) {
    _demandaActual = _demandaActual.copyWith(
      idCfgTipoIngreso: idCfgTipoIngreso,
      nroLlamadaEntrante: nroLlamadaEntrante,
      apellidoNombre: apellidoNombre,
      dni: dni,
      idCfgEstado: idCfgEstado,
      clearNroLlamada: clearNroLlamada,
      // Actualizamos la fecha a ahora
      fechaHora: DateTime.now(),
    );
    
    _guardarBorrador();
    notifyListeners();
    _programarGuardadoRemoto();
  }

  void updateIncidente({
    String? direccion,
    int? idLocalidad,
    double? latitud,
    double? longitud,
    String? direccionAuto,
    String? descripcion,
    String? codigoTriage,
    int? idConfCodigo,
    String? protocolosIds,
    bool clearCodigo = false,
    bool syncInmediato = false,
    bool fromSocket = false,
  }) {
    final bool esSinCodigo = clearCodigo ||
        (codigoTriage != null &&
            (codigoTriage.trim().isEmpty ||
                codigoTriage.toLowerCase().contains('sin')));

    int? nuevoIdConf = idConfCodigo;
    String? nuevoTriage = codigoTriage;

    if (esSinCodigo) {
      nuevoIdConf = idConfCodigo ?? ConfiguracionService.idSinCodigoConst;
      nuevoTriage = 'Sin código';
    } else if (nuevoTriage != null) {
      if (nuevoTriage.toLowerCase() == 'rojo') {
        nuevoIdConf ??= 29;
      } else if (nuevoTriage.toLowerCase() == 'amarillo') {
        nuevoIdConf ??= 30;
      } else if (nuevoTriage.toLowerCase() == 'verde') {
        nuevoIdConf ??= 31;
      }
    } else if (nuevoIdConf != null) {
      if (nuevoIdConf == 29 || nuevoIdConf == 135) {
        nuevoTriage = 'Rojo';
      } else if (nuevoIdConf == 30) {
        nuevoTriage = 'Amarillo';
      } else if (nuevoIdConf == 31) {
        nuevoTriage = 'Verde';
      } else if (nuevoIdConf == 63) {
        nuevoTriage = 'Sin código';
      }
    }

    _incidenteActual = _incidenteActual.copyWith(
      direccion: direccion,
      idLocalidad: idLocalidad,
      latitud: latitud,
      longitud: longitud,
      direccionAuto: direccionAuto,
      descripcion: descripcion,
      idConfCodigo: nuevoIdConf,
      clearIdConfCodigo: esSinCodigo && nuevoIdConf == null,
      codigoTriage: nuevoTriage,
      clearCodigoTriage: esSinCodigo && nuevoTriage == null,
      protocolosIds: protocolosIds,
    );

    if (nuevoTriage != null && nuevoTriage.toLowerCase() == 'rojo') {
      for (var v in _victimas) {
        if (v.codigoTriage == null || v.codigoTriage!.isEmpty) {
          v.codigoTriage = 'Rojo';
        }
      }
    }

    _sincronizarSocketRoom();
    _guardarBorrador();
    notifyListeners();

    // La dirección y coordenadas se sincronizan explícitamente al buscar la dirección en el mapa (Enter / Ver en el mapa).
    // Si se pide syncInmediato (ej. al marcar o desmarcar etiquetas) o por cambios con debouncer:
    if (syncInmediato && _incidenteActual.idIncidente != null && !fromSocket) {
      if (_debounceIncidenteTimer?.isActive ?? false) {
        _debounceIncidenteTimer!.cancel();
      }
      syncIncidenteDesdeGoogleMaps();
    } else if (!fromSocket && (descripcion != null || codigoTriage != null || clearCodigo || idConfCodigo != null)) {
      _programarGuardadoRemotoIncidente();
    }
  }

  void _programarGuardadoRemoto() {
    // Si aún no tenemos un incidente creado en el backend, no programar guardado de demanda
    if (_incidenteActual.idIncidente == null) {
      return;
    }

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      await _sincronizarConBackend();
    });
  }

  void _programarGuardadoRemotoIncidente() {
    // NUNCA sincronizar un incidente nuevo o cambios de dirección por debouncer automático.
    // Solo sincronizar automáticamente con PUT si el incidente ya existe en el backend (ej. descripción, triage).
    if (_incidenteActual.idIncidente == null) {
      return;
    }

    if (_debounceIncidenteTimer?.isActive ?? false) {
      _debounceIncidenteTimer!.cancel();
    }
    _debounceIncidenteTimer = Timer(const Duration(seconds: 2), () async {
      await syncIncidenteDesdeGoogleMaps();
    });
  }
  
  bool _isSyncingDemanda = false;

  Future<void> _sincronizarConBackend() async {
    if (_isSyncingDemanda) return;

    // Si no tenemos ID de incidente aún, NO se realiza POST de la demanda aislada.
    if (_demandaActual.idIncidente == null && _incidenteActual.idIncidente == null) {
      return;
    }

    final targetIncId = _demandaActual.idIncidente ?? _incidenteActual.idIncidente;
    if (targetIncId == null) return;

    // Verificar que se hayan completado datos reales del llamante (teléfono, nombre o DNI)
    final tieneDatosLlamada = _demandaActual.nroLlamadaEntrante != null ||
        (_demandaActual.apellidoNombre != null && _demandaActual.apellidoNombre!.trim().isNotEmpty) ||
        (_demandaActual.dni != null && _demandaActual.dni!.trim().isNotEmpty);

    if (!tieneDatosLlamada) {
      return; // Evitar POSTs de demandas recibidas vacías/anónimas al ingresar o editar incidentes
    }

    _isSyncingDemanda = true;

    try {
      if (_demandaActual.idDemandaRecibida == null) {
        _demandaActual = _demandaActual.copyWith(idIncidente: targetIncId);

        final creada = await DemandaRecibidaService.crear(_demandaActual);
        if (creada != null && creada.idDemandaRecibida != null) {
          _demandaActual = _demandaActual.copyWith(idDemandaRecibida: creada.idDemandaRecibida);
          await _guardarBorrador();
          notifyListeners();
        }
      } else {
        // Es un PUT de una demanda previamente guardada
        await DemandaRecibidaService.actualizar(_demandaActual);
      }
    } finally {
      _isSyncingDemanda = false;
    }
  }

  bool _isSyncingIncidente = false;

  /// Se llama explícitamente al buscar la dirección en el mapa (Enter o "Ver en el mapa") o al tocar un punto en el mapa.
  /// Hace POST si es un incidente nuevo o PUT si ya existe.
  Future<void> syncIncidenteDesdeGoogleMaps() async {
    if (_isSyncingIncidente) return;
    _isSyncingIncidente = true;

    try {
      if (_debounceIncidenteTimer?.isActive ?? false) {
        _debounceIncidenteTimer!.cancel();
      }

      final tieneUbicacionValida = (_incidenteActual.direccion != null && _incidenteActual.direccion!.trim().isNotEmpty) ||
          (_incidenteActual.direccionAuto != null && _incidenteActual.direccionAuto!.trim().isNotEmpty) ||
          _incidenteActual.latitud != null;

      if (!tieneUbicacionValida && _incidenteActual.idIncidente == null) {
        return; // No crear incidente sin ubicación
      }

      if (_incidenteActual.idIncidente == null) {
        final creado = await IncidenteService.crear(_incidenteActual);
        if (creado != null && creado.idIncidente != null) {
          _incidenteActual = _incidenteActual.copyWith(idIncidente: creado.idIncidente);
          _sincronizarSocketRoom();
          
          // Vinculamos el incidente con la demanda
          _demandaActual = _demandaActual.copyWith(idIncidente: creado.idIncidente);
          await _guardarBorrador();
          notifyListeners();

          // Cancelamos cualquier debouncer de demanda pendiente para evitar duplicados
          _debounceTimer?.cancel();

          // Sincronizamos la demanda (POST) usando el flujo centralizado y protegido
          await _sincronizarConBackend();
        }
      } else {
        await IncidenteService.actualizar(_incidenteActual);
        _sincronizarSocketRoom();
        if (_demandaActual.idIncidente != _incidenteActual.idIncidente) {
          _demandaActual = _demandaActual.copyWith(idIncidente: _incidenteActual.idIncidente);
          _programarGuardadoRemoto();
        }
      }
    } finally {
      _isSyncingIncidente = false;
    }
  }

  List<VictimaData> _victimas = [VictimaData()];
  List<VictimaData> get victimas => _victimas;

  int _selectedVictimaIndex = 0;
  int get selectedVictimaIndex => _selectedVictimaIndex;
  set selectedVictimaIndex(int value) {
    if (value >= 0 && value < _victimas.length) {
      if (_selectedVictimaIndex != value) {
        releaseVictimaLock();
      }
      _selectedVictimaIndex = value;
      notifyListeners();
    }
  }

  Timer? _victimLockDebounce;
  int? _activeLockedVictimaIndex;

  void lockVictima(int index) {
    if (_incidenteActual.idIncidente == null) return;
    _victimLockDebounce?.cancel();
    if (_activeLockedVictimaIndex != index) {
      if (_activeLockedVictimaIndex != null) {
        SocketService().unlockField('victima_$_activeLockedVictimaIndex');
      }
      _activeLockedVictimaIndex = index;
      SocketService().lockField('victima_$index');
    }
  }

  void scheduleUnlockVictima(int index, {Duration delay = const Duration(seconds: 2)}) {
    if (_incidenteActual.idIncidente == null) return;
    _victimLockDebounce?.cancel();
    _victimLockDebounce = Timer(delay, () {
      if (_activeLockedVictimaIndex == index) {
        SocketService().unlockField('victima_$index');
        _activeLockedVictimaIndex = null;
      }
    });
  }

  void cancelUnlockVictima() {
    _victimLockDebounce?.cancel();
  }

  void releaseVictimaLock() {
    _victimLockDebounce?.cancel();
    if (_activeLockedVictimaIndex != null) {
      SocketService().unlockField('victima_$_activeLockedVictimaIndex');
      _activeLockedVictimaIndex = null;
    }
  }

  bool get esIncidenteRojo {
    final triage = _incidenteActual.codigoTriage?.toLowerCase();
    if (triage != null && triage.contains('sin')) return false;
    final code = _incidenteActual.idConfCodigo;
    if (code == 63) return false;
    return triage == 'rojo' ||
        code == 29 ||
        code == 135 ||
        protocolosSeleccionados.isNotEmpty;
  }

  void _asegurarTriageRojoVictimas() {
    if (esIncidenteRojo) {
      for (var v in _victimas) {
        if (v.codigoTriage == null || v.codigoTriage!.isEmpty) {
          v.codigoTriage = 'Rojo';
        }
      }
    }
  }

  void addVictima({bool emitirSocket = true}) {
    final nueva = VictimaData();
    if (esIncidenteRojo) {
      nueva.codigoTriage = 'Rojo';
    }
    _victimas.add(nueva);
    _selectedVictimaIndex = _victimas.length - 1;
    _registrarOyentesParaVictimaIndex(_selectedVictimaIndex);
    if (emitirSocket) {
      SocketService().updateField('victimas_action', 'add');
    }
    _guardarBorrador();
    notifyListeners();
  }

  void updateTodasLasVictimas({required String codigoTriage, bool emitirSocket = true}) {
    for (int i = 0; i < _victimas.length; i++) {
      _victimas[i].codigoTriage = codigoTriage;
      if (emitirSocket) {
        SocketService().updateField('victima_${i}_triage', codigoTriage);
      }
      if (_victimas[i].idVictima != null && (_victimas[i].nombre.trim().isNotEmpty || _victimas[i].dni.trim().isNotEmpty)) {
        _programarSyncVictima(_victimas[i]);
      }
    }
    _guardarBorrador();
    notifyListeners();
  }

  void removeVictima(int index, {bool emitirSocket = true}) {
    if (_victimas.length > 1) {
      _victimas.removeAt(index);
      if (_selectedVictimaIndex >= _victimas.length) {
        _selectedVictimaIndex = _victimas.length - 1;
      }
      _registrarOyentesSocketVictimas();
      if (emitirSocket) {
        SocketService().updateField('victimas_action', 'remove:$index');
      }
      notifyListeners();
    }
  }

  Timer? _uiNameDebounce;

  void updateVictima(int index, {
    String? nombre,
    String? edad,
    int? idConfGenero,
    String? dni,
    String? codigoTriage,
    List<String>? sintomas,
    String? observaciones,
    bool emitirSocket = true,
  }) {
    if (index >= 0 && index < _victimas.length) {
      final v = _victimas[index];
      bool shouldNotifyImmediately = true;

      if (nombre != null) {
        v.nombre = nombre;
        if (emitirSocket) {
          shouldNotifyImmediately = false;
          _uiNameDebounce?.cancel();
          _uiNameDebounce = Timer(const Duration(seconds: 2), () {
            notifyListeners();
          });
          SocketService().updateField('victima_${index}_nombre', nombre);
        } else {
          shouldNotifyImmediately = true;
        }
      }
      if (edad != null) {
        v.edad = edad;
        if (emitirSocket) {
          SocketService().updateField('victima_${index}_edad', edad);
        }
      }
      if (idConfGenero != null) {
        v.idConfGenero = idConfGenero;
        if (emitirSocket) {
          SocketService().updateField('victima_${index}_genero', idConfGenero.toString());
        }
      }
      if (dni != null) {
        v.dni = dni;
        if (emitirSocket) {
          SocketService().updateField('victima_${index}_dni', dni);
        }
      }
      if (codigoTriage != null) {
        v.codigoTriage = codigoTriage;
        if (emitirSocket) {
          SocketService().updateField('victima_${index}_triage', codigoTriage);
        }
      }
      if (sintomas != null) {
        v.sintomasSeleccionados = sintomas;
        if (emitirSocket) {
          SocketService().updateField('victima_${index}_sintomas', sintomas.join(','));
        }
      }
      if (observaciones != null) {
        v.observaciones = observaciones;
        if (emitirSocket) {
          SocketService().updateField('victima_${index}_observaciones', observaciones);
        }
      }
      
      if (shouldNotifyImmediately) {
        notifyListeners();
      }
      if (emitirSocket) {
        _programarSyncVictima(v);
      }
    }
  }

  final Map<String, Timer> _victimaSyncTimers = {};

  void _programarSyncVictima(VictimaData v) {
    _victimaSyncTimers[v.id]?.cancel();
    _victimaSyncTimers[v.id] = Timer(const Duration(seconds: 2), () async {
      await _sincronizarVictima(v);
    });
  }

  Future<void> _sincronizarVictima(VictimaData victima) async {
    final payload = victima.toVictima(_incidenteActual.idIncidente);
    if (victima.idVictima == null) {
      if (victima.nombre.trim().isEmpty && victima.dni.trim().isEmpty) return;
      final creada = await VictimaService.crear(payload);
      if (creada != null && creada.idVictima != null) {
        victima.idVictima = creada.idVictima;
        notifyListeners();
      }
    } else {
      await VictimaService.actualizar(payload);
    }
  }

  Future<void> cargarIncidenteDirecto(Map<String, dynamic> rawMap) async {
    _vistaFormulario = true;
    _selectedVictimaIndex = 0;

    Map<String, dynamic> incData = rawMap;
    if (rawMap.containsKey('incidente') && rawMap['incidente'] is Map) {
      incData = rawMap['incidente'];
    }

    final idInc = (rawMap['idincidente'] ?? incData['idincidente'] ?? rawMap['iddemandarecibida'])?.toString();
    final int? idIncidente = idInc != null ? int.tryParse(idInc) : null;

    _incidenteActual = Incidente.fromJson(incData);
    if (_incidenteActual.idIncidente == null && idIncidente != null) {
      _incidenteActual = _incidenteActual.copyWith(idIncidente: idIncidente);
    }

    if (_incidenteActual.victimas != null && _incidenteActual.victimas!.isNotEmpty) {
      _victimas = _incidenteActual.victimas!.map((v) => VictimaData.fromVictima(v)).toList();
    } else {
      _victimas = [VictimaData()];
    }
    _asegurarTriageRojoVictimas();

    if (rawMap.containsKey('iddemandarecibida') || rawMap.containsKey('nro_llamada_entrante')) {
      _demandaActual = DemandaRecibida.fromJson(rawMap);
    } else {
      _demandaActual = DemandaRecibida(
        idCfgEstado: 5,
        idIncidente: idIncidente,
        incidente: _incidenteActual,
        fechaHora: DateTime.now(),
      );
    }

    _sincronizarSocketRoom();
    _guardarBorrador();
    notifyListeners();

    // Sincronizar el paso del incidente inmediatamente (utilizando hint de la llamada/Kanban)
    actualizarPasoIncidente(rawMapHint: rawMap);

    // Carga diferida (Lazy loading) de los datos profundos del incidente (víctimas, novedades, despachos) en segundo plano
    if (idIncidente != null) {
      _cargarDatosDiferidosIncidente(idIncidente);
    }
  }

  Future<void> _cargarDatosDiferidosIncidente(int idIncidente) async {
    try {
      final incidenteCompleto = await IncidenteService.obtenerPorId(idIncidente);
      if (incidenteCompleto != null) {
        _incidenteActual = incidenteCompleto;
        if (incidenteCompleto.victimas != null && incidenteCompleto.victimas!.isNotEmpty) {
          _victimas = incidenteCompleto.victimas!.map((v) => VictimaData.fromVictima(v)).toList();
          _asegurarTriageRojoVictimas();
        }
        _demandaActual = _demandaActual.copyWith(incidente: _incidenteActual);
        _sincronizarSocketRoom();
      }

      final llamadas = await DemandaRecibidaService.obtenerTodasPorIncidente(idIncidente);
      _llamadasDelIncidente = llamadas;
      await _guardarBorrador();
      notifyListeners();

      // Refrescar el paso con los datos profundos (despachos de víctimas)
      await actualizarPasoIncidente();
    } catch (e) {
      debugPrint('[IngresoController] Error en carga diferida de incidente: $e');
    }
  }

  Future<void> cargarDemanda(DemandaRecibida demanda) async {
    _demandaActual = demanda;
    _selectedVictimaIndex = 0; 
    _vistaFormulario = true;
    if (demanda.incidente != null) {
      _incidenteActual = demanda.incidente!;
      if (demanda.incidente!.victimas != null && demanda.incidente!.victimas!.isNotEmpty) {
        _victimas = demanda.incidente!.victimas!.map((v) => VictimaData.fromVictima(v)).toList();
      } else {
        _victimas = [VictimaData()];
      }
    } else {
      _incidenteActual = Incidente(idLocalidad: 580056);
      _victimas = [VictimaData()];
    }
    _asegurarTriageRojoVictimas();
    _llamadasDelIncidente = [demanda];
    _sincronizarSocketRoom();
    _guardarBorrador();
    notifyListeners();

    // Sincronizar paso inicial según demanda
    actualizarPasoIncidente();

    // Carga diferida (Lazy loading) de los datos profundos del incidente por ID
    final idDemanda = demanda.idDemandaRecibida;
    final idIncidente = demanda.incidente?.idIncidente ?? demanda.idIncidente;
    if (idDemanda != null || idIncidente != null) {
      DemandaRecibida? completa;
      if (idDemanda != null) {
        completa = await DemandaRecibidaService.obtenerPorId(idDemanda);
      }
      completa ??= idIncidente != null ? await DemandaRecibidaService.obtenerPorIncidente(idIncidente) : null;

      if (completa != null) {
        _demandaActual = completa;
        if (completa.incidente != null) {
          _incidenteActual = completa.incidente!;
          if (completa.incidente!.victimas != null && completa.incidente!.victimas!.isNotEmpty) {
            _victimas = completa.incidente!.victimas!.map((v) => VictimaData.fromVictima(v)).toList();
            _asegurarTriageRojoVictimas();
          }
        }
        _guardarBorrador();
        notifyListeners();
        await actualizarPasoIncidente();
      }
    }
  }

  void cargarIncidenteYListarLlamadas(DemandaRecibida demandaConIncidente, List<DemandaRecibida> llamadas) {
    _vistaFormulario = true;
    // Vincular la llamada actual al incidente seleccionado sin sobrescribir los datos de ingreso
    _demandaActual = _demandaActual.copyWith(
      idIncidente: demandaConIncidente.incidente?.idIncidente ?? demandaConIncidente.idIncidente,
      incidente: demandaConIncidente.incidente,
      idDemandaRecibida: null, // Se trata de una nueva llamada para este incidente
    );
    
    _llamadasDelIncidente = llamadas;
    _selectedVictimaIndex = 0;

    if (demandaConIncidente.incidente != null) {
      _incidenteActual = demandaConIncidente.incidente!;
      if (demandaConIncidente.incidente!.victimas != null && demandaConIncidente.incidente!.victimas!.isNotEmpty) {
        _victimas = demandaConIncidente.incidente!.victimas!.map((v) => VictimaData.fromVictima(v)).toList();
      } else {
        _victimas = [VictimaData()];
      }
    } else {
      _incidenteActual = Incidente(idLocalidad: 580056);
      _victimas = [VictimaData()];
    }
    _asegurarTriageRojoVictimas();
    
    _sincronizarSocketRoom();
    _guardarBorrador();
    notifyListeners();
    actualizarPasoIncidente();
  }

  bool _isActualizandoPaso = false;

  /// Calcula y actualiza el paso del incidente (0: Incidente, 1: Despacho, 2: En sitio, 3: Traslado, 4: Fin, 5: Cierre)
  Future<void> actualizarPasoIncidente({Map<String, dynamic>? rawMapHint}) async {
    if (_isActualizandoPaso) return;
    _isActualizandoPaso = true;
    try {
      final idIncidente = _incidenteActual.idIncidente ?? _demandaActual.idIncidente;

      int pasoCalculado = 0;

    // Si el incidente está cerrado
    if (_incidenteActual.activo == 0 ||
        _demandaActual.idCfgEstado == 7 ||
        _demandaActual.idCfgEstado == 8) {
      pasoCalculado = _demandaActual.idCfgEstado == 8 ? 4 : 5;
    }

    final List<String> estadosDetectados = [];

    // 1. Detección rápida desde rawMapHint (útil al navegar desde Listados / Kanban)
    if (rawMapHint != null) {
      if (rawMapHint['moviles'] is List) {
        for (var m in (rawMapHint['moviles'] as List)) {
          if (m is Map && m['status'] != null) {
            estadosDetectados.add(m['status'].toString());
          }
        }
      }
      final incHint = rawMapHint['incidente'] is Map ? rawMapHint['incidente'] : rawMapHint;
      if (incHint is Map && incHint['victimas'] is List) {
        for (var v in (incHint['victimas'] as List)) {
          if (v is Map && v['despachos'] is List) {
            for (var d in (v['despachos'] as List)) {
              if (d is Map && (d['activo'] == 1 || d['activo'] == '1' || d['activo'] == true)) {
                estadosDetectados.add('Despachado');
              }
            }
          }
        }
      }
    }

    // 2. Detección desde los móviles en memoria de DespachoController
    try {
      final despController = DespachoController();
      if (idIncidente != null) {
        final movilesAsignados = despController.moviles.where((m) =>
          m.idIncidenteActivo == idIncidente ||
          (m.idIncidenteActivo != null && m.idIncidenteActivo.toString() == idIncidente.toString())
        ).toList();

        for (var m in movilesAsignados) {
          estadosDetectados.add(m.estado);
        }
      }
    } catch (_) {}

    // 3. Detección desde las víctimas del incidente actual
    if (_incidenteActual.victimas != null) {
      for (var vic in _incidenteActual.victimas!) {
        if (vic.idMovilAsignado != null && vic.idMovilAsignado!.trim().isNotEmpty) {
          estadosDetectados.add('Despachado');
        }
        if (vic.idDespacho != null) {
          estadosDetectados.add('Despachado');
        }
      }
    }

    // 4. Detección directa desde los despachos expandidos del incidente
    if (_incidenteActual.despachos != null && _incidenteActual.despachos!.isNotEmpty) {
      for (var d in _incidenteActual.despachos!) {
        if (d is Map) {
          final act = d['activo'];
          // Solo despachos activos (activo == 1), ignorar cancelados (activo == 2)
          if (act == 1 || act == '1' || act == true) {
            estadosDetectados.add('Despachado');
            if (d['movilunidad'] is Map && d['movilunidad']['movil'] is Map) {
              final mData = d['movilunidad']['movil'];
              if (mData['estado'] != null) {
                estadosDetectados.add(mData['estado'].toString());
              }
            }
          }
        }
      }
    }

    // 5. Detección desde último estado del incidente si existe
    if (_incidenteActual.ultimoEstadoRel != null) {
      final uRel = _incidenteActual.ultimoEstadoRel!;
      final estRel = uRel['estadoRel'] ?? uRel['estado_rel'];
      if (estRel is Map && estRel['descripcion'] != null) {
        estadosDetectados.add(estRel['descripcion'].toString());
      }
    }

    // 6. Demanda en estado 6 (Despachado)
    if (_demandaActual.idCfgEstado == 6) {
      estadosDetectados.add('Despachado');
    }

    pasoCalculado = _calcularPasoDesdeEstados(estadosDetectados, pasoCalculado);
    _pasoIncidente = pasoCalculado;
    notifyListeners();

    // 5. Consulta asíncrona de despachos en backend en tiempo real
    if (idIncidente != null) {
      try {
        final despachosBackend = await DespachoService.obtenerPorIncidente(idIncidente);
        _despachosActivos = despachosBackend;

        if (despachosBackend.isNotEmpty) {
          for (var d in despachosBackend) {
            estadosDetectados.add('Despachado');
            if (d['movilunidad'] is Map && d['movilunidad']['movil'] is Map) {
              final mData = d['movilunidad']['movil'];
              if (mData['estado'] != null) {
                estadosDetectados.add(mData['estado'].toString());
              }
            }
          }
          final nuevoPaso = _calcularPasoDesdeEstados(estadosDetectados, _pasoIncidente);
          if (nuevoPaso != _pasoIncidente) {
            _pasoIncidente = nuevoPaso;
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('[IngresoController] Error al verificar despachos del incidente: $e');
      }
    }
    } finally {
      _isActualizandoPaso = false;
    }
  }

  int _calcularPasoDesdeEstados(List<String> estados, int pasoBase) {
    int maxPaso = pasoBase;

    for (var est in estados) {
      final e = est.trim().toLowerCase();
      if (e == 'cierre' || e == 'cerrado') {
        if (maxPaso < 5) maxPaso = 5;
      } else if (e == 'fin' || e == 'finalizado' || e == 'arribado' || e == 'arribado destino' || e == 'base') {
        if (maxPaso < 4) maxPaso = 4;
      } else if (e == 'traslado' || e == 'en traslado' || e == 'en_traslado') {
        if (maxPaso < 3) maxPaso = 3;
      } else if (e == 'en sitio' || e == 'en_sitio' || e == 'en escena' || e == 'arribado escena' || e == 'arribado_escena') {
        if (maxPaso < 2) maxPaso = 2;
      } else if (e == 'despachado' || e == 'despacho' || e == 'en camino' || e == 'en_camino' || e == 'en transito' || e == 'asignado') {
        if (maxPaso < 1) maxPaso = 1;
      }
    }
    return maxPaso;
  }
}
