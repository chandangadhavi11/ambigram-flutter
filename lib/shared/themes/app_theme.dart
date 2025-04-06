import 'package:flutter/material.dart';
import '../../core/constants/app_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: Color(0xFF2B2734),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Color(0xFFE5E5E5),
    ),
    fontFamily: AppFonts.primaryFont,
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: Color(0xFF2B2734),
    colorScheme: ColorScheme.dark().copyWith(secondary: Color(0xFFE5E5E5)),
    // etc...
  );
}
