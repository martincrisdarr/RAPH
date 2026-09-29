import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import 'socket_events.dart';

class SocketService {
  // Patrón Singleton
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnecting = false;
  String? _currentToken;

  String? _currentEntidad;
  int? _currentRecordId;

  // Estado reactivo: Mapa de los campos que están bloqueados actualmente
  // Ejemplo: {"telefono": {"id": "ivanb", "nombre": "Ivan Benzaquen"}}
  final ValueNotifier<Map<String, dynamic>> lockedFields = ValueNotifier({});

  // Estado reactivo de conexión
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  void connect(String token) {
    // Si ya estamos conectados o en proceso de conexión con el mismo token, no duplicar conexión
    if (_socket != null && _currentToken == token) {
      if (_socket!.connected || _isConnecting) {
        debugPrint('[SocketService] Ya conectado o en proceso de conexion con el mismo token.');
        return;
      }
    }

    if (_socket != null) {
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }

    _currentToken = token;
    _isConnecting = true;

    final uri = Uri.parse(ApiConfig.socketUrl);
    final baseUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
    final socketPath = '/socket.io'; // Usamos el path root que responde con JSON y no da 404

    debugPrint('[SocketService] Conectando a $baseUrl con path $socketPath');

    _socket = io.io(baseUrl, io.OptionBuilder()
      .setPath(socketPath)
      .setTransports(['polling', 'websocket']) // Permite iniciar por HTTP polling y luego escalar a WebSocket
      .setAuth({'token': token}) // Envío seguro del token (v3/v4)
      .setQuery({'token': token}) // Compatibilidad con handshakes basados en query
      .build());

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Conectado al servidor Socket.IO (socket id: ${_socket?.id})');
      _isConnecting = false;
      isConnected.value = true;

      // Auto re-join a la sala de registro si estaba seteada previamente
      if (_currentEntidad != null && _currentRecordId != null) {
        debugPrint('[SocketService] Auto re-joining record on connect: $_currentEntidad $_currentRecordId');
        _socket?.emit(SocketEvents.clientJoin, {
          'entidad': _currentEntidad,
          'id': _currentRecordId,
        });
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[SocketService] Desconectado del servidor Socket.IO: $reason');
      _isConnecting = false;
      isConnected.value = false;
    });

    _socket!.onConnectError((err) {
      debugPrint('[SocketService] Error de conexion Socket.IO: $err');
      _isConnecting = false;
    });

    _socket!.on(SocketEvents.serverError, (err) {
      debugPrint('[SocketService] Error de Socket.IO: $err');
    });

    // Escuchar el estado completo (Late Joiner)
    _socket!.on(SocketEvents.serverSyncState, (data) {
      debugPrint('[SocketService] Recibido record:sync: $data');
      if (data is Map) {
        lockedFields.value = Map<String, dynamic>.from(data);
      }
    });

    // Escuchar cuando OTRA persona bloquea
    _socket!.on(SocketEvents.serverFieldLocked, (data) {
      if (data is Map) {
        final field = data['field'];
        final lockedBy = data['lockedBy'];
        debugPrint('[SocketService] Recibido fieldLocked: field=$field, lockedBy=$lockedBy');
        if (field is String) {
          final currentLocks = Map<String, dynamic>.from(lockedFields.value);
          currentLocks[field] = lockedBy;
          lockedFields.value = currentLocks;
        }
      }
    });

    // Escuchar cuando OTRA persona libera
    _socket!.on(SocketEvents.serverFieldUnlocked, (data) {
      if (data is Map) {
        final field = data['field'];
        debugPrint('[SocketService] Recibido fieldUnlocked: field=$field');
        if (field is String) {
          final currentLocks = Map<String, dynamic>.from(lockedFields.value);
          currentLocks.remove(field);
          lockedFields.value = currentLocks;
        }
      }
    });

    // Escuchar actualizaciones de campos en tiempo real
    void handleIncomingField(dynamic data) {
      debugPrint('[SocketService] Recibido fieldUpdated raw data: $data');
      if (data is Map) {
        final field = data['field'];
        final value = data['value'];
        debugPrint('[SocketService] Recibido fieldUpdated: field=$field, value=$value');
        if (field is String && value != null) {
          final callbacks = _fieldUpdateCallbacks[field];
          if (callbacks != null && callbacks.isNotEmpty) {
            for (var callback in List.from(callbacks)) {
              callback(value.toString());
            }
          }
        }
      }
    }

    _socket!.on(SocketEvents.serverFieldUpdated, handleIncomingField);
    _socket!.on(SocketEvents.clientUpdateField, handleIncomingField);
    _socket!.on('novedad_creada', (data) {
      debugPrint('[SocketService] Recibido evento directo "novedad_creada": $data');
      final callbacks = _fieldUpdateCallbacks['novedad_creada'];
      if (callbacks != null && callbacks.isNotEmpty) {
        for (var callback in List.from(callbacks)) {
          callback(data is String ? data : (data != null ? data.toString() : ''));
        }
      }
    });
  }

  final Map<String, List<void Function(String)>> _fieldUpdateCallbacks = {};

  void registerFieldListener(String fieldId, void Function(String) callback) {
    _fieldUpdateCallbacks.putIfAbsent(fieldId, () => []).add(callback);
    debugPrint('[SocketService] Registrado listener para "$fieldId" (total oyentes: ${_fieldUpdateCallbacks[fieldId]?.length})');
  }

  void unregisterFieldListener(String fieldId, void Function(String) callback) {
    _fieldUpdateCallbacks[fieldId]?.remove(callback);
    debugPrint('[SocketService] Desregistrado listener para "$fieldId"');
  }

  // --- MÉTODOS PARA EMITIR DESDE LA UI ---

  void joinRecord(String entidad, int id) {
    _currentEntidad = entidad;
    _currentRecordId = id;
    debugPrint('[SocketService] joinRecord($entidad, $id) -> Socket conectado: ${_socket?.connected}');
    _socket?.emit(SocketEvents.clientJoin, {
      'entidad': entidad,
      'id': id,
    });
  }

  void lockField(String fieldId) {
    _socket?.emit(SocketEvents.clientLockField, {'field': fieldId});
  }

  void unlockField(String fieldId) {
    _socket?.emit(SocketEvents.clientUnlockField, {'field': fieldId});
  }

  void updateField(String fieldId, String value) {
    debugPrint('[SocketService] updateField($fieldId) -> Socket conectado: ${_socket?.connected}');
    _socket?.emit(SocketEvents.clientUpdateField, {
      'field': fieldId,
      'value': value,
    });
  }

  void disconnect() {
    _isConnecting = false;
    _currentToken = null;
    _currentEntidad = null;
    _currentRecordId = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    lockedFields.value = {};
    _fieldUpdateCallbacks.clear();
  }
}
