import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color background = Color(0xFF15151E); // Gris muy oscuro/azulado
  static const Color surface = Color(0xFF1E1E2C); // Un poco más claro para tarjetas y sidebar
  static const Color primary = Color(0xFF00E5FF); // Cyan vibrante para acentos
  static const Color secondary = Color(0xFF757575); // Gris para textos secundarios
  
  // Colores de estado
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFFD740);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: surface,
        error: error,
      ),
      canvasColor: surface, // Usado a menudo por drawers/sidebars
      cardColor: surface,
      dividerColor: surface,
      
      // Configuración de texto
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFB0B0C3), fontSize: 14), // Texto un poco apagado
        labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      
      // Configuración de componentes interactivos
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: secondary),
        hintStyle: const TextStyle(color: secondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background, // Texto en botón
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
