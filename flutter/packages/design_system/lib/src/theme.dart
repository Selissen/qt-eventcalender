import 'package:flutter/material.dart';

/// Tokens matching the Qt Material theme used in the Qt shell.
abstract final class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryContainer = Color(0xFF1976D2);
  static const secondary = Color(0xFF00897B);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F5F5);
  static const error = Color(0xFFD32F2F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF212121);
}

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.secondary,
      onSecondaryContainer: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      onError: AppColors.onPrimary,
    ),
    fontFamily: 'Roboto',
  );
}
