import 'package:flutter/material.dart';

/// Tokens de diseño base para el tema dark estilo Giro/antigravity.
///
/// Importar estos tokens desde widgets y temas en lugar de hardcodear colores
/// o radios, para mantener una base visual consistente.
class AppColors {
  // Colores base
  static const Color background = Color(0xFF050816);
  static const Color surface = Color(0xFF0B1020);
  static const Color surfaceAlt = Color(0xFF111827);

  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);

  static const Color border = Color(0xFF1F2937);
  static const Color shadow = Color(0xFF000000);

  // Colores de acento
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentRed = Color(0xFFFB7185);
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentPurple = Color(0xFFA855F7);
}

/// Radios de borde estándar para el sistema de diseño.
class AppRadii {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Espaciados estándar en el layout.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Duraciones recomendadas para animaciones sutiles.
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);
}

