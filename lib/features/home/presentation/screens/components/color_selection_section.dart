import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_application_1/core/constants/app_colors.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';

/// Displays a horizontal list of selectable background colors.
class ColorSelectionSection extends StatefulWidget {
  final int selectedColorIndex;
  final ValueChanged<int> onColorSelected;

  const ColorSelectionSection({
    Key? key,
    required this.selectedColorIndex,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  _ColorSelectionSectionState createState() => _ColorSelectionSectionState();
}

class _ColorSelectionSectionState extends State<ColorSelectionSection> {
  @override
  Widget build(BuildContext context) {
    final List<NamedColor> colors = ColorPalette.backgroundChoices(context);
    final int selectedIndex = widget.selectedColorIndex;

    // Safely get the currently selected color's name (for display).
    final String selectedColorName =
        (selectedIndex >= 0 && selectedIndex < colors.length)
            ? colors[selectedIndex].name.toUpperCase()
            : 'UNKNOWN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and label.
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/color_icon_light.svg',
                        width: 100.0,
                        height: 100.0,
                        semanticsLabel: 'Color Icon',
                        placeholderBuilder:
                            (BuildContext context) => Container(
                              padding: const EdgeInsets.all(30.0),
                              child: const CircularProgressIndicator(),
                            ),
                      ),
                    ),
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
        ),
        const SizedBox(height: 8),
        // Row of color swatches
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
                    widget.onColorSelected(index);
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
                      if (selectedIndex == index)
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
