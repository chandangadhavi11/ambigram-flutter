import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_application_1/core/constants/app_colors.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';

/// Displays a horizontal list of selectable background colors.
class ColorSelectionSection extends StatelessWidget {
  /// The list of colors you want to display.
  /// Comes straight from Remote Config (or the local fallback).
  final List<NamedColor> colors;

  /// Currently‑selected index in [colors].
  final int selectedColorIndex;

  /// Callback when the user taps a swatch.
  final ValueChanged<int> onColorSelected;

  const ColorSelectionSection({
    Key? key,
    required this.colors,
    required this.selectedColorIndex,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely get the currently selected color's name (for the right‑hand label).
    final String selectedColorName =
        (selectedColorIndex >= 0 && selectedColorIndex < colors.length)
            ? colors[selectedColorIndex].name.toUpperCase()
            : 'UNKNOWN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and label.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/color_icon_light.svg',
                  width: 16,
                  height: 16,
                  semanticsLabel: 'Color Icon',
                ),
                const SizedBox(width: 4),
                Text(
                  'BACKGROUND COLOR',
                  style: TextStyle(
                    color: AppColors.labelText(context),
                    fontSize: 12,
                    fontFamily: 'Averta Demo PE Cutted Demo',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            Text(
              selectedColorName,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.labelText(context),
                fontSize: 12,
                fontFamily: 'Averta Demo PE Cutted Demo',
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row of color swatches.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: List.generate(colors.length, (index) {
              final namedColor = colors[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onColorSelected(index);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: ShapeDecoration(
                          color: namedColor.color,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.50,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ),
                      if (selectedColorIndex == index)
                        SvgPicture.asset(
                          'assets/images/tick_icon.svg',
                          width: 10,
                          height: 10,
                          semanticsLabel: 'Tick Icon',
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
