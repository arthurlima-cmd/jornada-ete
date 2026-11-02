import 'package:flutter/material.dart';

/// Paleta única do app (antes eram mais de 15 cores fixas espalhadas).
class Cores {
  static const azul = Color(0xFF091540);
  static const azulMedio = Color(0xFF3D52A0);
  static const azulClaro = Color(0xFFE8EEF8);
  static const amarelo = Color(0xFFF2B705);
  static const verde = Color(0xFF1B8A3A);
  static const vermelho = Color(0xFFC62828);
  static const fundo = Color(0xFFF4F6FB);
  static const texto = Color(0xFF101213);
  static const textoSecundario = Color(0xFF57636C);
  static const borda = Color(0xFFDDE3EC);
}

ThemeData temaJornada() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Cores.azul,
    primary: Cores.azul,
    secondary: Cores.azulMedio,
    surface: Colors.white,
    error: Cores.vermelho,
  );

  final raio = BorderRadius.circular(12);

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Cores.fundo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Cores.azul,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: raio),
      enabledBorder: OutlineInputBorder(
        borderRadius: raio,
        borderSide: const BorderSide(color: Cores.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: raio,
        borderSide: const BorderSide(color: Cores.azul, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: raio),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: raio),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Cores.azulClaro,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
