import 'package:flutter/material.dart';
import 'package:user_session_contract/user_session_contract.dart';
import 'app/main_layout.dart';
import 'shared/theme/app_theme.dart';
import 'config/auth_controller.dart';
import 'shared/services/socket_service.dart';

class RaphApp extends StatefulWidget {
  final IUserSession? session;

  const RaphApp({super.key, this.session});

  @override
  State<RaphApp> createState() => _RaphAppState();
}

class _RaphAppState extends State<RaphApp> {
  @override
  void initState() {
    super.initState();
    _syncSession(notify: false);
  }

  @override
  void didUpdateWidget(covariant RaphApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _syncSession(notify: true);
    }
  }

  void _syncSession({required bool notify}) {
    final session = widget.session;
    if (session != null) {
      RaphAuthController.instance.initialize(session, notify: notify);
      final token = session.token;
      if (token != null && token.isNotEmpty) {
        SocketService().connect(token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAPH - Despacho de Ambulancias',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainLayout(),
    );
  }
}
