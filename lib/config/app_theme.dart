import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF2E7D32); // Green
  static const Color secondaryColor = Color(0xFF1976D2); // Blue
  static const Color accentColor = Color(0xFFFFC107); // Amber
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light grey
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF212121); // Dark grey
  static const Color textSecondaryColor = Color(0xFF757575); // Grey

  // Text styles
  static TextStyle get headingStyle => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      );

  static TextStyle get subheadingStyle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
      );

  static TextStyle get bodyStyle => GoogleFonts.poppins(
        fontSize: 14,
        color: textPrimaryColor,
      );

  static TextStyle get captionStyle => GoogleFonts.poppins(
        fontSize: 12,
        color: textSecondaryColor,
      );

  // ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: TextTheme(
        displayLarge: headingStyle,
        titleLarge: subheadingStyle,
        bodyLarge: bodyStyle,
        bodyMedium: bodyStyle,
        bodySmall: captionStyle,
      ),
    );
  }
}
