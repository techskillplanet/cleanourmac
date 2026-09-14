import 'package:flutter/material.dart';

class AppPalette {
  static const primary = Color(0xFF385C67);
  static const primaryDark = Color(0xFF83A9B3);
  static const accent = Color(0xFF596A7B);
  static const canvas = Color(0xFFF4F5F7);
  static const sidebar = Color(0xFFEEF0F2);
  static const heroStart = Color(0xFF17212A);
  static const heroEnd = Color(0xFF263641);
  static const success = Color(0xFF39715B);
  static const warning = Color(0xFFA06A2C);
  static const danger = Color(0xFFB54747);
  static const android = Color(0xFF557363);
  static const ios = Color(0xFF596A7B);

  // Dark mode uses a blue-green graphite ramp instead of inverting the
  // light palette. This keeps surfaces layered without turning gray text
  // into low-contrast fog.
  static const darkCanvas = Color(0xFF0E151A);
  static const darkSurface = Color(0xFF151E24);
  static const darkSurfaceRaised = Color(0xFF1B282F);
  static const darkSurfaceHigh = Color(0xFF22333B);
  static const darkBorder = Color(0xFF354850);
  static const darkPrimary = Color(0xFF8CCBD3);
  static const darkPrimaryContainer = Color(0xFF21454D);
  static const darkOnPrimary = Color(0xFF082126);
  static const darkText = Color(0xFFEDF4F5);
  static const darkMutedText = Color(0xFFA8BABF);
  static const darkSuccess = Color(0xFF7BC89F);
  static const darkWarning = Color(0xFFE4B66F);
  static const darkDanger = Color(0xFFF08D8D);

  static bool isDark(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark;

  static Color successFor(BuildContext context) =>
      isDark(context) ? darkSuccess : success;

  static Color warningFor(BuildContext context) =>
      isDark(context) ? darkWarning : warning;

  static Color dangerFor(BuildContext context) =>
      isDark(context) ? darkDanger : danger;
}

class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      secondary: AppPalette.accent,
      brightness: Brightness.light,
      surface: AppPalette.canvas,
    ),
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppPalette.darkPrimary,
      onPrimary: AppPalette.darkOnPrimary,
      primaryContainer: AppPalette.darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFC0EDF0),
      secondary: Color(0xFFB8C8CD),
      onSecondary: Color(0xFF172227),
      secondaryContainer: Color(0xFF33464D),
      onSecondaryContainer: Color(0xFFD6E5E8),
      tertiary: AppPalette.darkWarning,
      onTertiary: Color(0xFF2A2112),
      tertiaryContainer: Color(0xFF58421F),
      onTertiaryContainer: Color(0xFFFFDEAA),
      error: AppPalette.darkDanger,
      onError: Color(0xFF351416),
      errorContainer: Color(0xFF5E2528),
      onErrorContainer: Color(0xFFFFDAD9),
      surface: AppPalette.darkCanvas,
      onSurface: AppPalette.darkText,
      surfaceDim: Color(0xFF0E151A),
      surfaceBright: Color(0xFF2B3B43),
      surfaceContainerLowest: Color(0xFF0A1014),
      surfaceContainerLow: AppPalette.darkSurface,
      surfaceContainer: Color(0xFF19242A),
      surfaceContainerHigh: AppPalette.darkSurfaceRaised,
      surfaceContainerHighest: AppPalette.darkSurfaceHigh,
      onSurfaceVariant: AppPalette.darkMutedText,
      outline: Color(0xFF71858B),
      outlineVariant: AppPalette.darkBorder,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE4ECEE),
      onInverseSurface: Color(0xFF182328),
      inversePrimary: Color(0xFF3D6971),
      surfaceTint: AppPalette.darkPrimary,
    ),
    dark: true,
  );

  static ThemeData _build(ColorScheme colorScheme, {bool dark = false}) {
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: '.AppleSystemUIFont',
      scaffoldBackgroundColor: colorScheme.surface,
    );

    final borderColor = colorScheme.outlineVariant.withValues(
      alpha: dark ? 0.78 : 0.7,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? colorScheme.surface.withValues(alpha: 0.92)
            : Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 76,
        titleSpacing: 24,
        shape: Border(bottom: BorderSide(color: borderColor)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? AppPalette.darkSurfaceRaised : const Color(0xFFFAFAFB),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? AppPalette.darkSurfaceRaised : null,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: dark ? AppPalette.darkSurfaceHigh : null,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? AppPalette.darkSurfaceHigh : null,
        contentTextStyle: TextStyle(
          color: dark ? AppPalette.darkText : null,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
