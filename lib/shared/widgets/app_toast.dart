import 'package:flutter/material.dart';
import '../theme/app_theme_tokens.dart';

enum ToastType {
  success,
  despacho,
  cancelado,
  warning,
  error,
  info,
}

class AppToast {
  static OverlayEntry? _currentEntry;

  /// Muestra un Toast en la esquina superior derecha con animación moderna.
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    // Si ya hay un toast visible, removerlo limpiamente
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        title: title,
        message: message,
        type: type,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
        duration: duration,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String title;
  final String? message;
  final ToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.title,
    this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));

    _animController.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismissWithAnim();
      }
    });
  }

  void _dismissWithAnim() async {
    if (!mounted) return;
    await _animController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgGradientStart;
    Color bgGradientEnd;
    Color borderColor;
    Color iconColor;
    IconData iconData;

    switch (widget.type) {
      case ToastType.success:
      case ToastType.despacho:
        bgGradientStart = const Color(0xFF064E3B);
        bgGradientEnd = const Color(0xFF022C22);
        borderColor = const Color(0xFF10B981);
        iconColor = const Color(0xFF34D399);
        iconData = widget.type == ToastType.despacho
            ? Icons.airport_shuttle_rounded
            : Icons.check_circle_rounded;
        break;

      case ToastType.cancelado:
      case ToastType.warning:
        bgGradientStart = const Color(0xFF451A03);
        bgGradientEnd = const Color(0xFF291002);
        borderColor = const Color(0xFFF59E0B);
        iconColor = const Color(0xFFFBBF24);
        iconData = widget.type == ToastType.cancelado
            ? Icons.cancel_outlined
            : Icons.warning_amber_rounded;
        break;

      case ToastType.error:
        bgGradientStart = const Color(0xFF5A1218);
        bgGradientEnd = const Color(0xFF36080D);
        borderColor = const Color(0xFFEF4444);
        iconColor = const Color(0xFFF87171);
        iconData = Icons.error_outline_rounded;
        break;

      case ToastType.info:
        bgGradientStart = const Color(0xFF0C2B4E);
        bgGradientEnd = const Color(0xFF06182D);
        borderColor = const Color(0xFF38BDF8);
        iconColor = const Color(0xFF7DD3FC);
        iconData = Icons.info_outline_rounded;
        break;
    }

    return Positioned(
      top: 24,
      right: 24,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 380,
                  minWidth: 280,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bgGradientStart, bgGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: borderColor.withOpacity(0.7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: borderColor.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: iconColor.withOpacity(0.35), width: 1),
                      ),
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (widget.message != null && widget.message!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.message!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _dismissWithAnim,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
