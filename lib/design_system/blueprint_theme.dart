import 'package:flutter/material.dart';

class BlueprintTheme {
  static const Color obsidian = Color(0xFF0C1016);
  static const Color midnight = Color(0xFF111723);
  static const Color slate = Color(0xFF171E2A);
  static const Color panel = Color(0xFF151C27);
  static const Color panelRaised = Color(0xFF1A2230);
  static const Color outline = Color(0xFF283345);
  static const Color fog = Color(0xFF8E9AAD);
  static const Color pearl = Color(0xFFF6F2EA);
  static const Color ruby = Color(0xFFFF6B6B);
  static const Color coral = Color(0xFFFF9870);
  static const Color seafoam = Color(0xFF80E2D2);
  static const Color gold = Color(0xFFF1C678);

  static ThemeData light() {
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: seafoam,
      onPrimary: obsidian,
      secondary: coral,
      onSecondary: obsidian,
      surface: panel,
      onSurface: pearl,
      error: ruby,
      onError: pearl,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: obsidian,
      canvasColor: obsidian,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      scaffoldBackgroundColor: obsidian,
      dividerColor: outline,
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: pearl,
          letterSpacing: -0.9,
          height: 1.05,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: pearl,
          letterSpacing: -0.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: pearl,
          letterSpacing: -0.35,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: pearl,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: pearl.withValues(alpha: 0.96),
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: pearl.withValues(alpha: 0.88),
          height: 1.5,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: pearl.withValues(alpha: 0.84),
          height: 1.5,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: fog,
          height: 1.45,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: pearl,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: outline.withValues(alpha: 0.8)),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: midnight.withValues(alpha: 0.98),
        indicatorColor: seafoam.withValues(alpha: 0.16),
        elevation: 0,
        height: 78,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? pearl : fog,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? seafoam : fog,
            size: 22,
          );
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: slate,
        selectedColor: seafoam.withValues(alpha: 0.18),
        side: const BorderSide(color: outline),
        labelStyle: const TextStyle(
          color: pearl,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seafoam,
          foregroundColor: obsidian,
          disabledBackgroundColor: panelRaised,
          disabledForegroundColor: fog,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pearl,
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelRaised,
        prefixIconColor: fog,
        hintStyle: const TextStyle(color: fog),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: seafoam.withValues(alpha: 0.9), width: 1.4),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: pearl,
        textColor: pearl,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelRaised,
        contentTextStyle: const TextStyle(color: pearl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: panelRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(color: pearl),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panelRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: pearl,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: pearl.withValues(alpha: 0.84),
          height: 1.45,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: panelRaised,
        modalBackgroundColor: panelRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static BoxDecoration heroGradient({
    Color? primary,
    Color? secondary,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          (primary ?? ruby).withValues(alpha: 0.22),
          (secondary ?? seafoam).withValues(alpha: 0.14),
          midnight,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: outline),
      boxShadow: [
        BoxShadow(
          color: (primary ?? ruby).withValues(alpha: 0.14),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  static BoxDecoration softPanel({
    bool highlighted = false,
  }) {
    return BoxDecoration(
      color: highlighted ? panelRaised : panel,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: highlighted
            ? seafoam.withValues(alpha: 0.22)
            : outline.withValues(alpha: 0.9),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}
