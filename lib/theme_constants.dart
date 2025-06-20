import 'package:flutter/material.dart';

class BuriCareTheme {
  // Primary brand colors
  static const Color primaryColor = Color(0xFF7A1E1E); // Burgundy
  static const Color secondaryColor = Color(0xFFBF4342); // Lighter burgundy
  static const Color accentColor = Color(0xFFFFFFFF); // White

  // Vital sign colors
  static const Color heartRateColor = Color(0xFFBF4342); // Red tint
  static const Color temperatureColor = Color(0xFFD98324); // Orange
  static const Color spo2Color = Color(0xFF2B6DA5); // Blue

  // Status colors
  static const Color normalColor = Color(0xFF2E7D32); // Green
  static const Color warningColor = Color(0xFFFF8F00); // Amber
  static const Color alertColor = Color(0xFFD32F2F); // Red

  // Light theme colors
  static const Color lightPrimaryTextColor = Color(0xFF212121);
  static const Color lightSecondaryTextColor = Color(0xFF757575);
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);

  // Dark theme colors
  static const Color darkPrimaryTextColor = Color(0xFFE0E0E0);
  static const Color darkSecondaryTextColor = Color(0xFFBDBDBD);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkSurfaceColor = Color(0xFF2C2C2C);
  static const Color darkPrimaryColor = Color(0xFF9A1622); // Slightly lighter burgundy for dark mode

  // Get light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightPrimaryTextColor,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: lightCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightPrimaryTextColor),
        bodyMedium: TextStyle(color: lightSecondaryTextColor),
        headlineLarge: TextStyle(color: lightPrimaryTextColor),
        headlineMedium: TextStyle(color: lightPrimaryTextColor),
        titleLarge: TextStyle(color: lightPrimaryTextColor),
      ),
    );
  }

  // Get dark theme data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimaryColor,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: secondaryColor,
        surface: darkSurfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkPrimaryTextColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: darkCardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkPrimaryTextColor),
        bodyMedium: TextStyle(color: darkSecondaryTextColor),
        headlineLarge: TextStyle(color: darkPrimaryTextColor),
        headlineMedium: TextStyle(color: darkPrimaryTextColor),
        titleLarge: TextStyle(color: darkPrimaryTextColor),
      ),
    );
  }

  // Legacy getter for backward compatibility
  static ThemeData get themeData => lightTheme;
}