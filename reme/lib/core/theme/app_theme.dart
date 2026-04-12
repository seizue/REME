import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand accent — rgb(126, 85, 55)
  static const Color primary = Color(0xFF7E5537);
  static const Color secondary = Color(0xFF9E7255);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color priceUp = Color(0xFFEF5350);
  static const Color priceDown = Color(0xFF4CAF50);

  // ── Light palette ────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF2F2F7); // iOS-style neutral grey
  static const Color lightSurface = Color(0xFFFFFFFF); // pure white cards
  static const Color lightSurfaceVariant = Color(0xFFE8E8ED);
  static const Color lightOnSurface = Color(0xFF1C1C1E); // near-black text
  static const Color lightOnSurfaceMuted = Color(0xFF6C6C70);

  // ── AMOLED dark palette ──────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF000000); // true black
  static const Color darkSurface = Color(0xFF0D0D0D); // near-black cards
  static const Color darkSurfaceVariant = Color(0xFF1A1A1A);
  static const Color darkOnSurface = Color(0xFFF5E6CC); // warm white text
  static const Color darkOnSurfaceMuted = Color(0xFF8A7A60);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBg : lightBg;
    final surface = isDark ? darkSurface : lightSurface;
    final surfaceVariant = isDark ? darkSurfaceVariant : lightSurfaceVariant;
    final onSurface = isDark ? darkOnSurface : lightOnSurface;
    final onSurfaceMuted = isDark ? darkOnSurfaceMuted : lightOnSurfaceMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.poppinsTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkBg : lightSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: onSurfaceMuted),
        hintStyle: TextStyle(color: onSurfaceMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? darkBg : lightSurface,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? primary : onSurfaceMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primary : onSurfaceMuted);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? darkBg : lightSurface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: isDark ? 0 : 8,
      ),
      dividerTheme: DividerThemeData(color: surfaceVariant, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle: TextStyle(color: onSurface, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: onSurfaceMuted,
        labelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }
}

extension ThemeColors on BuildContext {
  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surfaceVariant =>
      isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant;

  Color get onSurfaceMuted =>
      isDark ? AppTheme.darkOnSurfaceMuted : AppTheme.lightOnSurfaceMuted;
}
