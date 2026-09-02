import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../shared/models/configuracion.dart';
import '../../shared/services/configuracion_service.dart';

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
              'Gestioná las categorías generales del sistema de forma organizada por módulos.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            
            // TabBar
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
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
                  _buildEtiquetasTab(),
                  _buildProtocolosTab(),
                  _buildSistemaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtiquetasTab() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: const [
        _CategoryFolderCard(
          title: 'Etiquetas de Incidentes',
          description: 'Administrar el catálogo de etiquetas clasificatorias para incidentes (Tipo 8)',
          idTipo: 8,
          icon: Icons.label_rounded,
          iconColor: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildProtocolosTab() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: const [
        _CategoryFolderCard(
          title: 'Tipos de Incidentes',
          description: 'Catálogo de tipos de incidente (Tipo 4: Accidente Vehicular, Derrumbe, etc.)',
          idTipo: 4,
          icon: Icons.category_rounded,
          iconColor: Colors.deepOrangeAccent,
        ),
        _CategoryFolderCard(
          title: 'Protocolos de Emergencia',
          description: 'Administrar catálogo de protocolos rápidos y guía de incidentes (Tipo 7)',
          idTipo: 7,
          icon: Icons.emergency_rounded,
          iconColor: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildSistemaTab() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: const [
        _CategoryFolderCard(
          title: 'Tipos de Ingreso',
          description: 'Categorías de entrada de llamadas y demandas (Tipo 3)',
          idTipo: 3,
          icon: Icons.call_received_rounded,
          iconColor: Colors.blueAccent,
        ),
        _CategoryFolderCard(
          title: 'Géneros de Identificación',
          description: 'Opciones de género de pacientes y víctimas (Tipo 6)',
          idTipo: 6,
          icon: Icons.people_alt_rounded,
          iconColor: Colors.purpleAccent,
        ),
      ],
    );
  }
}

class _CategoryFolderCard extends StatefulWidget {
  final String title;
  final String description;
  final int idTipo;
  final IconData icon;
  final Color iconColor;

  const _CategoryFolderCard({
    required this.title,
    required this.description,
    required this.idTipo,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<_CategoryFolderCard> createState() => _CategoryFolderCardState();
}

class _CategoryFolderCardState extends State<_CategoryFolderCard> {
  int _count = 0;
  bool _isLoading = true;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _cargarConteo();
  }

  Future<void> _cargarConteo() async {
    try {
      final items = await ConfiguracionService.obtenerPorTipo(widget.idTipo);
      if (mounted) {
        setState(() {
          _count = items.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _abrirModalGestion() {
    showDialog(
      context: context,
      builder: (context) => _GestionConfiguracionModal(
        title: widget.title,
        idTipo: widget.idTipo,
        icon: widget.icon,
        iconColor: widget.iconColor,
        onChanged: _cargarConteo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _abrirModalGestion,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? widget.iconColor.withValues(alpha: 0.7) : const Color(0xFF334155),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.iconColor.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: widget.iconColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      _isLoading ? 'Cargando...' : '$_count elemento(s)',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'ADMINISTRAR',
                        style: TextStyle(
                          color: widget.iconColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: widget.iconColor, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GestionConfiguracionModal extends StatefulWidget {
  final String title;
  final int idTipo;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onChanged;

  const _GestionConfiguracionModal({
    required this.title,
    required this.idTipo,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  State<_GestionConfiguracionModal> createState() => _GestionConfiguracionModalState();
}

class _GestionConfiguracionModalState extends State<_GestionConfiguracionModal> {
  List<Configuracion> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final data = await ConfiguracionService.obtenerPorTipo(widget.idTipo);
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarToast(String mensaje, {bool esError = false}) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: esError ? const Color(0xFF7F1D1D) : const Color(0xFF064E3B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: esError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  esError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: esError ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  void _abrirDialogoGuardar({Configuracion? item}) {
    final controller = TextEditingController(text: item?.descripcion ?? '');
    final isEditing = item != null;

    showDialog(
      context: context,
      builder: (ctx) => PointerInterceptor(
        child: Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF334155), width: 1.5),
          ),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: widget.iconColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                        color: widget.iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Editar Registro' : 'Nuevo Registro',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Categoría: ${widget.title}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 20),

                // Form Field
                const Text(
                  'Nombre / Descripción de la Opción *',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ej. Nueva etiqueta...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: Icon(Icons.label_outlined, color: widget.iconColor, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.iconColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('CANCELAR'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('GUARDAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.iconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        final texto = controller.text.trim();
                        if (texto.isEmpty) return;
                        Navigator.pop(ctx);

                        try {
                          if (item == null) {
                            final res = await ConfiguracionService.crearConfiguracion(
                              descripcion: texto,
                              idconfiguraciontipo: widget.idTipo,
                            );
                            if (res != null) {
                              _mostrarToast('"$texto" creado correctamente');
                            } else {
                              _mostrarToast('Error al crear "$texto"', esError: true);
                            }
                          } else {
                            final res = await ConfiguracionService.actualizarConfiguracion(
                              item.idconfiguracion,
                              descripcion: texto,
                              idconfiguraciontipo: widget.idTipo,
                            );
                            if (res != null) {
                              _mostrarToast('"$texto" actualizado correctamente');
                            } else {
                              _mostrarToast('Error al actualizar "$texto"', esError: true);
                            }
                          }
                          await _cargarDatos();
                          widget.onChanged();
                        } catch (e) {
                          _mostrarToast('Error al procesar la solicitud', esError: true);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _eliminar(Configuracion item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => PointerInterceptor(
        child: Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirmar Eliminación',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Esta acción eliminará el registro de la base de datos',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.label_off_outlined, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.descripcion,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${item.idconfiguracion} • Tipo ${widget.idTipo}',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('CANCELAR'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('ELIMINAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      try {
        final exito = await ConfiguracionService.eliminarConfiguracion(item.idconfiguracion);
        if (exito) {
          _mostrarToast('"${item.descripcion}" eliminado correctamente');
        } else {
          _mostrarToast('Error al eliminar "${item.descripcion}"', esError: true);
        }
        await _cargarDatos();
        widget.onChanged();
      } catch (e) {
        _mostrarToast('Error al procesar la eliminación', esError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _items.where((e) {
      if (e.activo != 1) return false;
      if (_searchQuery.isEmpty) return true;
      return e.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return PointerInterceptor(
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        child: Container(
          width: 780,
          height: 620,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Modal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.iconColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Catálogo dinámico (Tipo ${widget.idTipo}) • ${_items.length} elemento(s)',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _abrirDialogoGuardar(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('NUEVO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFF334155)),
              const SizedBox(height: 16),

              // Buscador
              TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar en ${widget.title}...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.25),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contenido Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (filtrados.isEmpty
                        ? Center(
                            child: Text(
                              _items.isEmpty
                                  ? 'No hay elementos configurados en esta categoría.'
                                  : 'No se encontraron resultados para "$_searchQuery".',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisExtent: 90,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final item = filtrados[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: widget.iconColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(widget.icon, color: widget.iconColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.descripcion,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ID: ${item.idconfiguracion} • Activo: ${item.activo == 1 ? "Sí" : "No"}',
                                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white54),
                                      onPressed: () => _abrirDialogoGuardar(item: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                      onPressed: () => _eliminar(item),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFF334155)),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('CERRAR'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
