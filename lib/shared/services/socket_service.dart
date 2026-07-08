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

  // Estado reactivo: Mapa de los campos que están bloqueados actualmente
  // Ejemplo: {"telefono": {"id": "ivanb", "nombre": "Ivan Benzaquen"}}
  final ValueNotifier<Map<String, dynamic>> lockedFields = ValueNotifier({});

  // Estado reactivo de conexión
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    final uri = Uri.parse(ApiConfig.socketUrl);
    final baseUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
    final socketPath = '/socket.io'; // Usamos el path root que responde con JSON y no da 404

    debugPrint('[SocketService] Conectando a $baseUrl con path $socketPath');

    _socket = io.io(baseUrl, io.OptionBuilder()
      .setPath(socketPath)
      .setTransports(['polling', 'websocket']) // Permite iniciar por HTTP polling y luego escalar a WebSocket
      .setAuth({'token': token}) // Envío seguro del token (v3/v4)
      .setQuery({'token': token}) // Compatibilidad con handshakes basados en query
      .enableForceNew()
      .build());

    _socket!.onConnect((_) {
      debugPrint('Conectado al servidor Socket.IO');
      isConnected.value = true;
    });

    _socket!.onDisconnect((_) {
      debugPrint('Desconectado del servidor Socket.IO');
      isConnected.value = false;
    });

    _socket!.on(SocketEvents.serverError, (err) {
      debugPrint('Error de Socket.IO: $err');
    });

    // Escuchar el estado completo (Late Joiner)
    _socket!.on(SocketEvents.serverSyncState, (data) {
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
    _socket!.on(SocketEvents.serverFieldUpdated, (data) {
      if (data is Map) {
        final field = data['field'];
        final value = data['value'];
        debugPrint('[SocketService] Recibido fieldUpdated: field=$field, value=$value');
        if (field is String && value != null) {
          final callbacks = _fieldUpdateCallbacks[field];
          if (callbacks != null) {
            for (var callback in callbacks) {
              callback(value.toString());
            }
          }
        }
      }
    });
  }

  final Map<String, List<void Function(String)>> _fieldUpdateCallbacks = {};

  void registerFieldListener(String fieldId, void Function(String) callback) {
    _fieldUpdateCallbacks.putIfAbsent(fieldId, () => []).add(callback);
  }

  void unregisterFieldListener(String fieldId, void Function(String) callback) {
    _fieldUpdateCallbacks[fieldId]?.remove(callback);
  }

  // --- MÉTODOS PARA EMITIR DESDE LA UI ---

  void joinRecord(String entidad, int id) {
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
    _socket?.emit(SocketEvents.clientUpdateField, {
      'field': fieldId,
      'value': value,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    isConnected.value = false;
    lockedFields.value = {};
    _fieldUpdateCallbacks.clear();
  }
}
