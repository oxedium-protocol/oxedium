import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  appBarTheme: AppBarTheme(
    surfaceTintColor: Colors.white,
    titleTextStyle: const TextStyle(
      fontSize: 18.0,
      color: Colors.white,
      fontFamily: "Aeonik",
    ),
    iconTheme: IconThemeData(
      color: Colors.blueGrey.shade300,
    ),
  ),
  textTheme: const TextTheme(
    bodySmall: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    bodyMedium: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    bodyLarge: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    displaySmall: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    displayLarge: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    displayMedium: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    labelLarge: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    labelMedium: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    labelSmall: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    titleLarge: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    titleMedium: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    titleSmall: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    headlineLarge: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    headlineMedium: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
    headlineSmall: TextStyle(
        color: Colors.white, fontWeight: FontWeight.normal, fontSize: 16.0),
  ),
  dialogBackgroundColor: Colors.white,
  fontFamily: "Aeonik",
  cardColor: const Color(0xFF252525),
  canvasColor: Colors.white,
  scaffoldBackgroundColor: const Color(0xFF030303),
  primaryColor: const Color.fromARGB(255, 0, 0, 0),
  hintColor: Colors.grey.withOpacity(0.3),
  iconTheme: IconThemeData(
    color: Colors.blueGrey.shade300,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    onPrimary: const Color(0xFFA3ADD0),
    primary: Colors.white,
    brightness: Brightness.light,
    primaryContainer: Colors.white,
    secondary: Colors.grey.withOpacity(0.3),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.grey.withOpacity(0.3),
    selectionColor: const Color(0xFF80EEFB).withOpacity(0.3),
  ),
);
