import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores principais
  static const Color primaryColor = Color(0xFFF97316); // Laranja principal
  static const Color scaffoldBackgroundColor = Color(0xFF121212); // Cinza quase preto (mais profundo)
  static const Color cardColor = Color(0xFF1E1E1E); // Superfície elevada
  static const Color inputFillColor = Color(0xFF252525);

  // Cores de Status (Semanticas)
  static const Color successColor = Color(0xFF10B981); // Verde esmeralda
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color infoColor = Color(0xFF3B82F6);    // Blue
  static const Color errorColor = Color(0xFFEF4444);   // Rose/Red

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    final textTheme = GoogleFonts.interTextTheme(
      baseTheme.textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: cardColor,
        onSurface: Colors.white,
        error: errorColor,
        surfaceContainer: cardColor, // Para Material 3
      ),
      
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Cards mais arredondados
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: cardColor,
      ),

      // TEMA DE CHIPS (Importante para os filtros que adicionamos)
      chipTheme: ChipThemeData(
        backgroundColor: inputFillColor,
        selectedColor: primaryColor.withValues(alpha: 0.2),
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
        secondaryLabelStyle: const TextStyle(fontSize: 12, color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        checkmarkColor: primaryColor,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.all(16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: errorColor, width: 1.0),
        ),
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIconColor: Colors.grey[500],
        suffixIconColor: Colors.grey[500],
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 24,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return Colors.white10;
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Colors.white10,
        circularTrackColor: Colors.white10,
      ),
    );
  }
}
