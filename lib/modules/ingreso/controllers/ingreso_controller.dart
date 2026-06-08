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

  Timer? _debounceTimer;
  Timer? _debounceIncidenteTimer;
  static const String _draftKey = 'demanda_draft';
  static const String _incidenteDraftKey = 'incidente_draft';

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
    if (draftJson != null) {
      try {
        final decoded = jsonDecode(draftJson);
        _demandaActual = DemandaRecibida.fromJson(decoded);
      } catch (e) {
        print('Error al cargar borrador de demanda: $e');
      }
    }

    final incDraftJson = prefs.getString(_incidenteDraftKey);
    if (incDraftJson != null) {
      try {
        final decoded = jsonDecode(incDraftJson);
        _incidenteActual = Incidente.fromJson(decoded);
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
  }

  Future<void> limpiarBorrador() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    await prefs.remove(_incidenteDraftKey);
    await prefs.remove('novedades_draft');
    _demandaActual = DemandaRecibida(idCfgEstado: 5);
    _incidenteActual = Incidente(idLocalidad: 580056);
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
  }) {
    _incidenteActual = _incidenteActual.copyWith(
      direccion: direccion,
      idLocalidad: idLocalidad,
      latitud: latitud,
      longitud: longitud,
      direccionAuto: direccionAuto,
      descripcion: descripcion,
    );

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
        // Vinculamos el incidente con la demanda
        _demandaActual = _demandaActual.copyWith(idIncidente: creado.idIncidente);
        await _guardarBorrador();
        notifyListeners();
        // Disparamos la sincronización de la demanda para que guarde el idincidente
        _programarGuardadoRemoto();
      }
    } else {
      await IncidenteService.actualizar(_incidenteActual);
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

  void addVictima() {
    _victimas.add(VictimaData());
    _selectedVictimaIndex = _victimas.length - 1;
    notifyListeners();
  }

  void removeVictima(int index) {
    if (_victimas.length > 1) {
      _victimas.removeAt(index);
      if (_selectedVictimaIndex >= _victimas.length) {
        _selectedVictimaIndex = _victimas.length - 1;
      }
      notifyListeners();
    }
  }

  Timer? _uiNameDebounce;

  void updateVictima(int index, {String? nombre, String? edad, int? idConfGenero, String? dni, String? codigoTriage, List<String>? sintomas}) {
    if (index >= 0 && index < _victimas.length) {
      final v = _victimas[index];
      bool shouldNotifyImmediately = true;

      if (nombre != null) {
        v.nombre = nombre;
        shouldNotifyImmediately = false;
        _uiNameDebounce?.cancel();
        _uiNameDebounce = Timer(const Duration(seconds: 2), () {
          notifyListeners();
        });
      }
      if (edad != null) v.edad = edad;
      if (idConfGenero != null) v.idConfGenero = idConfGenero;
      if (dni != null) v.dni = dni;
      if (codigoTriage != null) v.codigoTriage = codigoTriage;
      if (sintomas != null) v.sintomasSeleccionados = sintomas;
      
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
    
    _guardarBorrador();
    notifyListeners();
  }
}
