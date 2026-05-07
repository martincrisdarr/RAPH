import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/novedad.dart';
import '../../../shared/services/novedad_service.dart';
import '../controllers/ingreso_controller.dart';

class NovedadesSection extends StatefulWidget {
  /// Nombre del usuario actual (inyectado desde IngresoPage vía AuthController)
  final String usuarioActual;

  const NovedadesSection({
    super.key,
    this.usuarioActual = 'Sistema',
  });

  @override
  State<NovedadesSection> createState() => _NovedadesSectionState();
}

class _NovedadesSectionState extends State<NovedadesSection> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final _ingresoController = IngresoController();

  static const String _storageKey = 'novedades_draft';

  final List<Novedad> _novedades = [];

  // Rastrea qué novedades están pendientes de confirmación del servidor
  final Set<int> _pendingIndexes = {};

  @override
  void initState() {
    super.initState();
    _cargarLocal();
  }

  // ── Persistencia local ────────────────────────────────────

  Future<void> _cargarLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      if (mounted) {
        setState(() {
          _novedades.addAll(decoded.map((j) => Novedad.fromJson(j as Map<String, dynamic>)));
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error al cargar novedades locales: $e');
    }
  }

  Future<void> _guardarLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_novedades.map((n) => n.toJson()).toList()),
    );
  }

  // ── Envío ─────────────────────────────────────────────────

  Future<void> _enviarMensaje() async {
    final texto = _inputController.text.trim();
    if (texto.isEmpty) return;

    final now = DateTime.now();
    final novedad = Novedad(
      descripcion: texto,
      idIncidente: _ingresoController.incidenteActual.idIncidente,
      fechaHora: now,
      usuario: widget.usuarioActual,
      idNovedadTipo: 1,
    );

    // 1. Agregar al estado local inmediatamente (UI optimista)
    final idx = _novedades.length;
    setState(() {
      _novedades.add(novedad);
      _pendingIndexes.add(idx);
      _inputController.clear();
    });

    // 2. Persistir localmente
    await _guardarLocal();
    _scrollToBottom();
    _focusNode.requestFocus();

    // 3. Sincronizar con el backend
    final creada = await NovedadService.crear(novedad);
    if (mounted) {
      setState(() {
        _pendingIndexes.remove(idx);
        if (creada != null) {
          // Actualizar el registro local con el ID del servidor
          _novedades[idx] = creada;
        }
        // Si falla, la novedad queda igual en local (sin idNovedad)
      });
      await _guardarLocal();
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Área de mensajes ───────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: _novedades.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 28,
                          color: Color(0xFF2A4A5E),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sin novedades',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF3A5A6E),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _novedades.length,
                    itemBuilder: (context, index) {
                      final nov = _novedades[index];
                      final isPending = _pendingIndexes.contains(index);
                      return _MensajeBubble(
                        texto: nov.descripcion,
                        remitente: nov.usuario ?? widget.usuarioActual,
                        hora: _formatHora(nov.fechaHora ?? DateTime.now()),
                        isPending: isPending,
                      );
                    },
                  ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Barra de entrada ───────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.87),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Agregar una novedad...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white30,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                  onSubmitted: (_) => _enviarMensaje(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _enviarMensaje,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: Size.zero,
                  fixedSize: const Size.fromHeight(44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  textStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Enviar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Burbuja de chat ──────────────────────────────────────────

class _MensajeBubble extends StatelessWidget {
  final String texto;
  final String remitente;
  final String hora;
  final bool isPending;

  const _MensajeBubble({
    required this.texto,
    required this.remitente,
    required this.hora,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicHeight(
          child: Container(
            constraints: const BoxConstraints(minWidth: 160),
            decoration: BoxDecoration(
              color: const Color(0xFF163547),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Acento izquierdo
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.white24
                        : theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                // Contenido
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila: nombre + hora + indicador pending
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              remitente,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isPending
                                    ? Colors.white38
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              hora,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            if (isPending) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Texto
                        Text(
                          texto,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(
                              alpha: isPending ? 0.5 : 0.87,
                            ),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
