import 'package:flutter/material.dart';

class ConfiguracionesPage extends StatefulWidget {
  const ConfiguracionesPage({super.key});

  @override
  State<ConfiguracionesPage> createState() => _ConfiguracionesPageState();
}

class _ConfiguracionesPageState extends State<ConfiguracionesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_rounded, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 16),
                Text(
                  'CONFIGURACIONES',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gestioná los parámetros generales del sistema y opciones de ingreso.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            
            // TabBar
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                ),
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'ETIQUETAS', icon: Icon(Icons.label_outline_rounded)),
                  Tab(text: 'PROTOCOLOS', icon: Icon(Icons.assignment_rounded)),
                  Tab(text: 'SISTEMA', icon: Icon(Icons.dvr_rounded)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEtiquetasSection(theme),
                  _buildProtocolosSection(theme),
                  _buildSistemaSection(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtiquetasSection(ThemeData theme) {
    // Mock data based on incidente_section.dart
    final etiquetas = [
      {'nombre': 'Caída', 'color': Colors.yellow.shade300},
      {'nombre': 'Tránsito', 'color': Colors.yellow.shade300},
      {'nombre': 'Arma blanca', 'color': Colors.red.shade300},
      {'nombre': 'Arma de fuego', 'color': Colors.red.shade300},
      {'nombre': 'Inconsciente', 'color': Colors.red.shade300},
      {'nombre': 'Cardíaco', 'color': Colors.red.shade300},
      {'nombre': 'Respiratorio', 'color': Colors.yellow.shade300},
      {'nombre': 'Quemadura', 'color': Colors.yellow.shade300},
      {'nombre': 'Vía Pública', 'color': Colors.green.shade300},
      {'nombre': 'Domicilio', 'color': Colors.green.shade300},
    ];

    return _buildConfigGrid(
      theme,
      title: 'Etiquetas de Incidentes',
      items: etiquetas.map((e) => _ConfigCardItem(
        title: e['nombre'] as String,
        subtitle: 'Color asignado',
        icon: Icons.label_rounded,
        iconColor: e['color'] as Color,
      )).toList(),
      onAdd: () => _showAddDialog(context, 'Nueva Etiqueta'),
    );
  }

  Widget _buildProtocolosSection(ThemeData theme) {
    // Mock data based on protocolo_victimas.dart
    final protocolos = [
      {'titulo': 'ACCIDENTE VEHICULAR', 'cod': 'Cód. 116', 'icon': '🚗'},
      {'titulo': 'DERRUMBE', 'cod': 'Cód. 120', 'icon': '🏚️'},
      {'titulo': 'CATÁSTROFE', 'cod': 'Cód. 125', 'icon': '⚡'},
      {'titulo': 'GASES TÓXICOS', 'cod': 'Cód. 121', 'icon': '☠️'},
      {'titulo': 'ACCIDENTE INDUSTRIAL', 'cod': 'Cód. 119', 'icon': '🏭'},
    ];

    return _buildConfigGrid(
      theme,
      title: 'Protocolos de Emergencia',
      items: protocolos.map((p) => _ConfigCardItem(
        title: p['titulo']!,
        subtitle: p['cod']!,
        icon: Icons.emergency_rounded,
        trailing: Text(p['icon']!, style: const TextStyle(fontSize: 24)),
      )).toList(),
      onAdd: () => _showAddDialog(context, 'Nuevo Protocolo'),
    );
  }

  Widget _buildSistemaSection(ThemeData theme) {
    final opciones = [
      {'titulo': 'Tipos de Ingreso', 'desc': 'Gestionar categorías de entrada'},
      {'titulo': 'Géneros', 'desc': 'Opciones de identificación'},
      {'titulo': 'Localidades', 'desc': 'Zonas de cobertura'},
    ];

    return _buildConfigGrid(
      theme,
      title: 'Listados del Sistema',
      items: opciones.map((o) => _ConfigCardItem(
        title: o['titulo']!,
        subtitle: o['desc']!,
        icon: Icons.list_rounded,
      )).toList(),
      onAdd: () => _showAddDialog(context, 'Nuevo Listado'),
    );
  }

  Widget _buildConfigGrid(ThemeData theme, {
    required String title,
    required List<_ConfigCardItem> items,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('AGREGAR'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 100,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (item.iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.iconColor ?? theme.colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                    if (item.trailing != null) item.trailing!,
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white38),
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('GUARDAR')),
        ],
      ),
    );
  }
}

class _ConfigCardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;

  _ConfigCardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.trailing,
  });
}
