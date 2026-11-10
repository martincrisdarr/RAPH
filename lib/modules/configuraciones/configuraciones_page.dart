import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../shared/models/configuracion.dart';
import '../../shared/models/hospital.dart';
import '../../shared/services/configuracion_service.dart';
import '../../shared/services/geocoding_service.dart';
import '../../shared/services/hospital_service.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
              'Gestioná las categorías generales del sistema y centros hospitalarios de forma organizada por módulos.',
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
                  Tab(text: 'HOSPITALES', icon: Icon(Icons.local_hospital_rounded)),
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
                  _buildHospitalesTab(),
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

  Widget _buildHospitalesTab() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: const [
        _HospitalFolderCard(
          title: 'Hospitales y Centros de Salud',
          description: 'Administrar catálogo de hospitales y su ubicación en el mapa para traslados de ambulancias',
          icon: Icons.local_hospital_rounded,
          iconColor: Color(0xFF00E5FF),
        ),
      ],
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
      final data = await ConfiguracionService.obtenerPorTipo(widget.idTipo, forzarRecarga: true);
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

class _HospitalFolderCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const _HospitalFolderCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<_HospitalFolderCard> createState() => _HospitalFolderCardState();
}

class _HospitalFolderCardState extends State<_HospitalFolderCard> {
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
      final items = await HospitalService.obtenerHospitales(forzarRecarga: true);
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
      builder: (context) => _GestionHospitalesModal(
        title: widget.title,
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
                      _isLoading ? 'Cargando...' : '$_count hospital(es)',
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

class _GestionHospitalesModal extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onChanged;

  const _GestionHospitalesModal({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  State<_GestionHospitalesModal> createState() => _GestionHospitalesModalState();
}

class _GestionHospitalesModalState extends State<_GestionHospitalesModal> {
  List<Hospital> _hospitales = [];
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
      final data = await HospitalService.obtenerHospitales(forzarRecarga: true);
      if (mounted) {
        setState(() {
          _hospitales = data;
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
            constraints: const BoxConstraints(maxWidth: 380),
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

  void _abrirDialogoHospital({Hospital? hospital}) {
    final isEditing = hospital != null;
    final nombreCtrl = TextEditingController(text: hospital?.nombre ?? '');
    final direccionCtrl = TextEditingController(text: hospital?.direccion ?? '');
    final localidadCtrl = TextEditingController(text: hospital?.localidad ?? 'Neuquén');

    double? selectedLat = hospital?.latitud;
    double? selectedLng = hospital?.longitud;
    GoogleMapController? mapController;

    bool buscandoEnMapa = false;
    bool guardando = false;

    final bool mapsSupported = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> buscarDireccionEnMapa() async {
            final dir = direccionCtrl.text.trim();
            final loc = localidadCtrl.text.trim().isEmpty ? 'Neuquén' : localidadCtrl.text.trim();
            if (dir.isEmpty) {
              _mostrarToast('Ingresá una dirección para ubicarla en el mapa', esError: true);
              return;
            }
            setDialogState(() => buscandoEnMapa = true);
            try {
              final coords = await GeocodingService.getCoordinatesFromAddress(dir, localidad: loc);
              if (coords != null) {
                if (ctx.mounted) {
                  setDialogState(() {
                    selectedLat = coords.latitude;
                    selectedLng = coords.longitude;
                  });
                }
                mapController?.animateCamera(CameraUpdate.newLatLngZoom(coords, 16));
                _mostrarToast('Ubicación marcada en el mapa');
              } else {
                _mostrarToast('No se encontró la dirección exacta, podés marcarla tocando el mapa', esError: true);
              }
            } catch (_) {
              _mostrarToast('Error al buscar la dirección en el mapa', esError: true);
            } finally {
              if (ctx.mounted) {
                setDialogState(() => buscandoEnMapa = false);
              }
            }
          }

          Future<void> seleccionarPuntoEnMapa(LatLng coords) async {
            setDialogState(() {
              selectedLat = coords.latitude;
              selectedLng = coords.longitude;
              buscandoEnMapa = true;
            });
            try {
              final address = await GeocodingService.getAddressFromCoordinates(
                coords.latitude,
                coords.longitude,
              );
              if (address != null && address.trim().isNotEmpty && ctx.mounted) {
                setDialogState(() {
                  direccionCtrl.text = address.trim();
                });
              }
            } catch (_) {
            } finally {
              if (ctx.mounted) {
                setDialogState(() => buscandoEnMapa = false);
              }
            }
          }

          InputDecoration buildDeco({
            required String hint,
            required IconData icon,
          }) {
            return InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon: Icon(icon, color: widget.iconColor, size: 18),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            );
          }

          final Set<Marker> markers = {};
          if (selectedLat != null && selectedLng != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('hospital_selected_pin'),
                position: LatLng(selectedLat!, selectedLng!),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );
          }

          return PointerInterceptor(
            child: Dialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFF334155), width: 1.5),
              ),
              child: Container(
                width: 660,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
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
                              isEditing ? Icons.edit_location_alt_rounded : Icons.local_hospital_rounded,
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
                                  isEditing ? 'Editar Hospital / Centro de Salud' : 'Nuevo Hospital / Centro de Salud',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Ingresá la dirección o marcá el punto exacto en el mapa',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
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
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: Color(0xFF334155)),
                      const SizedBox(height: 18),

                      // Nombre
                      const Text(
                        'Nombre del Hospital / Institución *',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nombreCtrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: buildDeco(
                          hint: 'Ej. Hospital Provincial Neuquén Dr. Eduardo Castro Rendón',
                          icon: Icons.local_hospital_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Dirección y Localidad + Botón Buscar en Mapa
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dirección / Ubicación *',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: direccionCtrl,
                                  onSubmitted: (_) => buscarDireccionEnMapa(),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: buildDeco(
                                    hint: 'Ej. Buenos Aires 450',
                                    icon: Icons.location_on_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Localidad',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: localidadCtrl,
                                  onSubmitted: (_) => buscarDireccionEnMapa(),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: buildDeco(
                                    hint: 'Neuquén',
                                    icon: Icons.location_city_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: buscandoEnMapa ? null : buscarDireccionEnMapa,
                              icon: buscandoEnMapa
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.search_rounded, size: 18),
                              label: const Text('BUSCAR EN MAPA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Encabezado del Mapa
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.touch_app_rounded, size: 15, color: Colors.white54),
                              SizedBox(width: 6),
                              Text(
                                'Hacé clic en el mapa para marcar la ubicación exacta del hospital',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (selectedLat != null && selectedLng != null)
                                  ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                  : Colors.orange.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (selectedLat != null && selectedLng != null)
                                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                    : Colors.orange.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  (selectedLat != null && selectedLng != null)
                                      ? Icons.check_circle_rounded
                                      : Icons.info_outline_rounded,
                                  size: 12,
                                  color: (selectedLat != null && selectedLng != null)
                                      ? const Color(0xFF34D399)
                                      : Colors.orangeAccent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  (selectedLat != null && selectedLng != null)
                                      ? 'Ubicación marcada'
                                      : 'Sin marcar en el mapa',
                                  style: TextStyle(
                                    color: (selectedLat != null && selectedLng != null)
                                        ? const Color(0xFF34D399)
                                        : Colors.orangeAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Mapa interactivo
                      Container(
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14.5),
                          child: !mapsSupported
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map_outlined, size: 36, color: Colors.white24),
                                      SizedBox(height: 8),
                                      Text(
                                        'Mapa interactivo disponible en versión Web y Móvil',
                                        style: TextStyle(color: Colors.white38, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                )
                              : Stack(
                                  children: [
                                    GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(
                                          selectedLat ?? -38.9516,
                                          selectedLng ?? -68.0591,
                                        ),
                                        zoom: selectedLat != null ? 15 : 13,
                                      ),
                                      myLocationButtonEnabled: false,
                                      mapToolbarEnabled: false,
                                      zoomControlsEnabled: true,
                                      markers: markers,
                                      onMapCreated: (controller) => mapController = controller,
                                      onTap: seleccionarPuntoEnMapa,
                                    ),
                                    if (buscandoEnMapa)
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: widget.iconColor.withValues(alpha: 0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: widget.iconColor,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Actualizando ubicación...',
                                                style: TextStyle(color: Colors.white, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Divider(height: 1, color: Color(0xFF334155)),
                      const SizedBox(height: 16),

                      // Botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: guardando ? null : () => Navigator.pop(ctx),
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
                            icon: guardando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.check_circle_rounded, size: 18),
                            label: Text(isEditing ? 'GUARDAR CAMBIOS' : 'CREAR HOSPITAL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.iconColor,
                              foregroundColor: const Color(0xFF0F172A),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 4,
                            ),
                            onPressed: guardando
                                ? null
                                : () async {
                                    final nombre = nombreCtrl.text.trim();
                                    final direccion = direccionCtrl.text.trim();
                                    final localidad = localidadCtrl.text.trim().isEmpty
                                        ? 'Neuquén'
                                        : localidadCtrl.text.trim();

                                    if (nombre.isEmpty || direccion.isEmpty) {
                                      _mostrarToast('Completá el nombre y la dirección del hospital', esError: true);
                                      return;
                                    }

                                    setDialogState(() => guardando = true);

                                    double? lat = selectedLat;
                                    double? lng = selectedLng;

                                    // Si aún no marcó en el mapa, geocodificar automáticamente por dirección
                                    if (lat == null || lng == null) {
                                      try {
                                        final coords = await GeocodingService.getCoordinatesFromAddress(
                                          direccion,
                                          localidad: localidad,
                                        );
                                        if (coords != null) {
                                          lat = coords.latitude;
                                          lng = coords.longitude;
                                        }
                                      } catch (_) {}
                                    }

                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }

                                    try {
                                      if (!isEditing) {
                                        final creado = await HospitalService.crearHospital(
                                          nombre: nombre,
                                          direccion: direccion,
                                          localidad: localidad,
                                          latitud: lat,
                                          longitud: lng,
                                        );
                                        if (creado != null) {
                                          _mostrarToast('Hospital "$nombre" creado correctamente');
                                        } else {
                                          _mostrarToast('Error al crear el hospital', esError: true);
                                        }
                                      } else {
                                        final actualizado = await HospitalService.actualizarHospital(
                                          hospital.idhospital,
                                          nombre: nombre,
                                          direccion: direccion,
                                          localidad: localidad,
                                          latitud: lat,
                                          longitud: lng,
                                        );
                                        if (actualizado != null) {
                                          _mostrarToast('Hospital "$nombre" actualizado');
                                        } else {
                                          _mostrarToast('Error al actualizar el hospital', esError: true);
                                        }
                                      }
                                      await _cargarDatos();
                                      widget.onChanged();
                                    } catch (_) {
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
        },
      ),
    );
  }

  Future<void> _eliminarHospital(Hospital item) async {
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
            width: 460,
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
                            'Eliminar Hospital',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'El hospital dejará de aparecer en las opciones de traslado',
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
                      const Icon(Icons.local_hospital_rounded, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.direccion} (${item.localidad})',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
      final exito = await HospitalService.eliminarHospital(item.idhospital);
      if (exito) {
        _mostrarToast('Hospital "${item.nombre}" eliminado');
      } else {
        _mostrarToast('No se pudo eliminar el hospital', esError: true);
      }
      await _cargarDatos();
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _hospitales.where((h) {
      if (h.activo != 1) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return h.nombre.toLowerCase().contains(q) ||
          h.direccion.toLowerCase().contains(q) ||
          h.localidad.toLowerCase().contains(q);
    }).toList();

    return PointerInterceptor(
      child: Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        child: Container(
          width: 900,
          height: 640,
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
                          'Red de derivación y traslado sanitario • ${_hospitales.length} hospital(es) activo(s)',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _abrirDialogoHospital(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('NUEVO HOSPITAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.iconColor,
                      foregroundColor: const Color(0xFF0F172A),
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
                  hintText: 'Buscar por nombre, dirección o localidad...',
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

              // Grid de Hospitales
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (filtrados.isEmpty
                        ? Center(
                            child: Text(
                              _hospitales.isEmpty
                                  ? 'No hay hospitales registrados aún.'
                                  : 'No se encontraron hospitales para "$_searchQuery".',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 430,
                              mainAxisExtent: 108,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final h = filtrados[index];
                              final tieneUbicacion = h.latitud != null && h.longitud != null;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: widget.iconColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.local_hospital_rounded, color: widget.iconColor, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            h.nombre,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.place_outlined, size: 13, color: Colors.white54),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${h.direccion}, ${h.localidad}',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                tieneUbicacion ? Icons.location_on_rounded : Icons.location_off_outlined,
                                                size: 12,
                                                color: tieneUbicacion ? const Color(0xFF34D399) : Colors.orangeAccent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                tieneUbicacion ? 'Ubicado en el mapa' : 'Sin ubicación en mapa',
                                                style: TextStyle(
                                                  color: tieneUbicacion ? const Color(0xFF34D399) : Colors.orangeAccent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar hospital',
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                                          onPressed: () => _abrirDialogoHospital(hospital: h),
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar hospital',
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                          onPressed: () => _eliminarHospital(h),
                                        ),
                                      ],
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
