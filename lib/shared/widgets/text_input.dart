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
    final bool hasError = widget.error?.isNotEmpty ?? false;
    final Color borderColor =
        hasError ? const Color(0xFFE35555) : const Color(0xFF6C6A6E);
    final Color textColor =
        hasError ? const Color(0xFFE35555) : const Color(0xFF2B2734);

    // Build the text field container with the proper styling.
    Widget textField = Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.50, color: borderColor),
        ),
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        onChanged: (text) {
          // Trigger haptic feedback on every change.
          HapticFeedback.lightImpact();
          // Convert text to uppercase before propagating.
          final upperText = text.toUpperCase();
          if (widget.onChanged != null) widget.onChanged!(upperText);
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
            color: textColor,
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
    // trigger haptic feedback, and apply any additional effects.
    Widget clickableTextField = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
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
            style: const TextStyle(
              color: Color(0xFFE35555),
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
