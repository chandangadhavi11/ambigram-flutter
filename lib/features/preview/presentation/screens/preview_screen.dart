import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:screenshot/screenshot.dart';

// For saving images to gallery:
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

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
  // Screenshot controller
  final ScreenshotController _screenshotController = ScreenshotController();

  // Storage for the captured image
  Uint8List? _capturedImage;

  bool _isLoading = true;
  double _rotationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    // Simulate a 2-second loading phase
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  /// Rotates the preview by 180 degrees each tap
  void _rotatePreview() {
    HapticFeedback.lightImpact();
    setState(() {
      // Rotate 180 degrees each tap (pi radians)
      _rotationAngle += pi;
    });
  }

  /// Capture the current widget as an image and store in memory
  Future<void> _captureAndShowImage() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capture failed. Image is null.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing screenshot: $e')));
    }
  }

  /// Save the captured image to the user's gallery
  Future<void> _saveScreenshotToGallery() async {
    // If we haven't yet captured an image, do so first.
    if (_capturedImage == null) {
      await _captureAndShowImage();
      if (_capturedImage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No screenshot to save!')));
        return;
      }
    }

    // Request permission for Android/iOS
    // For Android 13+ (API 33), consider Permission.photos or Permission.mediaLibrary
    // For older Android, 'Permission.storage' is typical.
    // For iOS, the plugin will automatically handle 'Permission.photos'
    final status = await Permission.storage.request();

    if (status.isGranted) {
      try {
        await FlutterImageGallerySaver.saveImage(_capturedImage!);

        // Since the package often doesn't return a success flag, assume success if no exception
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot saved to gallery!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving screenshot: $e')));
      }
    } else {
      // Handle permission denied or restricted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color from your custom ColorPalette
    final backgroundColor =
        ColorPalette.backgroundChoices(context)[widget
            .selectedColorIndex].color;

    // Number of images is the length of the first word
    final imageCount = widget.firstWord.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Screen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _captureAndShowImage,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // The screenshot portion
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

              // If a captured image is available, display a preview
              if (_capturedImage != null) ...[
                const Text(
                  'Captured Image Preview:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Image.memory(_capturedImage!),
              ],

              const SizedBox(height: 20),

              // Button to save screenshot to gallery
              ElevatedButton(
                onPressed: _saveScreenshotToGallery,
                child: const Text('Save to Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color backgroundColor, int imageCount) {
    // 1. If zero images (first word empty), just show a message
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

    // 2. If still in the 2-second loading phase, show "LOADING..."
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

    // 3. Final ambigram preview
    final screenWidth = MediaQuery.of(context).size.width;
    const containerPadding = 32.0;
    final availableWidth = screenWidth - containerPadding;

    // Desired image width
    const desiredImageWidth = 60.0;
    final totalImagesWidth = imageCount * desiredImageWidth;

    // Scale down if total width of images exceeds available width
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

          // Decide if letters should flip
          final isFlipped = firstLetter.compareTo(secondLetter) > 0;
          final letterPair =
              isFlipped
                  ? '$secondLetter$firstLetter'
                  : '$firstLetter$secondLetter';

          // For example, "https://yourcdn.com/ambigram-0/ab.svg"
          // Adjust with your actual endpoints or local assets
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
