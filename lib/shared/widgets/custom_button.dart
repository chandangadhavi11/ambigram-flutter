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
    widget.onClick?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Keep the original color (#2B2734) in light mode,
    // and use the theme's primary color in dark mode.
    final Color backgroundColor =
        theme.brightness == Brightness.light
            ? const Color(0xFF2B2734)
            : theme.colorScheme.primary;

    // White text in light mode, and adapt to onPrimary in dark mode.
    final Color textColor =
        theme.brightness == Brightness.light
            ? Colors.white
            : theme.colorScheme.onPrimary;

    return Material(
      // Use Material so that InkWell can paint ripple over it.
      color: backgroundColor,
      child: InkWell(
        onTap: _handleTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        // InkWell gives a default ripple effect on tap.
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _opacity,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            // Add a repeating noise texture image as a background.
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/noise.png'),
                repeat: ImageRepeat.repeat,
                // Optional: adjust fit or color blend modes.
              ),
            ),
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontFamily: 'Averta Demo PE Cutted Demo',
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
