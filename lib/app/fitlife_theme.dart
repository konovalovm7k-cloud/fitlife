import 'package:flutter/material.dart';

const green = Color(0xFF35785B);
const greenDark = Color(0xFF214D3B);
const mint = Color(0xFFE7F0E8);
const bg = Color(0xFFF5F5EF);
const ink = Color(0xFF20362B);
const muted = Color(0xFF65756B);
const line = Color(0xFFE3E8DF);
const coral = Color(0xFFCE795E);
const gold = Color(0xFFB38A3C);

ThemeData fitLifeTheme() {
  final base = ThemeData(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(seedColor: green).copyWith(
      primary: green,
      onPrimary: Colors.white,
      surface: bg,
      onSurface: ink,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'Manrope',
      bodyColor: ink,
      displayColor: ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: mint,
      height: 76,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: green, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: line, space: 24),
  );
}
