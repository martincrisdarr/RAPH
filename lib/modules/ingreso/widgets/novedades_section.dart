import 'package:flutter/material.dart';

class _Mensaje {
  final String texto;
  final String remitente;
  final DateTime hora;

  _Mensaje({
    required this.texto,
    required this.remitente,
    required this.hora,
  });
}

class NovedadesSection extends StatefulWidget {
  /// Nombre del usuario actual (en producción vendrá de la sesión)
  final String usuarioActual;

  const NovedadesSection({
    super.key,
    this.usuarioActual = 'Dev Local',
  });

  @override
  State<NovedadesSection> createState() => _NovedadesSectionState();
}

class _NovedadesSectionState extends State<NovedadesSection> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_Mensaje> _mensajes = [];

  void _enviarMensaje() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _mensajes.add(
        _Mensaje(
          texto: texto,
          remitente: widget.usuarioActual,
          hora: DateTime.now(),
        ),
      );
      _controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });

    _focusNode.requestFocus();
  }

  String _formatHora(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Área de mensajes ─────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: _mensajes.isEmpty
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
                    itemCount: _mensajes.length,
                    itemBuilder: (context, index) {
                      final msg = _mensajes[index];
                      return _MensajeBubble(
                        texto: msg.texto,
                        remitente: msg.remitente,
                        hora: _formatHora(msg.hora),
                      );
                    },
                  ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Barra de entrada ─────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
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
                      vertical: 12,
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
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                      ),
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

  const _MensajeBubble({
    required this.texto,
    required this.remitente,
    required this.hora,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
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
                  color: theme.colorScheme.primary,
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
                      // Fila: nombre + hora
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            remitente,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Texto del mensaje
                      Text(
                        texto,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.87),
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
    );
  }
}
