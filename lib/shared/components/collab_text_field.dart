import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/socket_service.dart';

class CollabTextField extends StatefulWidget {
  final String fieldId; // Ej: "descripcion" o "victima_1_nombre"
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final bool isCollaborative;

  const CollabTextField({
    Key? key,
    required this.fieldId,
    required this.label,
    this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.suffixIcon,
    this.initialValue,
    this.validator,
    this.isCollaborative = true,
  }) : super(key: key);

  @override
  _CollabTextFieldState createState() => _CollabTextFieldState();
}

class _CollabTextFieldState extends State<CollabTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool _isLocalController = false;
  bool _isLocalFocusNode = false;
  Timer? _unlockDebounce;

  @override
  void initState() {
    super.initState();
    
    // Configurar controller
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue);
      _isLocalController = true;
    }

    // Configurar FocusNode
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isLocalFocusNode = true;
    }

    // Escuchar eventos de Focus para emitir locks/unlocks
    _focusNode.addListener(_onFocusChange);

    // Registrar listener para actualizaciones de texto colaborativo
    SocketService().registerFieldListener(widget.fieldId, _onFieldUpdatedFromServer);
  }

  void _onFocusChange() {
    if (!widget.isCollaborative) return;
    if (_focusNode.hasFocus) {
      _unlockDebounce?.cancel();
      SocketService().lockField(widget.fieldId);
    } else {
      _unlockDebounce?.cancel();
      // Debounce de 150ms para evitar desbloqueos fantasmas por parpadeo de foco en Flutter Web
      _unlockDebounce = Timer(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          SocketService().unlockField(widget.fieldId);
        }
      });
    }
  }

  void _onFieldUpdatedFromServer(String newValue) {
    if (!widget.isCollaborative) return;
    // Si el usuario local NO está escribiendo (no tiene foco), actualizamos el valor en tiempo real
    if (!_focusNode.hasFocus) {
      if (_controller.text != newValue) {
        setState(() {
          _controller.text = newValue;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
        
        // Disparar callback local para mantener el estado sincronizado
        if (widget.onChanged != null) {
          widget.onChanged!(newValue);
        }
      }
    }
  }

  @override
  void dispose() {
    _unlockDebounce?.cancel();
    SocketService().unregisterFieldListener(widget.fieldId, _onFieldUpdatedFromServer);
    _focusNode.removeListener(_onFocusChange);
    if (_isLocalFocusNode) {
      _focusNode.dispose();
    }
    if (_isLocalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: SocketService().lockedFields,
      builder: (context, locks, child) {
        final bool isLocked = widget.isCollaborative && locks.containsKey(widget.fieldId);
        String lockedByName = "";

        if (isLocked) {
          lockedByName = locks[widget.fieldId]['nombre'] ?? 'Otro usuario';
        }

        return Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !isLocked,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              validator: widget.validator,
              onChanged: (val) {
                // Emitir cambio en tiempo real al socket
                if (widget.isCollaborative) {
                  SocketService().updateField(widget.fieldId, val);
                }
                
                // Disparar callback local
                if (widget.onChanged != null) {
                  widget.onChanged!(val);
                }
              },
              textAlignVertical: widget.maxLines == null || widget.maxLines! > 1 
                  ? TextAlignVertical.top 
                  : TextAlignVertical.center,
              decoration: InputDecoration(
                labelText: widget.label,
                alignLabelWithHint: true,
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: isLocked 
                    ? Colors.red.withOpacity(0.05) 
                    : Colors.white.withOpacity(0.02),
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isLocked ? Colors.redAccent.withOpacity(0.5) : Colors.white12,
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.redAccent.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                suffixIcon: widget.suffixIcon,
              ),
            ),

            // Badge indicador de quién está bloqueando (estilo Premium)
            if (isLocked)
              Positioned(
                right: 12,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Editando: $lockedByName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
