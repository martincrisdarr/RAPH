import 'package:flutter/material.dart';

/// Widget base para skeleton loading. Muestra un bloque animado con
/// dimensiones y bordes configurables.
///
/// Ejemplo de uso:
/// ```dart
/// // Skeleton genérico
/// SkeletonBox(width: 200, height: 16)
///
/// // Skeleton de un campo de formulario (altura estándar, ancho expandido)
/// SkeletonField()
///
/// // Skeleton de un campo corto con label
/// SkeletonField(width: 120)
/// ```
class SkeletonBox extends StatefulWidget {
  /// Ancho del skeleton. Si es null se expande al máximo disponible.
  final double? width;

  /// Alto del skeleton.
  final double height;

  /// Radio de borde. Por defecto 8.
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.04 + _animation.value * 0.04),
                Colors.white.withValues(alpha: 0.10 + _animation.value * 0.06),
                Colors.white.withValues(alpha: 0.04 + _animation.value * 0.04),
              ],
              stops: [
                0.0,
                0.3 + _animation.value * 0.4,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton que imita la altura y el estilo de un campo de formulario
/// (TextFormField / DropdownMenu). Incluye opcionalmente un "label"
/// encima o en modo superpuesto, igual que los inputs del proyecto.
class SkeletonField extends StatelessWidget {
  /// Ancho fijo. Si es null, se expande al espacio disponible.
  final double? width;

  /// Alto del campo. Por defecto 56 (igual que los inputs estándar).
  final double height;

  /// Ancho del label simulado que aparece dentro del campo.
  final double labelWidth;

  const SkeletonField({
    super.key,
    this.width,
    this.height = 56,
    this.labelWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label simulado (línea delgada, más angosta)
          SkeletonBox(width: labelWidth, height: 10, borderRadius: 4),
          const SizedBox(height: 6),
          // Valor simulado (línea más ancha y oscura)
          SkeletonBox(
            width: (width != null) ? width! * 0.6 : null,
            height: 11,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Fila de skeleton fields para formularios con múltiples columnas.
/// Recibe una lista de [widths] relativas (flex) o [fixedWidths] absolutas.
///
/// Ejemplo:
/// ```dart
/// // 3 campos iguales en fila
/// SkeletonFieldRow(count: 3)
///
/// // Campo grande + pequeño
/// SkeletonFieldRow(flexValues: [3, 1])
/// ```
class SkeletonFieldRow extends StatelessWidget {
  /// Número de campos con flex igual (se ignora si flexValues != null).
  final int count;

  /// Lista de flex custom para cada campo.
  final List<int>? flexValues;

  /// Espacio entre campos.
  final double spacing;

  const SkeletonFieldRow({
    super.key,
    this.count = 1,
    this.flexValues,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final values = flexValues ?? List.filled(count, 1);

    return Row(
      children: [
        for (int i = 0; i < values.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            flex: values[i],
            child: const SkeletonField(),
          ),
        ],
      ],
    );
  }
}
