import 'package:flutter/material.dart';

/// Paleta del Sistema de Gestión Académica: verde azulado (académico),
/// terracota como acento y fondos cálidos tipo papel. Los widgets no usan
/// estas constantes directamente: las leen del tema
/// (`Theme.of(context).colorScheme` y `context.tokens`).
class AppPalette {
  AppPalette._();

  // Modo claro
  static const primary = Color(0xFF0F766E); // verde azulado
  static const secondary = Color(0xFFD9653B); // terracota
  static const accent = Color(0xFFE0A526); // dorado
  static const success = Color(0xFF2F9E44);
  static const warning = Color(0xFFD9910B);
  static const error = Color(0xFFD64545);
  static const info = Color(0xFF2B7FD3);
  static const background = Color(0xFFF6F4EF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEFEBE3);
  static const border = Color(0xFFE2DCD0);
  static const textPrimary = Color(0xFF1B2B2A);
  static const textSecondary = Color(0xFF5E6B69);
  static const sidebar = Color(0xFF0B3B37);

  // Modo oscuro
  static const primaryDark = Color(0xFF4FD1C0);
  static const secondaryDark = Color(0xFFF2925F);
  static const accentDark = Color(0xFFF2C14E);
  static const successDark = Color(0xFF5BD08A);
  static const warningDark = Color(0xFFF2B84B);
  static const errorDark = Color(0xFFF27B7B);
  static const infoDark = Color(0xFF6BB3F2);
  static const backgroundDark = Color(0xFF0E1514);
  static const surfaceDark = Color(0xFF162120);
  static const surfaceMutedDark = Color(0xFF1F2C2A);
  static const borderDark = Color(0xFF2B3D3A);
  static const textPrimaryDark = Color(0xFFE7EFEE);
  static const textSecondaryDark = Color(0xFF9DB0AD);
  static const sidebarDark = Color(0xFF0A1211);
}
