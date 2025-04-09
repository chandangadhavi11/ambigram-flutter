import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom [TextInputFormatter] that converts input to uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class AmbigramTextInput extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final String? error;

  const AmbigramTextInput({
    super.key,
    this.controller,
    this.hintText = "",
    this.onChanged,
    this.error,
  });

  @override
  _AmbigramTextInputState createState() => _AmbigramTextInputState();
}

class _AmbigramTextInputState extends State<AmbigramTextInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasError = (widget.error?.isNotEmpty ?? false);

    // We’ll maintain the original light-mode border color (#6C6A6E)
    // for light mode and choose something else (like outline) for dark mode.
    final borderColor =
        hasError
            ? theme.colorScheme.error
            : theme.brightness == Brightness.light
            ? const Color(0xFF6C6A6E)
            : theme.colorScheme.outline;

    // Similarly, let's maintain the original text color (#2B2734) for light mode
    // if no error, otherwise rely on theme-based colors.
    final textColor =
        hasError
            ? theme.colorScheme.error
            : theme.brightness == Brightness.light
            ? const Color(0xFF2B2734)
            : theme.colorScheme.onSurface;

    // For background, we can use the theme’s surface color or any other
    // color that suits dark mode vs. light mode.
    final backgroundColor = theme.colorScheme.surface;

    Widget textField = Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.5, color: borderColor),
        ),
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        onChanged: (text) {
          // Trigger haptic feedback only for iOS.
          if (Platform.isIOS) HapticFeedback.lightImpact();
          // Convert text to uppercase before propagating.
          final upperText = text.toUpperCase();
          widget.onChanged?.call(upperText);
        },
        inputFormatters: [UpperCaseTextFormatter()],
        textCapitalization: TextCapitalization.characters,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Averta Demo PE Cutted Demo',
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            // Slightly lighter than the primary text color for the hint:
            color: textColor.withOpacity(0.6),
            fontSize: 12,
            fontFamily: 'Averta Demo PE Cutted Demo',
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
          isCollapsed: true,
        ),
      ),
    );

    // Wrap the container with a GestureDetector to focus the input when tapped,
    // triggering haptic feedback only on iOS.
    Widget clickableTextField = GestureDetector(
      onTap: () {
        if (Platform.isIOS) HapticFeedback.lightImpact();
        _focusNode.requestFocus();
      },
      child: textField,
    );

    // If there's an error, display the error text below the field.
    if (hasError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          clickableTextField,
          const SizedBox(height: 8),
          Text(
            widget.error!,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    return clickableTextField;
  }
}
