import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ltech_core/ltech_core.dart';

const goldenCode = 0xFFb88c51;

const black = Color(0xFF131311);
const softBlack = Color(0xFF1D1D1D);
const golden = Color(goldenCode);
const grey = Color(0xFF30302E);
const white = Colors.white70;

const materialColor = MaterialColor(goldenCode, <int, Color>{
  50: white,
  100: grey,
  200: softBlack,
  300: black,
  400: golden,
  500: golden,
  600: golden,
  700: golden,
});

final appTheme = ThemeData(
  brightness: .dark,
  colorScheme: ColorScheme.fromSeed(seedColor: golden, brightness: .dark),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(golden)
    )
  ),
  iconTheme: IconThemeData(
    color: golden
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(
      side: BorderSide(color: golden.withValues(alpha: .4), width: 1.5),
      borderRadius: 8.borderRadius,
    ),
    titleTextStyle: GoogleFonts.montserrat(
      color: golden,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    contentTextStyle: GoogleFonts.montserrat(color: white, fontSize: 16),
  ),
  drawerTheme: DrawerThemeData(
    shape: BeveledRectangleBorder()
  ),
  textTheme: GoogleFonts.montserratTextTheme().copyWith(
    bodySmall: TextStyle(color: white),
    bodyMedium: TextStyle(color: white),
    bodyLarge: TextStyle(color: white),
    titleSmall: TextStyle(color: white),
    titleMedium: TextStyle(color: white),
    titleLarge: TextStyle(color: white),
    headlineLarge: TextStyle(color: Colors.white),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateColor.resolveWith((state) {
        if (state.contains(WidgetState.disabled)) {}
        return white;
      }),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateColor.resolveWith((state) {
        if (state.contains(WidgetState.disabled)) {}
        return golden;
      }),
      // Texto escuro: o branco sobre o dourado fica abaixo do contraste mínimo.
      foregroundColor: const WidgetStatePropertyAll(black),
      iconColor: const WidgetStatePropertyAll(black),
    ),
  ),
  textSelectionTheme: const TextSelectionThemeData(cursorColor: golden),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(borderRadius: 4.borderRadius),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: golden)),
  ),
  datePickerTheme: DatePickerThemeData(
    todayBorder: BorderSide(color: golden),
    todayForegroundColor: WidgetStatePropertyAll(Colors.white),
    todayBackgroundColor: WidgetStateColor.resolveWith((state) {
      if (state.contains(WidgetState.selected)) {
        return golden;
      }

      return Colors.transparent;
    }),
    dayBackgroundColor: WidgetStateColor.resolveWith((state) {
      if (state.contains(WidgetState.selected)) {
        return golden;
      }

      return Colors.transparent;
    }),
  ),
);
