import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmbigramButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback? onClick; // Optional additional onClick callback.
  final String text;

  const AmbigramButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.onClick,
  });

  @override
  _AmbigramButtonState createState() => _AmbigramButtonState();
}

class _AmbigramButtonState extends State<AmbigramButton> {
  double _opacity = 1.0;

  void _onTapDown(TapDownDetails details) {
    // Decrease opacity to simulate a pressed state.
    setState(() {
      _opacity = 0.6;
    });
  }

  void _onTapUp(TapUpDetails details) {
    // Return opacity back to normal.
    setState(() {
      _opacity = 1.0;
    });
  }

  void _onTapCancel() {
    // Reset opacity if tap is cancelled.
    setState(() {
      _opacity = 1.0;
    });
  }

  void _handleTap() {
    // Provide haptic feedback.
    HapticFeedback.heavyImpact();
    // Trigger the main onPressed callback.
    widget.onPressed();
    // Also call onClick if it is provided.
    if (widget.onClick != null) {
      widget.onClick!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _opacity,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFF2B2734)),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Averta Demo PE Cutted Demo',
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
