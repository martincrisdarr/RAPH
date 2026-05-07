import 'package:flutter/material.dart';
import 'package:raph/raph.dart';
import 'package:user_session_contract/user_session_contract.dart';

// AutoLoginSession simulating the IUserSession from Portal
class AutoLoginSession implements IUserSession {
  final UserData _user;
  final String _token;

  AutoLoginSession(this._user, this._token);

  @override bool get estaLogueado => true;
  @override String get token => _token;
  @override UserData get usuario => _user;
  @override Future<void> logout() async => debugPrint("Simulated Logout");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Simulamos un inicio de sesión predeterminado para el modo de desarrollo (Standalone)
  final simulatedUser = UserData(
    nombre: 'dev12345',
    apellido: '',
    email: 'dev12345@example.com',
  );
  final fakeToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImRldjEyMzQ1In0.eyJzdWIiOiJkZXYxMjM0NSIsImlzcyI6IiIsImF1ZCI6IiIsImlhdCI6MTc3ODE3Mjk2MSwiZXhwIjoxNzc4MzQ1NzYxLCJqdGkiOiI4ZDBjMGM5ZDM5NzIyY2EiLCJ1c2VyIjoiZGV2MTIzNDUiLCJub21icmUiOiJVc3VhcmlvIn0.vcSEIBdJZmVsmCjWCySFLPcluOtRK83basYYmUyMI1k';
  
  final mockSession = AutoLoginSession(simulatedUser, fakeToken);

  runApp(RaphApp(session: mockSession));
}
