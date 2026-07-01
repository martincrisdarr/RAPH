import 'package:flutter/material.dart';
import '../shared/components/app_sidebar.dart';
import '../modules/ingreso/ingreso_page.dart';
import '../modules/listados/listados_page.dart';
import '../modules/despacho/despacho_page.dart';
import '../modules/configuraciones/configuraciones_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 1;

  List<Widget> get _pages => [
    const IngresoPage(),
    ListadosPage(onNewIncidentTap: () => _onMenuSelected(0)),
    const DespachoPage(),
    const ConfiguracionesPage(),
  ];

  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar de Navegación
          AppSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onMenuSelected,
          ),
          
          // Contenido Principal
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
