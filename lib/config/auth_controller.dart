import 'package:flutter/foundation.dart';
import 'package:user_session_contract/user_session_contract.dart';

class RaphAuthController extends ChangeNotifier {
  static final instance = RaphAuthController._();
  RaphAuthController._();

  IUserSession? session;
  UserData? currentUser;
  String? token;

  void initialize(IUserSession session) {
    this.session = session;
    if (session.estaLogueado) {
      currentUser = session.usuario;
      token = session.token;
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

