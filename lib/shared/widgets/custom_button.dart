import 'dart:io' show Platform; // Only used to check for Android
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmbigramButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback? onClick; // Optional additional callback.
  final String text;

  const AmbigramButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.onClick,
  });

  @override
  State<AmbigramButton> createState() => _AmbigramButtonState();
}

class _AmbigramButtonState extends State<AmbigramButton> {
  double _opacity = 1.0;

  // Helpers ------------------------------------------------------------------

  bool get _isAndroid {
    if (kIsWeb) return false; // No system sounds on web
    // `Platform.isAndroid` works everywhere except web; fallback for tests/desktops
    return Platform.isAndroid ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  // Gesture callbacks --------------------------------------------------------

  void _onTapDown(TapDownDetails _) => setState(() => _opacity = 0.6);

  void _onTapUp(TapUpDetails _) => setState(() => _opacity = 1.0);

  void _onTapCancel() => setState(() => _opacity = 1.0);

  void _handleTap() {
    // ▸ 1. Native Android click sound
    if (_isAndroid) {
      SystemSound.play(SystemSoundType.click); // Same sound used by InkWell
    }

    // ▸ 2. Haptic feedback (works on both Android & iOS)
    HapticFeedback.heavyImpact();

    // ▸ 3. Callbacks
    widget.onPressed();
    widget.onClick?.call();
  }

  // Build --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Primary colour logic
    final backgroundColor =
        theme.brightness == Brightness.light
            ? const Color(0xFF2B2734)
            : theme.colorScheme.primary;

    final textColor =
        theme.brightness == Brightness.light
            ? Colors.white
            : theme.colorScheme.onPrimary;

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
          decoration: BoxDecoration(color: backgroundColor),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Averta Demo PE Cutted Demo',
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
            ).copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}
