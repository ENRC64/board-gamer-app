import 'package:material_ui/material_ui.dart';

import 'app_spacing.dart';

/// Zentrales Material-3-Theme.
///
/// Alle Farben werden aus einem einzigen Seed über [ColorScheme.fromSeed]
/// abgeleitet. Widgets greifen nur über `Theme.of(context).colorScheme` auf
/// Farben zu; hartcodierte Farben außerhalb dieser Datei sind nicht erlaubt.
abstract final class AppTheme {
  /// Einzige Markenfarbe der App (Brettspiel-Grün).
  static const Color _seed = Color(0xFF2E7D5B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final radius = BorderRadius.circular(AppSpacing.md);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Eine Hintergrundfarbe für alle Screens (kein veraltetes `background`).
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
