import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// Colores semánticos que no cubre [ColorScheme], para modo claro y oscuro.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceMuted;
  final Color border;
  final Color sidebar;
  final Color gradientStart;
  final Color gradientEnd;

  const AppTokens({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceMuted,
    required this.border,
    required this.sidebar,
    required this.gradientStart,
    required this.gradientEnd,
  });

  static const light = AppTokens(
    success: AppPalette.success,
    warning: AppPalette.warning,
    error: AppPalette.error,
    info: AppPalette.info,
    accent: AppPalette.accent,
    textPrimary: AppPalette.textPrimary,
    textSecondary: AppPalette.textSecondary,
    surfaceMuted: AppPalette.surfaceMuted,
    border: AppPalette.border,
    sidebar: AppPalette.sidebar,
    gradientStart: Color(0xFF0F766E),
    gradientEnd: Color(0xFF134E4A),
  );

  static const dark = AppTokens(
    success: AppPalette.successDark,
    warning: AppPalette.warningDark,
    error: AppPalette.errorDark,
    info: AppPalette.infoDark,
    accent: AppPalette.accentDark,
    textPrimary: AppPalette.textPrimaryDark,
    textSecondary: AppPalette.textSecondaryDark,
    surfaceMuted: AppPalette.surfaceMutedDark,
    border: AppPalette.borderDark,
    sidebar: AppPalette.sidebarDark,
    gradientStart: Color(0xFF115E59),
    gradientEnd: Color(0xFF0B3B37),
  );

  LinearGradient get gradient =>
      LinearGradient(colors: [gradientStart, gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight);

  @override
  AppTokens copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? surfaceMuted,
    Color? border,
    Color? sidebar,
    Color? gradientStart,
    Color? gradientEnd,
  }) => AppTokens(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    info: info ?? this.info,
    accent: accent ?? this.accent,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    border: border ?? this.border,
    sidebar: sidebar ?? this.sidebar,
    gradientStart: gradientStart ?? this.gradientStart,
    gradientEnd: gradientEnd ?? this.gradientEnd,
  );

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Material Design 3 con estilos propios: tipografía Outfit (títulos) +
/// DM Sans (texto), botones tipo píldora, campos rellenos sin borde y
/// tarjetas con sombra suave.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    tokens: AppTokens.light,
    primary: AppPalette.primary,
    secondary: AppPalette.secondary,
    background: AppPalette.background,
    surface: AppPalette.surface,
    error: AppPalette.error,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    tokens: AppTokens.dark,
    primary: AppPalette.primaryDark,
    secondary: AppPalette.secondaryDark,
    background: AppPalette.backgroundDark,
    surface: AppPalette.surfaceDark,
    error: AppPalette.errorDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppTokens tokens,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color error,
  }) {
    final oscuro = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: brightness,
      primary: primary,
      onPrimary: oscuro ? const Color(0xFF00201D) : Colors.white,
      secondary: secondary,
      onSecondary: oscuro ? const Color(0xFF331100) : Colors.white,
      tertiary: tokens.accent,
      surface: surface,
      error: error,
    );
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final cuerpo = GoogleFonts.dmSansTextTheme(base.textTheme);
    final titulos = GoogleFonts.outfitTextTheme(base.textTheme);
    final textTheme = cuerpo
        .copyWith(
          displayLarge: titulos.displayLarge,
          displayMedium: titulos.displayMedium,
          displaySmall: titulos.displaySmall,
          headlineLarge: titulos.headlineLarge,
          headlineMedium: titulos.headlineMedium,
          headlineSmall: titulos.headlineSmall,
          titleLarge: titulos.titleLarge,
        )
        .apply(bodyColor: tokens.textPrimary, displayColor: tokens.textPrimary);
    const pildora = StadiumBorder();
    final campo = OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: tokens.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: oscuro ? 0 : 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: oscuro ? BorderSide(color: tokens.border) : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: campo,
        enabledBorder: campo,
        disabledBorder: campo,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: error, width: 2),
        ),
        labelStyle: TextStyle(color: tokens.textSecondary),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: pildora,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: pildora,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: primary, width: 1.4),
          shape: pildora,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 44),
          shape: pildora,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: const StadiumBorder(),
        elevation: 2,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        backgroundColor: tokens.surfaceMuted,
        selectedColor: primary.withValues(alpha: oscuro ? 0.3 : 0.16),
        labelStyle: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w600),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pildora),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.border)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: secondary.withValues(alpha: oscuro ? 0.28 : 0.16),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? secondary : tokens.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? secondary : tokens.textSecondary);
        }),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        iconColor: tokens.textSecondary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: oscuro ? tokens.surfaceMuted : tokens.sidebar,
        contentTextStyle: TextStyle(color: oscuro ? tokens.textPrimary : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      // Calendarios (fecha de nacimiento, inicio de curso…): cabecera con el
      // color de la marca, días redondos y hoy marcado en terracota.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        headerBackgroundColor: oscuro ? tokens.surfaceMuted : tokens.sidebar,
        headerForegroundColor: oscuro ? tokens.textPrimary : Colors.white,
        headerHeadlineStyle: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700),
        weekdayStyle: TextStyle(fontWeight: FontWeight.w800, color: tokens.textSecondary),
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
        todayBorder: BorderSide(color: secondary, width: 1.6),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? colorScheme.onPrimary : secondary,
        ),
        rangeSelectionBackgroundColor: primary.withValues(alpha: oscuro ? 0.22 : 0.12),
        rangePickerHeaderBackgroundColor: oscuro ? tokens.surfaceMuted : tokens.sidebar,
        rangePickerHeaderForegroundColor: oscuro ? tokens.textPrimary : Colors.white,
        yearShape: const WidgetStatePropertyAll(StadiumBorder()),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
        confirmButtonStyle: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: colorScheme.onPrimary),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dialHandColor: primary,
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: tokens.textSecondary,
        indicatorColor: secondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        dividerColor: tokens.border,
      ),
    );
  }
}
