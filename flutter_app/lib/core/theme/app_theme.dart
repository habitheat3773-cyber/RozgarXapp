import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors ────────────────────────────────────────────────────────
  static const Color primaryBlue     = Color(0xFF1E3A8A);
  static const Color primaryBlueMid  = Color(0xFF2563EB);
  static const Color primaryBlueLite = Color(0xFF3B82F6);
  static const Color accentOrange    = Color(0xFFF97316);
  static const Color accentOrangeLt  = Color(0xFFFB923C);
  static const Color successGreen    = Color(0xFF22C55E);
  static const Color warningAmber    = Color(0xFFF59E0B);
  static const Color errorRed        = Color(0xFFEF4444);
  static const Color infoCyan        = Color(0xFF06B6D4);

  // ─── Light Theme Colors ──────────────────────────────────────────────────
  static const Color lightBg         = Color(0xFFF0F4FF);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightCard       = Color(0xFFFFFFFF);
  static const Color lightBorder     = Color(0xFFE2E8F0);
  static const Color lightText       = Color(0xFF0F172A);
  static const Color lightTextSub    = Color(0xFF64748B);

  // ─── Dark Theme Colors ───────────────────────────────────────────────────
  static const Color darkBg          = Color(0xFF0B1120);
  static const Color darkSurface     = Color(0xFF0F172A);
  static const Color darkCard        = Color(0xFF1E293B);
  static const Color darkCard2       = Color(0xFF253347);
  static const Color darkBorder      = Color(0xFF334155);
  static const Color darkText        = Color(0xFFF1F5F9);
  static const Color darkTextSub     = Color(0xFF94A3B8);

  // ─── Category Colors ─────────────────────────────────────────────────────
  static const Map<String, Color> categoryColors = {
    'SSC':       Color(0xFF3B82F6),
    'Railway':   Color(0xFF8B5CF6),
    'Banking':   Color(0xFF06B6D4),
    'Defence':   Color(0xFFEF4444),
    'Police':    Color(0xFFF97316),
    'UPSC':      Color(0xFF10B981),
    'State PSC': Color(0xFFF59E0B),
    'Teaching':  Color(0xFFEC4899),
    'Engineering': Color(0xFF6366F1),
    'Medical':   Color(0xFF14B8A6),
    'Other':     Color(0xFF94A3B8),
  };

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentOrange,
        tertiary: primaryBlueLite,
        surface: lightSurface,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightText,
        outline: lightBorder,
      ),
      scaffoldBackgroundColor: lightBg,
      textTheme: _buildTextTheme(lightText, lightTextSub, false),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: lightText),
        titleTextStyle: GoogleFonts.poppins(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: lightTextSub, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBg,
        selectedColor: primaryBlue,
        labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightTextSub,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: primaryBlue.withOpacity(0.12),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: primaryBlue);
          }
          return GoogleFonts.poppins(fontSize: 11, color: lightTextSub);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryBlue);
          }
          return const IconThemeData(color: lightTextSub);
        }),
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primaryBlueLite,
        secondary: accentOrange,
        surface: darkSurface,
        error: errorRed,
        onPrimary: Colors.white,
        onSurface: darkText,
        outline: darkBorder,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: _buildTextTheme(darkText, darkTextSub, true),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.poppins(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlueLite,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlueLite, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: darkTextSub, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primaryBlueLite.withOpacity(0.15),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 1),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary, bool isDark) {
    return TextTheme(
      displayLarge:  GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.w700, color: primary, letterSpacing: -2),
      displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1),
      displaySmall:  GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: primary),
      headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      headlineMedium:GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: primary),
      titleLarge:    GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: primary),
      titleMedium:   GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleSmall:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge:     GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: primary, height: 1.6),
      bodyMedium:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: primary, height: 1.5),
      bodySmall:     GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
      labelLarge:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium:   GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall:    GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}

// ignore: non_constant_identifier_names
SystemUiOverlayStyle get SystemUiOverlayStyle => const SystemUiOverlayStyle();
