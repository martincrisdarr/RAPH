import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:user_session_contract/user_session_contract.dart';

class RaphAuthController extends ChangeNotifier {
  static final instance = RaphAuthController._();
  RaphAuthController._();

  IUserSession? session;
  UserData? currentUser;
  String? token;
  String? username;

  String get currentUsername {
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }

    // 1. Extraer del JWT token si está disponible
    final userFromToken = _extractUserFromJwt(token);
    if (userFromToken != null && userFromToken.isNotEmpty) {
      username = userFromToken;
      return userFromToken;
    }

    // 2. Extraer del email (ej. "gguerrero@neuquen.gov.ar" -> "gguerrero")
    if (currentUser?.email != null && currentUser!.email.isNotEmpty) {
      final email = currentUser!.email.trim();
      final userPart = email.contains('@') ? email.split('@').first : email;
      if (!userPart.contains(' ') && userPart.isNotEmpty) {
        username = userPart;
        return userPart;
      }
    }

    // 3. Si nombre no tiene espacios, podría ser el username
    if (currentUser?.nombre != null && currentUser!.nombre.isNotEmpty && !currentUser!.nombre.contains(' ')) {
      return currentUser!.nombre.trim();
    }

    return 'usuario';
  }

  static String? _extractUserFromJwt(String? jwtToken) {
    if (jwtToken == null || !jwtToken.contains('.')) return null;
    try {
      final parts = jwtToken.split('.');
      if (parts.length >= 2) {
        final normalized = base64.normalize(parts[1]);
        final payloadString = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> payload = jsonDecode(payloadString);

        final u = payload['user'] ??
            payload['username'] ??
            (payload['data'] is Map ? payload['data']['user'] : null) ??
            (payload['usuario'] is Map ? payload['usuario']['user'] : null);

        if (u != null && u.toString().trim().isNotEmpty) {
          return u.toString().trim();
        }
      }
    } catch (e) {
      debugPrint('[RaphAuthController] Error al decodificar JWT: $e');
    }
    return null;
  }

  void initialize(IUserSession session, {String? explicitUsername}) {
    this.session = session;
    if (explicitUsername != null && explicitUsername.isNotEmpty) {
      username = explicitUsername;
    }
    if (session.estaLogueado) {
      currentUser = session.usuario;
      token = session.token;
      if (username == null || username!.isEmpty) {
        username = _extractUserFromJwt(token);
      }
    }
    notifyListeners();
  }

  Future<void> logout() async {
    if (session != null) {
      await session!.logout();
    }
    currentUser = null;
    token = null;
    session = null;
    notifyListeners();
  }
}

