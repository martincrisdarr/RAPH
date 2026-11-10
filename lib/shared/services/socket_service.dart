import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';
import '../../config/auth_controller.dart';
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

  // Campos que este cliente local bloqueó explícitamente en la sesión
  final Set<String> _myLockedFields = {};

  String? get socketId => _socket?.id;

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

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setPath(socketPath)
          .setTransports(['polling', 'websocket']) // Permite iniciar por HTTP polling y luego escalar a WebSocket
          .setAuth({'token': token}) // Envío seguro del token (v3/v4)
          .setQuery({'token': token}) // Compatibilidad con handshakes basados en query
          .build(),
    );

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

    // Escuchar cuando OTRA persona libera (o confirmación de liberación)
    _socket!.on(SocketEvents.serverFieldUnlocked, (data) {
      if (data is Map) {
        final field = data['field'];
        debugPrint('[SocketService] Recibido fieldUnlocked: field=$field');
        if (field is String) {
          _myLockedFields.remove(field);
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

    void handleDespachoEvent(dynamic data) {
      debugPrint('[SocketService] Recibido evento de despacho: $data');
      final encoded = data is String ? data : (data != null ? jsonEncode(data) : '');
      final callbacks = _fieldUpdateCallbacks['despacho_actualizado'];
      if (callbacks != null && callbacks.isNotEmpty) {
        for (var callback in List.from(callbacks)) {
          callback(encoded);
        }
      }
    }

    _socket!.on('nuevo_despacho', handleDespachoEvent);
    _socket!.on('despacho_actualizado', handleDespachoEvent);
    _socket!.on('despacho_cancelado', handleDespachoEvent);
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
    _myLockedFields.add(fieldId);
    _socket?.emit(SocketEvents.clientLockField, {'field': fieldId});
  }

  void unlockField(String fieldId) {
    _myLockedFields.remove(fieldId);
    _socket?.emit(SocketEvents.clientUnlockField, {'field': fieldId});
  }

  /// Verifica si un campo está bloqueado por OTRO usuario (excluye al usuario actual).
  bool isFieldLockedByOther(String fieldId) {
    // Si nosotros mismos bloqueamos este campo en esta sesión, no está bloqueado para nosotros
    if (_myLockedFields.contains(fieldId)) return false;

    final locks = lockedFields.value;
    if (!locks.containsKey(fieldId)) return false;
    final lockInfo = locks[fieldId];
    return !isLockOwnedByCurrentUser(lockInfo);
  }

  /// Determina si un objeto de bloqueo pertenece al usuario actualmente autenticado en esta sesión.
  bool isLockOwnedByCurrentUser(dynamic lockInfo) {
    if (lockInfo == null) return false;

    // 1. Comparar por socketId si el servidor lo incluye
    final currentSocketId = _socket?.id;
    if (lockInfo is Map) {
      final lockSocketId = (lockInfo['socketId'] ?? lockInfo['socket_id'])?.toString();
      if (currentSocketId != null && lockSocketId != null && currentSocketId == lockSocketId) {
        return true;
      }
    }

    // 2. Normalizador de strings (remueve acentos y pasa a minúsculas)
    String norm(String s) => s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .trim();

    // 3. Obtener identificadores del usuario actual de RaphAuthController
    final auth = RaphAuthController.instance;
    final myUsername = norm(auth.currentUsername);
    final myNombre = norm(auth.currentUser?.nombre ?? '');
    final myApellido = norm(auth.currentUser?.apellido ?? '');
    final myFullName = '$myNombre $myApellido'.trim();
    final myEmail = norm(auth.currentUser?.email ?? '');

    // Extraer datos del lockInfo
    String? lockUser;
    String? lockNombre;
    String? lockEmail;

    if (lockInfo is Map) {
      final u = lockInfo['usuario'] ?? lockInfo['user'] ?? lockInfo['username'] ?? lockInfo['id'];
      if (u != null) lockUser = norm(u.toString());
      if (lockInfo['nombre'] != null) lockNombre = norm(lockInfo['nombre'].toString());
      if (lockInfo['email'] != null) lockEmail = norm(lockInfo['email'].toString());
    } else if (lockInfo is String) {
      final str = norm(lockInfo);
      lockUser = str;
      lockNombre = str;
    }

    // Comparar username
    if (myUsername.isNotEmpty && myUsername != 'usuario') {
      if (lockUser != null && (lockUser == myUsername || lockUser.contains(myUsername))) {
        return true;
      }
    }

    // Comparar nombre completo o coincidencia cruzada
    if (myFullName.isNotEmpty) {
      if (lockNombre != null &&
          (lockNombre == myFullName ||
              lockNombre.contains(myFullName) ||
              myFullName.contains(lockNombre))) {
        return true;
      }
      if (myNombre.isNotEmpty && myApellido.isNotEmpty && lockNombre != null) {
        if (lockNombre.contains(myNombre) && lockNombre.contains(myApellido)) {
          return true;
        }
      }
    }

    // Comparar nombre suelto si tiene más de 3 caracteres
    if (myNombre.length > 3 && lockNombre != null && lockNombre.contains(myNombre)) {
      if (myApellido.isNotEmpty && lockNombre.contains(myApellido)) {
        return true;
      }
    }

    // Comparar email
    if (myEmail.isNotEmpty && lockEmail != null && myEmail == lockEmail) {
      return true;
    }

    return false;
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
    _myLockedFields.clear();
    lockedFields.value = {};
    _socket?.disconnect();
  }
}
