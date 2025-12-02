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
      color: Colors.black,
      fontFamily: "Aeonik",
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(
      color: Colors.black54,
    ),
  ),

  // --- TEXT ---
  textTheme: const TextTheme(
    bodySmall: TextStyle(color: Colors.black87, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
    bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),

    displaySmall: TextStyle(color: Colors.black87, fontSize: 16),
    displayMedium: TextStyle(color: Colors.black87, fontSize: 16),
    displayLarge: TextStyle(color: Colors.black87, fontSize: 16),

    labelSmall: TextStyle(color: Colors.black87, fontSize: 16),
    labelMedium: TextStyle(color: Colors.black87, fontSize: 16),
    labelLarge: TextStyle(color: Colors.black87, fontSize: 16),

    titleSmall: TextStyle(color: Colors.black87, fontSize: 16),
    titleMedium: TextStyle(color: Colors.black87, fontSize: 16),
    titleLarge: TextStyle(color: Colors.black87, fontSize: 16),

    headlineSmall: TextStyle(color: Colors.black87, fontSize: 16),
    headlineMedium: TextStyle(color: Colors.black87, fontSize: 16),
    headlineLarge: TextStyle(color: Colors.black87, fontSize: 16),
  ),

  // --- COLORS ---
  scaffoldBackgroundColor: const Color(0xFFEFF3FB), // оставил как просили
  dialogBackgroundColor: Colors.white,
  cardColor: Colors.white,
  canvasColor: Colors.white,
  primaryColor: Colors.black,
  hintColor: Colors.grey.withOpacity(0.3),

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
    cursorColor: Colors.black.withOpacity(0.6),
    selectionColor: Colors.black.withOpacity(0.2),
  ),
);
