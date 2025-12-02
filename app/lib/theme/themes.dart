import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: 18.0,
      color: Colors.black,
      fontFamily: "Aeonik",
    ),
    iconTheme: IconThemeData(color: Colors.black87),
  ),

  textTheme: const TextTheme(
    bodySmall: TextStyle(color: Colors.black, fontSize: 16.0),
    bodyMedium: TextStyle(color: Colors.black, fontSize: 16.0),
    bodyLarge: TextStyle(color: Colors.black, fontSize: 16.0),
    displaySmall: TextStyle(color: Colors.black, fontSize: 16.0),
    displayMedium: TextStyle(color: Colors.black, fontSize: 16.0),
    displayLarge: TextStyle(color: Colors.black, fontSize: 16.0),
    labelSmall: TextStyle(color: Colors.black, fontSize: 16.0),
    labelMedium: TextStyle(color: Colors.black, fontSize: 16.0),
    labelLarge: TextStyle(color: Colors.black, fontSize: 16.0),
    titleSmall: TextStyle(color: Colors.black, fontSize: 16.0),
    titleMedium: TextStyle(color: Colors.black, fontSize: 16.0),
    titleLarge: TextStyle(color: Colors.black, fontSize: 16.0),
    headlineSmall: TextStyle(color: Colors.black, fontSize: 16.0),
    headlineMedium: TextStyle(color: Colors.black, fontSize: 16.0),
    headlineLarge: TextStyle(color: Colors.black, fontSize: 16.0),
  ),

  fontFamily: "Aeonik",

  scaffoldBackgroundColor: Colors.white,
  canvasColor: Colors.white,
  cardColor: const Color(0xFFF5F5F5),
  dialogBackgroundColor: Colors.white,

  iconTheme: const IconThemeData(color: Colors.black87),

  colorScheme: ColorScheme.fromSwatch(
    brightness: Brightness.light,
  ).copyWith(
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.grey.shade500,
  ),

  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.black54,
    selectionColor: Color(0xFF80EEFB),
  ),
);


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
    bodySmall: TextStyle(color: Colors.white, fontSize: 16.0),
    bodyMedium: TextStyle(color: Colors.white, fontSize: 16.0),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16.0),
    displaySmall: TextStyle(color: Colors.white, fontSize: 16.0),
    displayLarge: TextStyle(color: Colors.white, fontSize: 16.0),
    displayMedium: TextStyle(color: Colors.white, fontSize: 16.0),
    labelLarge: TextStyle(color: Colors.white, fontSize: 16.0),
    labelMedium: TextStyle(color: Colors.white, fontSize: 16.0),
    labelSmall: TextStyle(color: Colors.white, fontSize: 16.0),
    titleLarge: TextStyle(color: Colors.white, fontSize: 16.0),
    titleMedium: TextStyle(color: Colors.white, fontSize: 16.0),
    titleSmall: TextStyle(color: Colors.white, fontSize: 16.0),
    headlineLarge: TextStyle(color: Colors.white, fontSize: 16.0),
    headlineMedium: TextStyle(color: Colors.white, fontSize: 16.0),
    headlineSmall: TextStyle(color: Colors.white, fontSize: 16.0),
  ),
  dialogBackgroundColor: Colors.white,
  fontFamily: "Aeonik",
  cardColor: const Color(0xFF252525),
  canvasColor: Colors.white,
  scaffoldBackgroundColor: const Color(0xFF030303),
  primaryColor: const Color.fromARGB(255, 0, 0, 0),
  hintColor: Colors.grey,
  iconTheme: IconThemeData(
    color: Colors.blueGrey.shade300,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    onPrimary: const Color(0xFFA3ADD0),
    primary: Colors.white,
    brightness: Brightness.light,
    primaryContainer: Colors.white,
    secondary: Colors.grey,
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.grey,
    selectionColor: Color(0xFF80EEFB),
  ),
);
