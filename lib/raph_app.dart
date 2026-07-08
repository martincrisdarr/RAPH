import 'package:flutter/material.dart';
import 'package:user_session_contract/user_session_contract.dart';
import 'app/main_layout.dart';
import 'shared/theme/app_theme.dart';
import 'config/auth_controller.dart';
import 'shared/services/socket_service.dart';

class RaphApp extends StatelessWidget {
  final IUserSession? session;

  const RaphApp({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    if (session != null) {
      RaphAuthController.instance.initialize(session!);
      
      final token = session!.token;
      if (token != null && token.isNotEmpty) {
        SocketService().connect(token);
      }
    }

    return MaterialApp(
      title: 'RAPH - Despacho de Ambulancias',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainLayout(),
    );
  }
}
