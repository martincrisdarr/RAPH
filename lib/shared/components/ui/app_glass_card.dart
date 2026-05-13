import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';

/// Contenedor base con efecto "glass" sutil para el tema dark.
///
/// Usa los tokens de [AppColors] y [AppRadii] para integrarse con el resto
/// del sistema de diseño. No hardcodea colores en el widget.
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableBlur;
  final double blurSigma;
  final double? borderRadius;

  /// Permite ajustar ligeramente el nivel de opacidad del fondo.
  final double backgroundOpacity;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.enableBlur = true,
    this.blurSigma = 18,
    this.borderRadius,
    this.backgroundOpacity = 0.82,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? AppRadii.lg;

    final Color backgroundColor =
        AppColors.surface.withOpacity(backgroundOpacity);

    final BorderRadius resolvedRadius = BorderRadius.circular(radius);

    Widget card = AnimatedContainer(
      duration: AppDurations.medium,
      curve: Curves.easeOut,
      margin: margin ?? EdgeInsets.zero,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: resolvedRadius,
        border: Border.all(
          color: AppColors.border.withOpacity(0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.50),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );

    if (!enableBlur) {
      return ClipRRect(
        borderRadius: resolvedRadius,
        child: card,
      );
    }

    return ClipRRect(
      borderRadius: resolvedRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: card,
      ),
    );
  }
}

