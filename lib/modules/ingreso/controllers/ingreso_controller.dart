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
import '../../../shared/models/victima.dart';
import '../../../shared/services/socket_service.dart';

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

  bool _tieneBorrador = false;
  bool get tieneBorrador => _tieneBorrador;

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

  Future<void> _cargarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    final incDraftJson = prefs.getString(_incidenteDraftKey);
    
    _tieneBorrador = (draftJson != null || incDraftJson != null);

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
    
    notifyListeners();
  }

  Future<void> _guardarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(_demandaActual.toJson()));
    await prefs.setString(_incidenteDraftKey, jsonEncode(_incidenteActual.toJson()));
    if (!_tieneBorrador) {
      _tieneBorrador = true;
      notifyListeners();
    }
  }

  Future<void> limpiarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_incidenteDraftKey);
    await prefs.remove('novedades_draft');
    _demandaActual = DemandaRecibida(idCfgEstado: 5);
    _incidenteActual = Incidente(idLocalidad: 580056);
    _victimas = [VictimaData()];
    _selectedVictimaIndex = 0;
    _llamadasDelIncidente = [];
    _tieneBorrador = false;
    _sincronizarSocketRoom();
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
  }) {
    _incidenteActual = _incidenteActual.copyWith(
      direccion: direccion,
      idLocalidad: idLocalidad,
      latitud: latitud,
      longitud: longitud,
      direccionAuto: direccionAuto,
      descripcion: descripcion,
      codigoTriage: codigoTriage,
    );

    _sincronizarSocketRoom();
    _guardarBorrador();
    notifyListeners();
    // Si viene descripcion, también programar sync del incidente
    if (descripcion != null) {
      _programarGuardadoRemotoIncidente();
    }
  }

  void _programarGuardadoRemoto() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      await _sincronizarConBackend();
    });
  }

  void _programarGuardadoRemotoIncidente() {
    if (_debounceIncidenteTimer?.isActive ?? false) {
      _debounceIncidenteTimer!.cancel();
    }
    _debounceIncidenteTimer = Timer(const Duration(seconds: 2), () async {
      await syncIncidenteDesdeGoogleMaps();
    });
  }

  Future<void> _sincronizarConBackend() async {
    // Si no tenemos ID, es un POST
    if (_demandaActual.idDemandaRecibida == null) {
      // Evitar POST vacíos, al menos debe tener un tipo de ingreso, o nombre, o telefono
      if (_demandaActual.idCfgTipoIngreso != null || 
          _demandaActual.nroLlamadaEntrante != null || 
          _demandaActual.apellidoNombre != null) {
        
        final creada = await DemandaRecibidaService.crear(_demandaActual);
        if (creada != null && creada.idDemandaRecibida != null) {
          _demandaActual = _demandaActual.copyWith(idDemandaRecibida: creada.idDemandaRecibida);
          await _guardarBorrador();
          notifyListeners();
        }
      }
    } else {
      // Es un PUT
      await DemandaRecibidaService.actualizar(_demandaActual);
    }

    // Sincronizar Incidente (NO se dispara desde el debounce, solo desde Google Maps)
  }

  /// Se llama únicamente cuando el usuario confirma una ubicación desde el mapa
  /// (tap en el mapa o link de WhatsApp). Hace POST si es nuevo o PUT si ya existe.
  Future<void> syncIncidenteDesdeGoogleMaps() async {
    if (_incidenteActual.latitud == null || _incidenteActual.longitud == null) return;

    if (_incidenteActual.idIncidente == null) {
      final creado = await IncidenteService.crear(_incidenteActual);
      if (creado != null && creado.idIncidente != null) {
        _incidenteActual = _incidenteActual.copyWith(idIncidente: creado.idIncidente);
        _sincronizarSocketRoom();
        // Vinculamos el incidente con la demanda
        _demandaActual = _demandaActual.copyWith(idIncidente: creado.idIncidente);
        await _guardarBorrador();
        notifyListeners();
        // Disparamos la sincronización de la demanda para que guarde el idincidente
        _programarGuardadoRemoto();
      }
    } else {
      await IncidenteService.actualizar(_incidenteActual);
      _sincronizarSocketRoom();
      if (_demandaActual.idIncidente != _incidenteActual.idIncidente) {
        _demandaActual = _demandaActual.copyWith(idIncidente: _incidenteActual.idIncidente);
        _programarGuardadoRemoto();
      }
    }
  }

  List<VictimaData> _victimas = [VictimaData()];
  List<VictimaData> get victimas => _victimas;

  int _selectedVictimaIndex = 0;
  int get selectedVictimaIndex => _selectedVictimaIndex;
  set selectedVictimaIndex(int value) {
    if (value >= 0 && value < _victimas.length) {
      _selectedVictimaIndex = value;
      notifyListeners();
    }
  }

  void addVictima({bool emitirSocket = true}) {
    _victimas.add(VictimaData());
    _selectedVictimaIndex = _victimas.length - 1;
    _registrarOyentesParaVictimaIndex(_selectedVictimaIndex);
    if (emitirSocket) {
      SocketService().updateField('victimas_action', 'add');
    }
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
      _programarSyncVictima(v);
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
      if (victima.nombre.isEmpty && victima.dni.isEmpty && victima.idConfGenero == null) return;
      final creada = await VictimaService.crear(payload);
      if (creada != null && creada.idVictima != null) {
        victima.idVictima = creada.idVictima;
        notifyListeners();
      }
    } else {
      await VictimaService.actualizar(payload);
    }
  }

  void cargarDemanda(DemandaRecibida demanda) {
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
    _llamadasDelIncidente = [demanda];
    _sincronizarSocketRoom();
    _guardarBorrador();
    notifyListeners();
  }

  void cargarIncidenteYListarLlamadas(DemandaRecibida demandaConIncidente, List<DemandaRecibida> llamadas) {
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
    
    _sincronizarSocketRoom();
    _guardarBorrador();
    notifyListeners();
  }
}
