import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'animated_selectable_chip.dart';
import 'package:flutter_application_1/core/constants/app_colors.dart';

/// Header section that shows the "CREATE YOUR OWN AMBIGRAM" title,
/// the user's remaining credits, and the horizontal list of chips.
class HeaderSection extends StatefulWidget {
  final int credits;
  final List<String> chipLabels;
  final int selectedChipIndex;
  final ValueChanged<int> onChipSelected;

  const HeaderSection({
    Key? key,
    required this.credits,
    required this.chipLabels,
    required this.selectedChipIndex,
    required this.onChipSelected,
  }) : super(key: key);

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  final List<GlobalKey> _chipKeys = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // create a key for each label
    _chipKeys.addAll(widget.chipLabels.map((_) => GlobalKey()).toList());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onChipTap(int index) {
    // Scroll the tapped chip into view
    final ctx = _chipKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        alignment: 0.5,
      );
    }

    // Notify parent
    widget.onChipSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final credits = widget.credits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // space between two children
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title area
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CREATE YOUR OWN ',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    fontFamily: 'Averta Demo PE Cutted Demo',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AMBIGRAM',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 20,
                    fontFamily: 'Averta Demo PE Cutted Demo',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            // Credits area
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/flash_icon.svg',
                  width: 14,
                  height: 14,
                  semanticsLabel: 'Icon',
                ),
                const SizedBox(width: 4),
                Text(
                  '$credits',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 12,
                    fontFamily: 'Averta Demo PE Cutted Demo',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none, // <-- Make horizontal overflow visible
          child: Row(
            children: List.generate(widget.chipLabels.length, (index) {
              final label = widget.chipLabels[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AnimatedSelectableChip(
                  key: _chipKeys[index],
                  label: label,
                  delay: Duration(milliseconds: 100 * index),
                  isSelected: widget.selectedChipIndex == index,
                  onTap: () => _onChipTap(index),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
