import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/shared/widgets/text_input.dart';
import 'package:flutter_application_1/shared/widgets/custom_button.dart';

/// Displays the input fields for the words and the "GENERATE" / "DOWNLOAD" button.
class InputSection extends StatefulWidget {
  final void Function(String firstWord, String secondWord) onGenerate;
  final bool hasGenerated;
  final VoidCallback onDownload;
  final VoidCallback onInputChanged;

  const InputSection({
    Key? key,
    required this.onGenerate,
    required this.hasGenerated,
    required this.onDownload,
    required this.onInputChanged,
  }) : super(key: key);

  @override
  State<InputSection> createState() => _InputSectionState();
}

class _InputSectionState extends State<InputSection> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();

  String? _firstError;
  String? _secondError;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    // Remove field errors once user starts typing
    _firstController.addListener(() {
      if (_firstError != null) {
        setState(() => _firstError = null);
      }
      // If user had already generated, revert the button back to "GENERATE"
      if (widget.hasGenerated) {
        widget.onInputChanged();
      }
    });
    _secondController.addListener(() {
      if (_secondError != null) {
        setState(() => _secondError = null);
      }
      // If user had already generated, revert the button back to "GENERATE"
      if (widget.hasGenerated) {
        widget.onInputChanged();
      }
    });
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final firstWord = _firstController.text.trim();
    final secondWord = _secondController.text.trim();

    _firstError = null;
    _secondError = null;

    // 1) Non-empty check for first word
    if (firstWord.isEmpty) {
      _firstError =
          "YOU HAVEN'T ENTERED YOUR FIRST WORD YET. PLEASE TYPE SOMETHING!";
    } else {
      // 2) Check length constraints & only letters
      if (firstWord.length < 2) {
        _firstError = "YOUR FIRST WORD MUST HAVE AT LEAST 2 LETTERS.";
      } else if (firstWord.length > 12) {
        _firstError = "YOUR FIRST WORD CAN’T BE LONGER THAN 12 LETTERS.";
      } else if (!RegExp(r'^[A-Za-z]+$').hasMatch(firstWord)) {
        _firstError =
            "PLEASE USE LETTERS (A–Z) ONLY, NO NUMBERS OR SPECIAL CHARACTERS.";
      }
    }

    // 3) If the second word is not empty, check constraints
    if (secondWord.isNotEmpty) {
      if (secondWord.length < 2) {
        _secondError = "YOUR SECOND WORD MUST HAVE AT LEAST 2 LETTERS.";
      } else if (secondWord.length > 12) {
        _secondError = "YOUR SECOND WORD CAN’T BE LONGER THAN 12 LETTERS.";
      } else if (!RegExp(r'^[A-Za-z]+$').hasMatch(secondWord)) {
        _secondError =
            "PLEASE USE LETTERS (A–Z) ONLY, NO NUMBERS OR SPECIAL CHARACTERS.";
      } else {
        // 4) If second word is present, it must match the first word's length
        if (_firstError == null && firstWord.length != secondWord.length) {
          _secondError =
              "SECOND WORD MUST MATCH THE FIRST WORD'S LENGTH IF USED.";
        }
      }
    }

    return _firstError == null && _secondError == null;
  }

  @override
  Widget build(BuildContext context) {
    final firstErrorToShow = _showErrors ? _firstError : null;
    final secondErrorToShow = _showErrors ? _secondError : null;

    final buttonLabel = widget.hasGenerated ? "DOWNLOAD AMBIGRAM" : "GENERATE";

    return Column(
      children: [
        AmbigramTextInput(
          controller: _firstController,
          hintText: "ENTER FIRST WORD",
          error: firstErrorToShow,
        ),
        const SizedBox(height: 16),
        AmbigramTextInput(
          controller: _secondController,
          hintText: "ENTER SECOND WORD (OPTIONAL)",
          error: secondErrorToShow,
        ),
        const SizedBox(height: 20),
        AmbigramButton(
          text: buttonLabel,
          onPressed: () {
            HapticFeedback.mediumImpact();
            // If already generated, user wants to "DOWNLOAD AMBIGRAM"
            if (widget.hasGenerated) {
              widget.onDownload();
            } else {
              // Otherwise, do "GENERATE" logic
              setState(() => _showErrors = true);
              if (_validateInputs()) {
                widget.onGenerate(
                  _firstController.text.trim(),
                  _secondController.text.trim(),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
