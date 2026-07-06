import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  runApp(const DevLoginApp());
}

class DevLoginApp extends StatefulWidget {
  const DevLoginApp({super.key});

  @override
  State<DevLoginApp> createState() => _DevLoginAppState();
}

class _DevLoginAppState extends State<DevLoginApp> {
  IUserSession? _session;
  final _userController = TextEditingController(text: '');
  final _passController = TextEditingController(text: '');
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa usuario y contraseña.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://emergenciasyriesgos.neuquen.gov.ar/giro/api/web/usuario/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user': username,
          'pass': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final userData = data['usuario'] ?? {};
          final simulatedUser = UserData(
            nombre: userData['nombre']?.toString() ?? username,
            apellido: userData['apellido']?.toString() ?? '',
            email: userData['mail']?.toString() ?? '',
          );
          final token = data['token']?.toString() ?? '';

          setState(() {
            _session = AutoLoginSession(simulatedUser, token);
          });
          return;
        }
      }
      
      setState(() {
        _errorMessage = 'Error de inicio de sesión (${response.statusCode}):\n${response.body}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Excepción al conectar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session != null) {
      return RaphApp(session: _session);
    }

    return MaterialApp(
      title: 'RAPH - Dev Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_person,
                    size: 64,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'RAPH - Modo Desarrollo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión con credenciales reales para obtener un token JWT válido y probar los WebSockets.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'CONECTAR Y ABRIR APP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
