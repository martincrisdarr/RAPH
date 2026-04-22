import 'package:flutter/material.dart';
import 'app/main_layout.dart';
import 'shared/theme/app_theme.dart';

class RaphApp extends StatelessWidget {
  const RaphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAPH - Despacho de Ambulancias',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}
