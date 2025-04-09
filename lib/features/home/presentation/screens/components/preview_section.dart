import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_application_1/core/constants/app_colors.dart';

/// Displays the preview area: either a "CLICK ON GENERATE" message,
/// a "LOADING..." indicator, or the actual generated letters.
class PreviewSection extends StatefulWidget {
  final int imageCount;
  final Color backgroundColor;
  final String firstWord;
  final String secondWord;
  final int selectedChipIndex;

  const PreviewSection({
    Key? key,
    required this.imageCount,
    required this.backgroundColor,
    required this.firstWord,
    required this.secondWord,
    required this.selectedChipIndex,
  }) : super(key: key);

  @override
  _PreviewSectionState createState() => _PreviewSectionState();
}

class _PreviewSectionState extends State<PreviewSection> {
  bool _toastShown = false; // Tracks if the toast has been shown
  bool _isLoading = false; // Tracks if we are in the "LOADING..." phase
  double _rotationAngle = 0.0; // Tracks the current rotation angle in radians

  @override
  void didUpdateWidget(covariant PreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If previously there were zero images, and now there's some positive number,
    // trigger the loading phase for 2 seconds.
    if (oldWidget.imageCount == 0 && widget.imageCount > 0) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }

    // If the user changes the selectedChipIndex, also show loading for 2 seconds.
    if (oldWidget.selectedChipIndex != widget.selectedChipIndex) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  // Called when the preview section is tapped.
  void _rotatePreview() {
    // create a haptic feedback
    HapticFeedback.lightImpact();
    setState(() {
      _rotationAngle += pi; // Increase rotation by 180 degrees (pi radians)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire container in a GestureDetector to rotate on tap.
    return GestureDetector(
      onTap: _rotatePreview,
      child: AnimatedRotation(
        turns: _rotationAngle / (2 * pi), // Convert radians to "turns"
        duration: const Duration(milliseconds: 300),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // If still zero images, just show "CLICK ON GENERATE TO PREVIEW"
    if (widget.imageCount == 0) {
      return Container(
        width: double.infinity,
        height: 220,
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "CLICK ON GENERATE TO PREVIEW",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      );
    }

    // If in loading phase, show "LOADING..."
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 220,
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "LOADING...",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      );
    }

    // Otherwise, show the generated letters
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(color: widget.backgroundColor),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 60,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                // Show a toast ONCE when user starts scrolling horizontally
                if (!_toastShown && scrollInfo is ScrollStartNotification) {
                  Fluttertoast.showToast(
                    msg: "YOU CAN SCROLL THROUGH THE IMAGES",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  _toastShown = true;
                }
                return false;
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: List.generate(widget.imageCount, (index) {
                    final firstLetter = widget.firstWord[index].toLowerCase();

                    // If secondWord is supplied, we match from the end:
                    // else fallback to the reversed letter of the firstWord
                    final secondLetter =
                        widget.secondWord.isNotEmpty
                            ? widget
                                .secondWord[widget.secondWord.length -
                                    1 -
                                    index]
                                .toLowerCase()
                            : widget
                                .firstWord[widget.firstWord.length - 1 - index]
                                .toLowerCase();

                    // Determine if letters should be flipped
                    final isFlipped = firstLetter.compareTo(secondLetter) > 0;

                    // Build the letter pair
                    final letterPair =
                        isFlipped
                            ? "$secondLetter$firstLetter"
                            : "$firstLetter$secondLetter";

                    // Build the final URL
                    final svgUrl =
                        "https://d2p3tez4zcgtm0.cloudfront.net/ambigram-${widget.selectedChipIndex}/$letterPair.svg";

                    // The SVG widget
                    final svgWidget = SvgPicture.network(
                      svgUrl,
                      height: 60,
                      fit: BoxFit.fitHeight,
                    );

                    // If the letters are flipped, rotate 180°
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child:
                          isFlipped
                              ? Transform.rotate(angle: pi, child: svgWidget)
                              : svgWidget,
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
