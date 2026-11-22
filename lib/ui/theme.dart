import 'package:material_ui/material_ui.dart';

/// A coin cabinet: green felt, brass and old paper.
const felt = Color(0xFF1E3B32);
const feltDeep = Color(0xFF142A23);
const brass = Color(0xFFC79A3B);
const paper = Color(0xFFF6F1E6);
const card = Color(0xFFFFFCF5);
const ink = Color(0xFF1D1B18);
const muted = Color(0xFF6B655B);
const line = Color(0xFFE3DACA);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: felt,
    primary: felt,
    secondary: brass,
    surface: paper,
    onSurface: ink,
  );
  final base = ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    useMaterial3: true,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brass,
      foregroundColor: feltDeep,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: line),
      backgroundColor: card,
    ),
  );
}
