import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NEW: for MethodChannel
import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_application_1/shared/widgets/custom_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class PreviewScreen extends StatefulWidget {
  final String firstWord;
  final String secondWord;
  final int selectedChipIndex;
  final int selectedColorIndex;

  const PreviewScreen({
    Key? key,
    required this.firstWord,
    required this.secondWord,
    required this.selectedChipIndex,
    required this.selectedColorIndex,
  }) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  Uint8List? _capturedImage;

  bool _isLoading = true;
  double _rotationAngle = 0.0;

  /// NEW: Create a method channel to communicate with native code.
  static const MethodChannel _methodChannel = MethodChannel('gallery_saver');

  @override
  void initState() {
    super.initState();
    // Simulate a loading phase.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _rotatePreview() {
    HapticFeedback.lightImpact();
    setState(() {
      _rotationAngle += pi;
    });
  }

  Future<void> _captureScreenshot() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      setState(() {
        _capturedImage = image;
      });
    }
  }

  Future<void> _shareScreenshot() async {
    if (_capturedImage == null) {
      await _captureScreenshot();
    }
    if (_capturedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No screenshot to share.')));
      return;
    }
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = File(
        '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await imagePath.writeAsBytes(_capturedImage!);
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text:
            'Check out my ambigram! Download the app here: https://example.com',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error while sharing: $e')));
    }
  }

  /// NEW: Save the captured screenshot to the device gallery via native code.
  Future<void> _saveToGallery() async {
    // If no image yet, capture a fresh screenshot.
    if (_capturedImage == null) {
      await _captureScreenshot();
    }

    // If still null, show error.
    if (_capturedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No screenshot to save.')));
      return;
    }

    try {
      // Invoke the native function.
      await _methodChannel.invokeMethod('saveImageToGallery', _capturedImage!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery successfully.')),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image to gallery: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        ColorPalette.backgroundChoices(context)[widget
            .selectedColorIndex].color;

    final imageCount = widget.firstWord.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Preview Screen')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Screenshot(
                controller: _screenshotController,
                child: Center(
                  child: GestureDetector(
                    onTap: _rotatePreview,
                    child: AnimatedRotation(
                      turns: _rotationAngle / (2 * pi),
                      duration: const Duration(milliseconds: 300),
                      child: _buildContent(backgroundColor, imageCount),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_capturedImage != null) ...[
                const Text(
                  'Captured Image Preview:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Image.memory(_capturedImage!),
              ],
              const SizedBox(height: 20),

              // Existing share button.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AmbigramButton(
                  onPressed: _shareScreenshot,
                  text: 'SHARE YOU AMBIGRAM',
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AmbigramButton(
                  onPressed: _saveToGallery,
                  text: 'SAVE IN GALLERY',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color backgroundColor, int imageCount) {
    if (imageCount == 0) {
      return Container(
        width: double.infinity,
        height: 220,
        color: backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          'NO WORD WAS ENTERED',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      );
    }

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 220,
        color: backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          'LOADING...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    const containerPadding = 32.0;
    final availableWidth = screenWidth - containerPadding;
    const desiredImageWidth = 60.0;
    final totalImagesWidth = imageCount * desiredImageWidth;

    double scaleFactor = 1.0;
    if (totalImagesWidth > availableWidth) {
      scaleFactor = availableWidth / totalImagesWidth;
    }

    return Container(
      width: double.infinity,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(imageCount, (index) {
          final firstLetter = widget.firstWord[index].toLowerCase();
          final secondLetter =
              widget.secondWord.isNotEmpty
                  ? widget.secondWord[widget.secondWord.length - 1 - index]
                      .toLowerCase()
                  : widget.firstWord[widget.firstWord.length - 1 - index]
                      .toLowerCase();

          final isFlipped = firstLetter.compareTo(secondLetter) > 0;
          final letterPair =
              isFlipped
                  ? '$secondLetter$firstLetter'
                  : '$firstLetter$secondLetter';

          final svgUrl =
              "https://d2p3tez4zcgtm0.cloudfront.net/ambigram-${widget.selectedChipIndex}/$letterPair.svg";

          final svgWidth = desiredImageWidth * scaleFactor;
          final svgWidget = SvgPicture.network(
            svgUrl,
            width: svgWidth,
            fit: BoxFit.fitHeight,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child:
                isFlipped
                    ? Transform.rotate(angle: pi, child: svgWidget)
                    : svgWidget,
          );
        }),
      ),
    );
  }
}
