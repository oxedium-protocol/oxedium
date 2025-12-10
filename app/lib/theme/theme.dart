import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: "Aeonik",

  // --- APP BAR ---
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 18.0,
      color: Colors.white,
      fontFamily: "Aeonik",
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
  ),

  // --- TEXT ---
  textTheme: const TextTheme(
    bodySmall: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),

    displaySmall: TextStyle(color: Colors.white, fontSize: 16),
    displayMedium: TextStyle(color: Colors.white, fontSize: 16),
    displayLarge: TextStyle(color: Colors.white, fontSize: 16),

    labelSmall: TextStyle(color: Colors.white, fontSize: 16),
    labelMedium: TextStyle(color: Colors.white, fontSize: 16),
    labelLarge: TextStyle(color: Colors.white, fontSize: 16),

    titleSmall: TextStyle(color: Colors.white, fontSize: 16),
    titleMedium: TextStyle(color: Colors.white, fontSize: 16),
    titleLarge: TextStyle(color: Colors.white, fontSize: 16),

    headlineSmall: TextStyle(color: Colors.white, fontSize: 16),
    headlineMedium: TextStyle(color: Colors.white, fontSize: 16),
    headlineLarge: TextStyle(color: Colors.white, fontSize: 16),
  ),

  // --- COLORS ---
  scaffoldBackgroundColor: const Color(0xFF0E0E0E),
  dialogBackgroundColor: Colors.white,
  cardColor: const Color(0xFF1A1A20),
  canvasColor: Colors.white,
  primaryColor: const Color(0xFF141419),
  hintColor: Colors.grey.withOpacity(0.8),

  iconTheme: const IconThemeData(color: Colors.black54),

  // --- COLOR SCHEME ---
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.grey.shade300,
    primaryContainer: Colors.white,
  ),

  // --- SELECT TEXT ---
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.grey.withOpacity(0.6),
    selectionColor: Colors.grey.withOpacity(0.2),
  ),
);
