// app_colors.dart
import 'package:flutter/material.dart';

/// A helper class to supply colors depending on
/// whether the app is in light mode or dark mode.

class AppColors {
  /// For main text content:
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF2B2734);
  }

  /// For secondary text content:
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB5B5B5)
        : const Color(0xFF959398);
  }

  /// For thin borders / outlines in light or dark mode:
  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFA9A6AF) // or tweak to your preference
        : const Color(0xFFA9A6AF);
  }

  /// For chips when they are not selected:
  static Color chipUnselectedBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors
            .transparent // tweak to your preference
        : Colors.transparent;
  }

  /// For chips when they are selected:
  static Color chipSelectedBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF2F2F2) // lighter background in dark mode
        : const Color(0xFF2B2734); // dark background in light mode
  }

  /// Text color inside chips:
  static Color chipText(BuildContext context, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSelected) {
      return isDark ? const Color(0xFF2B2734) : Colors.white;
    } else {
      return isDark ? const Color(0xFFF2F2F2) : const Color(0xFF2B2734);
    }
  }

  /// Background color for the preview section:
  static Color previewBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF454545) // or tweak to preference for dark
        : const Color(0xFF2B2734); // original color for light mode
  }

  /// Dynamic color for label text in the "BACKGROUND COLOR" row:
  static Color labelText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF2B2734);
  }

  /// The color options shown in the "ColorSelectionSection":
  static List<Color> backgroundChoices(BuildContext context) {
    // You can decide if you want to change these drastically for dark mode,
    // or keep them the same. Example below:

    return [
      // In light mode, we used these; same for dark mode, but feel free to adjust.
      const Color(0xFF2B2734),
      const Color(0xFFE35555),
      const Color(0xFF6C6A6E),
      const Color(0xFF959398),
      const Color(0xFFA9A6AF),
    ];
  }
}
