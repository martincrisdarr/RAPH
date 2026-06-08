import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

/// Tema principal de la librería RAPH.
///
/// Usa [ColorScheme.dark] como base y aplica los tokens definidos
/// en `app_theme_tokens.dart` para construir un estilo dark moderno.
ThemeData buildAppTheme() {
  const ColorScheme colorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.accentBlue,
    secondary: AppColors.accentPurple,
    error: AppColors.accentRed,
    background: AppColors.background,
    surface: AppColors.surface,
    onBackground: AppColors.textPrimary,
    onSurface: AppColors.textPrimary,
  );

  final ThemeData base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
  );

  final TextTheme baseText = base.textTheme;

  final TextTheme textTheme = baseText.copyWith(
    displayLarge: baseText.displayLarge?.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: baseText.headlineMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: baseText.titleLarge?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: baseText.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: baseText.bodyLarge?.copyWith(
      fontSize: 14,
      color: AppColors.textPrimary,
    ),
    bodyMedium: baseText.bodyMedium?.copyWith(
      fontSize: 13,
      color: AppColors.textSecondary,
    ),
    labelLarge: baseText.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: AppColors.textPrimary,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      floatingLabelStyle: TextStyle(color: colorScheme.primary, fontSize: 14),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24, width: 1.0),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: AppColors.shadow.withOpacity(0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: AppColors.border.withOpacity(0.9),
          width: 1,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.border.withOpacity(0.9),
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: 20,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background.withOpacity(0.9),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: const MaterialStatePropertyAll(true),
      thickness: const MaterialStatePropertyAll(4),
      radius: const Radius.circular(999),
      thumbColor: MaterialStatePropertyAll(
        AppColors.border.withOpacity(0.9),
      ),
      trackColor: const MaterialStatePropertyAll(Colors.transparent),
    ),
  );
}

