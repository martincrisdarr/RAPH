import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/demanda_recibida.dart';
import '../../../shared/services/demanda_recibida_service.dart';
import '../../../shared/models/incidente.dart';
import '../../../shared/services/incidente_service.dart';
import '../../../shared/models/victima_data.dart';
import '../../../shared/models/victima_despacho_resumen.dart';
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
    SocketService().registerFieldListener('despacho_actualizado', (raw) {
      _handleDespachoActualizadoSocket(raw);
    });
  }

  DemandaRecibida _demandaActual = DemandaRecibida(idCfgEstado: 5);
  DemandaRecibida get demandaActual => _demandaActual;

  Incidente _incidenteActual = Incidente(idLocalidad: 580056);
  Incidente get incidenteActual => _incidenteActual;

  int _pasoIncidente = 0;
  int get pasoIncidente => _pasoIncidente;

  List<Map<String, dynamic>> _despachosActivos = [];
  List<Map<String, dynamic>> get despachosActivos => _despachosActivos;

  List<VictimaDespachoResumen> get resumenDespachosVictimas {
    final List<VictimaDespachoResumen> items = [];
    final Set<int> usedDespachoIds = {};

    for (int i = 0; i < _victimas.length; i++) {
      final vic = _victimas[i];
      final number = i + 1;

      Map<String, dynamic>? dMatch;

      // 1. Por idvictima explícito
      if (vic.idVictima != null) {
        for (final d in _despachosActivos.reversed) {
          final dVic = int.tryParse(d['idvictima']?.toString() ?? '');
          if (dVic == vic.idVictima) {
            dMatch = d;
            break;
          }
        }
      }

      // 2. Por idMovilAsignado
      if (dMatch == null && vic.idMovilAsignado != null && vic.idMovilAsignado!.isNotEmpty) {
        for (final d in _despachosActivos.reversed) {
          final dM = (d['idmovil'] ?? d['idmovilunidad'])?.toString();
          if (dM == vic.idMovilAsignado) {
            dMatch = d;
            break;
          }
        }
      }

      // 3. Si solo hay 1 víctima y despachos disponibles
      if (dMatch == null && _victimas.length == 1 && _despachosActivos.isNotEmpty) {
        dMatch = _despachosActivos.last;
      }

      // 4. Emparejar por orden si quedan despachos no asociados explícitamente
      if (dMatch == null && _despachosActivos.isNotEmpty) {
        for (final d in _despachosActivos) {
          final dId = int.tryParse(d['iddespacho']?.toString() ?? '');
          if (dId != null && !usedDespachoIds.contains(dId)) {
            final dVic = int.tryParse(d['idvictima']?.toString() ?? '');
            if (dVic == null || dVic == vic.idVictima) {
              dMatch = d;
              break;
            }
          }
        }
      }

      int? dId;
      if (dMatch != null) {
        dId = int.tryParse(dMatch['iddespacho']?.toString() ?? '');
        if (dId != null) usedDespachoIds.add(dId);
      }

      // Triage
      final triageVictima = vic.codigoTriage?.trim();
      final triageIncidente = _incidenteActual.codigoTriage?.trim();
      final idConfCodigoIncidente = _incidenteActual.idConfCodigo;
      final tieneProt = protocolosSeleccionados.isNotEmpty;

      String? effectiveTriage = (triageVictima != null && triageVictima.isNotEmpty) ? triageVictima : null;
      if (effectiveTriage == null) {
        if (tieneProt || idConfCodigoIncidente == 29 || idConfCodigoIncidente == 135 || triageIncidente?.toLowerCase() == 'rojo') {
          effectiveTriage = 'Rojo';
        } else if (idConfCodigoIncidente == 30 || triageIncidente?.toLowerCase() == 'amarillo') {
          effectiveTriage = 'Amarillo';
        } else if (idConfCodigoIncidente == 31 || triageIncidente?.toLowerCase() == 'verde') {
          effectiveTriage = 'Verde';
        } else if (idConfCodigoIncidente == 63 || (triageIncidente != null && triageIncidente.toLowerCase().contains('sin'))) {
          effectiveTriage = 'Sin código';
        }
      }

      // Móvil y Estado operativo
      String? movilNombre;
      String? idMovil;
      String estadoOp = 'sin_despacho';
      String? hospitalNombre;
      bool isFinalizado = false;
      int paso = 0;

      if (dMatch != null) {
        idMovil = (dMatch['idmovil'] ?? dMatch['idmovilunidad'])?.toString();
        hospitalNombre = dMatch['hospital_nombre']?.toString();

        if (dMatch['movilunidad'] is Map) {
          final mu = dMatch['movilunidad'] as Map;
          if (mu['movil'] is Map && mu['movil']['nombre'] != null) {
            movilNombre = mu['movil']['nombre'].toString();
          } else if (mu['patente'] != null) {
            movilNombre = 'Unidad ${mu['patente']}';
          }
        }
        movilNombre ??= dMatch['movil_nombre']?.toString() ?? (idMovil != null ? 'Móvil $idMovil' : 'Móvil asignado');

        final act = dMatch['activo'];
        final rawEst = (dMatch['estado_operativo'] ?? dMatch['estado'] ?? 'despachado').toString().trim().toLowerCase();

        estadoOp = rawEst;

        if (rawEst == 'finalizado' || rawEst == 'en_hospital' || rawEst == 'fin' || rawEst == 'arribado' || rawEst == 'base' ||
            ((act == 0 || act == '0' || act == false) && rawEst == 'finalizado')) {
          paso = 4;
          isFinalizado = true;
          estadoOp = 'finalizado';
        } else if (rawEst == 'traslado' || rawEst == 'en_traslado' || rawEst == 'en traslado') {
          paso = 3;
          isFinalizado = false;
        } else if (rawEst == 'en_sitio' || rawEst == 'en sitio' || rawEst == 'en escena' || rawEst == 'arribado escena' || rawEst == 'arribado_escena') {
          paso = 2;
          isFinalizado = false;
        } else if (rawEst == 'despachado' || rawEst == 'despacho' || rawEst == 'en camino' || rawEst == 'en_camino' || rawEst == 'asignado') {
          paso = 1;
          isFinalizado = false;
        } else {
          paso = 1;
          isFinalizado = false;
        }
      } else if (vic.idMovilAsignado != null && vic.idMovilAsignado!.isNotEmpty) {
        idMovil = vic.idMovilAsignado;
        movilNombre = 'Móvil $idMovil';
        estadoOp = 'despachado';
        paso = 1;
      }

      final nombreCompleto = vic.nombre.trim();
      final nombreDisplay = nombreCompleto.isNotEmpty ? nombreCompleto : 'Víctima $number';

      items.add(VictimaDespachoResumen(
        index: number,
        idVictima: vic.idVictima,
        nombre: nombreDisplay,
        triage: effectiveTriage,
        movilNombre: movilNombre,
        idMovil: idMovil,
        estadoOperativo: estadoOp,
        hospitalNombre: hospitalNombre,
        isFinalizado: isFinalizado,
        paso: paso,
        idDespacho: dId,
      ));
    }

    // Unidades adicionales asignadas al incidente que no correspondan a una víctima puntual
    for (final d in _despachosActivos) {
      final dId = int.tryParse(d['iddespacho']?.toString() ?? '');
      if (dId != null && !usedDespachoIds.contains(dId)) {
        usedDespachoIds.add(dId);
        final idM = (d['idmovil'] ?? d['idmovilunidad'])?.toString();
        String? mNom;
        if (d['movilunidad'] is Map) {
          final mu = d['movilunidad'] as Map;
          if (mu['movil'] is Map && mu['movil']['nombre'] != null) {
            mNom = mu['movil']['nombre'].toString();
          }
        }
        mNom ??= d['movil_nombre']?.toString() ?? (idM != null ? 'Móvil $idM' : 'Móvil');

        final act = d['activo'];
        final rawEst = (d['estado_operativo'] ?? d['estado'] ?? 'despachado').toString().trim().toLowerCase();
        int paso = 1;
        bool isFin = false;
        if (rawEst == 'finalizado' || rawEst == 'en_hospital' || ((act == 0 || act == '0' || act == false) && rawEst == 'finalizado')) {
          paso = 4;
          isFin = true;
        } else if (rawEst.contains('traslado')) {
          paso = 3;
        } else if (rawEst.contains('sitio') || rawEst.contains('escena')) {
          paso = 2;
        }

        items.add(VictimaDespachoResumen(
          index: items.length + 1,
          nombre: 'Apoyo / Unidad extra',
          movilNombre: mNom,
          idMovil: idM,
          estadoOperativo: rawEst,
          hospitalNombre: d['hospital_nombre']?.toString(),
          isFinalizado: isFin,
          paso: paso,
          idDespacho: dId,
        ));
      }
    }

    return items;
  }

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
          _incidenteActual = _incidenteActual.copyWith(
            idIncidente: creado.idIncidente,
            direccion: (_incidenteActual.direccion == null || _incidenteActual.direccion!.trim().isEmpty)
                ? creado.direccion
                : _incidenteActual.direccion,
            direccionAuto: creado.direccionAuto ?? _incidenteActual.direccionAuto,
          );
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
      final tieneReporte = _incidenteActual.reporte != null && _incidenteActual.reporte!.trim().isNotEmpty;
      final uEst = int.tryParse((_incidenteActual.ultimoEstadoRel?['estado'] ?? _incidenteActual.ultimoEstadoRel?['idestado'] ?? '').toString());
      _demandaActual = DemandaRecibida(
        idCfgEstado: (tieneReporte || uEst == 7 || _incidenteActual.activo == 0) ? 7 : 5,
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
        final tieneReporte = _incidenteActual.reporte != null && _incidenteActual.reporte!.trim().isNotEmpty;
        final uEst = int.tryParse((_incidenteActual.ultimoEstadoRel?['estado'] ?? _incidenteActual.ultimoEstadoRel?['idestado'] ?? '').toString());
        _demandaActual = _demandaActual.copyWith(
          incidente: _incidenteActual,
          idCfgEstado: (tieneReporte || uEst == 7 || _incidenteActual.activo == 0) ? 7 : _demandaActual.idCfgEstado,
        );
        _sincronizarSocketRoom();
      }

      await _hidratarCierresVictimas(idIncidente);

      final llamadas = await DemandaRecibidaService.obtenerTodasPorIncidente(idIncidente);
      _llamadasDelIncidente = llamadas;
      if (llamadas.any((l) => l.idCfgEstado == 7)) {
        _demandaActual = _demandaActual.copyWith(idCfgEstado: 7);
      }
      await _guardarBorrador();
      notifyListeners();

      // Refrescar el paso con los datos profundos (despachos de víctimas)
      await actualizarPasoIncidente();
    } catch (e) {
      debugPrint('[IngresoController] Error en carga diferida de incidente: $e');
    }
  }

  Future<void> _hidratarCierresVictimas(int idIncidente) async {
    try {
      final cierres = await VictimaService.obtenerCierresPorIncidente(idIncidente);
      if (cierres.isEmpty) return;

      bool changed = false;
      for (final c in cierres) {
        final idVic = int.tryParse(c['idvictima']?.toString() ?? '');
        if (idVic == null) continue;
        final rep = c['reporte']?.toString();
        if (rep == null || rep.trim().isEmpty) continue;

        for (final v in _victimas) {
          if (v.idVictima == idVic) {
            v.reporte = rep;
            v.fechaHoraCierre = c['fechahora_cierre'] != null
                ? DateTime.tryParse(c['fechahora_cierre'].toString())
                : v.fechaHoraCierre;
            v.usuarioCierre = c['usuario_cierre']?.toString() ?? v.usuarioCierre;
            changed = true;
          }
        }
      }
      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[IngresoController] Error al hidratar cierres de víctimas: $e');
    }
  }

  /// Indica si la atención operativa de la víctima en [index] ya finalizó.
  bool isVictimaAtencionFinalizada(int index) {
    if (_pasoIncidente >= 4) return true;
    final resumen = resumenDespachosVictimas;
    if (index < 0 || index >= _victimas.length) return false;
    final v = _victimas[index];
    for (final r in resumen) {
      if ((v.idVictima != null && r.idVictima == v.idVictima) || r.index == index + 1) {
        return r.isFinalizado || r.paso >= 4;
      }
    }
    return false;
  }

  /// Indica si todas las víctimas registradas ya cuentan con su cierre individual.
  bool get todasLasVictimasCerradas {
    if (_victimas.isEmpty) return true;
    return _victimas.every((v) => v.isCerrada);
  }

  /// Cantidad de víctimas que ya tienen su cierre individual completado.
  int get cantidadVictimasCerradas {
    return _victimas.where((v) => v.isCerrada).length;
  }

  /// Registra el cierre individual de una víctima en la tabla ser_sien_dsp_victima_cierre.
  Future<bool> cerrarVictimaIndividual(int index, String reporte, {String? usuario}) async {
    if (index < 0 || index >= _victimas.length) return false;
    final v = _victimas[index];
    final repTrim = reporte.trim();
    if (repTrim.isEmpty) return false;

    int? idInc = _incidenteActual.idIncidente ?? _demandaActual.idIncidente;
    if (idInc == null) {
      final creadoInc = await IncidenteService.crear(_incidenteActual);
      if (creadoInc?.idIncidente != null) {
        idInc = creadoInc!.idIncidente;
        _incidenteActual = _incidenteActual.copyWith(idIncidente: idInc);
      }
    }
    if (idInc == null) return false;

    if (v.idVictima == null) {
      final payload = v.toVictima(idInc);
      final creadaV = await VictimaService.crear(payload);
      if (creadaV?.idVictima != null) {
        v.idVictima = creadaV!.idVictima;
      }
    }
    if (v.idVictima == null) return false;

    final res = await VictimaService.cerrarVictima(
      idVictima: v.idVictima!,
      idIncidente: idInc,
      reporte: repTrim,
      usuario: usuario,
    );

    if (res != null) {
      v.reporte = res['reporte']?.toString() ?? repTrim;
      v.fechaHoraCierre = res['fechahora_cierre'] != null
          ? DateTime.tryParse(res['fechahora_cierre'].toString())
          : DateTime.now();
      v.usuarioCierre = res['usuario_cierre']?.toString() ?? usuario;
      await _guardarBorrador();
      notifyListeners();
      return true;
    }
    return false;
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
        if (idIncidente != null) {
          await _hidratarCierresVictimas(idIncidente);
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

  void _handleDespachoActualizadoSocket(String raw) {
    try {
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        final Map<String, dynamic>? data = decoded is Map<String, dynamic>
            ? decoded
            : (decoded is Map ? Map<String, dynamic>.from(decoded) : null);

        if (data != null) {
          final idInc = int.tryParse((data['idincidente'] ?? data['id_incidente'])?.toString() ?? '');
          final currentInc = _incidenteActual.idIncidente ?? _demandaActual.idIncidente;

          // Si el despacho pertenece al incidente que tenemos actualmente abierto
          if (idInc != null && currentInc != null && idInc == currentInc) {
            final idD = int.tryParse(data['iddespacho']?.toString() ?? '');
            if (idD != null) {
              final idx = _despachosActivos.indexWhere((d) => int.tryParse(d['iddespacho']?.toString() ?? '') == idD);
              if (idx != -1) {
                _despachosActivos[idx] = {
                  ..._despachosActivos[idx],
                  ...data,
                };
              } else {
                _despachosActivos.add(data);
              }

              if (_incidenteActual.despachos != null) {
                final incDespList = List<dynamic>.from(_incidenteActual.despachos!);
                final dIdx = incDespList.indexWhere((d) => d is Map && int.tryParse(d['iddespacho']?.toString() ?? '') == idD);
                if (dIdx != -1) {
                  incDespList[dIdx] = {
                    ...Map<String, dynamic>.from(incDespList[dIdx] as Map),
                    ...data,
                  };
                  _incidenteActual = _incidenteActual.copyWith(despachos: incDespList);
                }
              }
              notifyListeners();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[IngresoController] Error parsing despacho_actualizado socket: $e');
    }
    actualizarPasoIncidente();
  }

  bool _isActualizandoPaso = false;
  bool _pendingActualizarPaso = false;

  /// Calcula y actualiza el paso del incidente respetando todas las víctimas y despachos
  /// (0: Incidente, 1: Despacho, 2: En sitio, 3: Traslado, 4: Fin, 5: Cierre)
  Future<void> actualizarPasoIncidente({Map<String, dynamic>? rawMapHint}) async {
    if (_isActualizandoPaso) {
      _pendingActualizarPaso = true;
      return;
    }
    _isActualizandoPaso = true;
    try {
      final idIncidente = _incidenteActual.idIncidente ?? _demandaActual.idIncidente;

      // 1. Sincronizar despachos desde _incidenteActual si _despachosActivos está vacío
      if (_despachosActivos.isEmpty && _incidenteActual.despachos != null && _incidenteActual.despachos!.isNotEmpty) {
        _despachosActivos = _incidenteActual.despachos!
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }

      // 2. Sincronizar desde rawMapHint (útil al navegar desde Listados / Kanban)
      if (rawMapHint != null) {
        if (rawMapHint['despachos'] is List) {
          final dList = (rawMapHint['despachos'] as List).whereType<Map<String, dynamic>>().toList();
          if (dList.isNotEmpty) {
            _despachosActivos = dList;
          }
        }
      }

      // 3. Cálculo sincrónico con los datos en memoria
      _pasoIncidente = _calcularPasoDesdeResumen(resumenDespachosVictimas, _pasoIncidente);
      notifyListeners();

      // 4. Consulta asíncrona de despachos en backend en tiempo real (incluyendo finalizados)
      if (idIncidente != null) {
        try {
          final despachosBackend = await DespachoService.obtenerPorIncidente(
            idIncidente,
            incluirFinalizados: true,
          );
          if (despachosBackend.isNotEmpty) {
            _despachosActivos = despachosBackend;
            final nuevoPaso = _calcularPasoDesdeResumen(resumenDespachosVictimas, _pasoIncidente);
            if (nuevoPaso != _pasoIncidente) {
              _pasoIncidente = nuevoPaso;
            }
            notifyListeners();
          }
        } catch (e) {
          debugPrint('[IngresoController] Error al verificar despachos del incidente: $e');
        }
      }
    } finally {
      _isActualizandoPaso = false;
      if (_pendingActualizarPaso) {
        _pendingActualizarPaso = false;
        actualizarPasoIncidente();
      }
    }
  }

  Future<void> marcarIncidenteCerrado(String reporte, {String? usuario}) async {
    final repTrim = reporte.trim();
    _incidenteActual = _incidenteActual.copyWith(
      reporte: repTrim,
      ultimoEstadoRel: {'estado': 7, 'idestado': 7},
    );
    _demandaActual = _demandaActual.copyWith(
      idCfgEstado: 7,
      incidente: _incidenteActual,
    );
    _pasoIncidente = 5;
    await _guardarBorrador();
    notifyListeners();
  }

  int _calcularPasoDesdeResumen(List<VictimaDespachoResumen> items, int pasoBase) {
    // 1. Cierre administrativo
    final tieneReporteCierre = _incidenteActual.reporte != null && _incidenteActual.reporte!.trim().isNotEmpty;
    final ultimoEst = int.tryParse((_incidenteActual.ultimoEstadoRel?['estado'] ?? _incidenteActual.ultimoEstadoRel?['idestado'] ?? '').toString());
    if (_incidenteActual.activo == 0 || _demandaActual.idCfgEstado == 7 || tieneReporteCierre || ultimoEst == 7) {
      return 5; // Cierre
    }
    if (_demandaActual.idCfgEstado == 8) {
      return 4; // Fin
    }

    // 2. Si no hay despachos asignados
    final conDespacho = items.where((i) => i.paso > 0).toList();
    if (conDespacho.isEmpty) {
      if (_demandaActual.idCfgEstado == 6) {
        return 1; // Despacho
      }
      return math.max(0, pasoBase);
    }

    // 3. ¿Todos los asignados finalizaron?
    final todosFinalizados = conDespacho.every((i) => i.isFinalizado || i.paso >= 4);
    final hayVictimasSinDespacho = items.any((i) => i.paso == 0);

    // Fin: Únicamente si TODOS los móviles asignados finalizaron y no quedan víctimas desatendidas
    if (todosFinalizados && !hayVictimasSinDespacho) {
      return 4;
    }

    // 4. Si hay móviles activos en curso, el paso global es el más avanzado entre los ACTIVOS
    final activos = conDespacho.where((i) => !i.isFinalizado && i.paso < 4).toList();
    if (activos.isNotEmpty) {
      final maxActivo = activos.map((i) => i.paso).reduce(math.max);
      return maxActivo;
    }

    if (hayVictimasSinDespacho) {
      return 1; // Vuelve a requerir despacho para las demás víctimas
    }

    return 4;
  }
}
