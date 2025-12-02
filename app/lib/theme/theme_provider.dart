import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:oxedium_website/theme/themes.dart';

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, bool?>((ref) => ThemeNotifier());

final themeProvider = Provider<ThemeData?>((ref) {
  final isDark = ref.watch(themeNotifierProvider);

  if (isDark == null) return null; // загружается

  return isDark ? darkTheme : lightTheme;
});

final themeIconProvider = Provider<IconData>((ref) {
  final isDark = ref.watch(themeNotifierProvider) ?? true;
  return isDark ? Icons.light_mode : Icons.dark_mode;
});



class ThemeNotifier extends StateNotifier<bool?> {
  ThemeNotifier() : super(null) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool("isDarkTheme") ?? true;

    state = saved;
  }

  Future<void> toggleTheme() async {
    if (state == null) return;

    final newValue = !state!;
    state = newValue;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkTheme", newValue);
  }
}

