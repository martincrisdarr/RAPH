import 'package:user_session_contract/user_session_contract.dart';

class RaphAuthController {
  static final instance = RaphAuthController._();
  RaphAuthController._();

  UserData? currentUser;
  String? token;

  void initialize(IUserSession session) {
    if (session.estaLogueado) {
      currentUser = session.usuario;
      token = session.token;
    }
  }
}
