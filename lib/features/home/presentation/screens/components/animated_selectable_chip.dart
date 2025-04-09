import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/constants/app_colors.dart';

/// An animated chip that fades in and has a selected/unselected state.
class AnimatedSelectableChip extends StatefulWidget {
  final String label;
  final Duration delay;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimatedSelectableChip({
    Key? key,
    required this.label,
    required this.delay,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  _AnimatedSelectableChipState createState() => _AnimatedSelectableChipState();
}

class _AnimatedSelectableChipState extends State<AnimatedSelectableChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeInController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _fadeInAnimation = CurvedAnimation(
    parent: _fadeInController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    // Trigger the fade-in after [widget.delay]
    Future.delayed(widget.delay, () {
      if (mounted) _fadeInController.forward();
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isSelected
            ? AppColors.chipSelectedBg(context)
            : AppColors.chipUnselectedBg(context);

    final border =
        widget.isSelected
            ? null
            : Border.all(color: AppColors.borderColor(context), width: 0.5);

    final textColor = AppColors.chipText(context, widget.isSelected);

    return FadeTransition(
      opacity: _fadeInAnimation,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            border: border,
            boxShadow:
                widget.isSelected
                    ? const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 16,
                        offset: Offset(0, 10),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontFamily: 'Averta Demo PE Cutted Demo',
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
