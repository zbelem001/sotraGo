import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightGray,
        error: AppColors.alert,
        onPrimary: Colors.white,
        onSecondary: AppColors.darkSlate,
        onSurface: AppColors.darkSlate,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSlate,
        error: AppColors.alert,
        onPrimary: Colors.white,
        onSecondary: AppColors.darkSlate,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSlate,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
