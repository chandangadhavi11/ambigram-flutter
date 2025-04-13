import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_application_1/shared/widgets/custom_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
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
  /// Screenshot controller to capture the final widget image
  final ScreenshotController _screenshotController = ScreenshotController();

  /// Holds the PNG bytes once a screenshot is captured
  Uint8List? _capturedImage;

  /// For rotating the entire preview 180 degrees
  double _rotationAngle = 0.0;

  /// Track if we have internet or not
  bool _noInternet = false;

  /// Future that fetches all SVG bytes
  Future<List<Uint8List?>>? _imagesFuture;

  /// Subscription for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Method channel to call native code to save images to gallery
  static const MethodChannel _methodChannel = MethodChannel('gallery_saver');

  @override
  void initState() {
    super.initState();
    _maybeLoadImages();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
        setState(() {
          _noInternet = true;
          _imagesFuture = null;
        });
      } else {
        // Regain internet
        setState(() {
          _noInternet = false;
          _maybeLoadImages();
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// If there's a word to preview, attempt to load images.
  Future<void> _maybeLoadImages() async {
    final imageCount =
        widget.firstWord.isNotEmpty ? widget.firstWord.length : 0;

    if (imageCount == 0) return; // No images needed

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _noInternet = true;
        _imagesFuture = null;
      });
    } else {
      setState(() {
        _noInternet = false;
        _imagesFuture = _loadAllSvgs(imageCount);
      });
    }
  }

  /// Fetch all letter-pairs in parallel. Returns a list of SVG bytes (or `null` if any fail).
  Future<List<Uint8List?>> _loadAllSvgs(int imageCount) async {
    final fetchFutures = <Future<Uint8List?>>[];
    for (int i = 0; i < imageCount; i++) {
      fetchFutures.add(_fetchSvgBytes(i));
    }
    return Future.wait(fetchFutures);
  }

  /// Fetch a single letter-pair’s SVG from the server and return its bytes (or `null` on error).
  Future<Uint8List?> _fetchSvgBytes(int i) async {
    try {
      final firstLetter = widget.firstWord[i].toLowerCase();

      // If secondWord is empty, we use the reversed firstWord letter.
      final secondLetter =
          widget.secondWord.isNotEmpty
              ? widget.secondWord[widget.secondWord.length - 1 - i]
                  .toLowerCase()
              : widget.firstWord[widget.firstWord.length - 1 - i].toLowerCase();

      // Decide if we need to flip based on alphabetical comparison
      final isFlipped = firstLetter.compareTo(secondLetter) > 0;
      final letterPair =
          isFlipped ? '$secondLetter$firstLetter' : '$firstLetter$secondLetter';

      final svgUrl =
          'https://d2p3tez4zcgtm0.cloudfront.net/ambigram-${widget.selectedChipIndex}/$letterPair.svg';

      final response = await http.get(Uri.parse(svgUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null; // Return null if status is not 200
      }
    } catch (e) {
      return null; // Return null on any fetch error
    }
  }

  /// Rotate the entire preview by 180 degrees
  void _rotatePreview() {
    HapticFeedback.lightImpact();
    setState(() {
      _rotationAngle += pi; // Rotate 180 degrees
    });
  }

  /// Capture screenshot of the entire preview area
  Future<void> _captureScreenshot() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      setState(() {
        _capturedImage = image;
      });
    }
  }

  /// Share the captured screenshot using share_plus
  Future<void> _shareScreenshot() async {
    // Ensure we have a captured image
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = File('${directory.path}/screenshot_$timestamp.png');
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

  /// Use a native MethodChannel to save the screenshot to the gallery
  Future<void> _saveToGallery() async {
    // Capture a fresh screenshot if needed
    if (_capturedImage == null) {
      await _captureScreenshot();
    }

    if (_capturedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No screenshot to save.')));
      return;
    }

    try {
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
    // Derive the same background color used in the home screen's preview
    final backgroundColor =
        ColorPalette.backgroundChoices(context)[widget
            .selectedColorIndex].color;

    // This is the same “imageCount” logic from your PreviewSection
    final imageCount =
        widget.firstWord.isNotEmpty ? widget.firstWord.length : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Preview Screen')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Wrap our preview in Screenshot so we can capture it
              Screenshot(
                controller: _screenshotController,
                child: GestureDetector(
                  onTap: _rotatePreview,
                  child: AnimatedRotation(
                    turns: _rotationAngle / (2 * pi),
                    duration: const Duration(milliseconds: 300),
                    child: _buildPreview(backgroundColor, imageCount),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons for sharing and saving
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AmbigramButton(
                  onPressed: _shareScreenshot,
                  text: 'SHARE YOUR AMBIGRAM',
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

  /// Core preview-building code, copied from _PreviewSectionState for identical look & feel
  Widget _buildPreview(Color backgroundColor, int imageCount) {
    // If user hasn't generated anything yet
    if (imageCount == 0) {
      return Container(
        width: double.infinity,
        height: 220,
        color: backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "CLICK ON GENERATE TO PREVIEW",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      );
    }

    // If we have no internet
    if (_noInternet) {
      return Container(
        width: double.infinity,
        height: 220,
        color: backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "PLEASE CONNECT TO INTERNET TO GENERATE AMBIGRAM",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      );
    }

    // Show a FutureBuilder that attempts to load all the SVGs
    return FutureBuilder<List<Uint8List?>>(
      future: _imagesFuture,
      builder: (context, snapshot) {
        // If _imagesFuture not set or is still loading
        if (_imagesFuture == null ||
            snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return Container(
            width: double.infinity,
            height: 220,
            color: backgroundColor,
            alignment: Alignment.center,
            child: const Text(
              "LOADING...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          );
        }

        // Data has arrived
        final svgBytesList = snapshot.data!;
        return Container(
          width: double.infinity,
          height: 220,
          color: backgroundColor,
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(imageCount, (index) {
                final firstLetter = widget.firstWord[index].toLowerCase();
                final secondLetter =
                    widget.secondWord.isNotEmpty
                        ? widget
                            .secondWord[widget.secondWord.length - 1 - index]
                            .toLowerCase()
                        : widget.firstWord[widget.firstWord.length - 1 - index]
                            .toLowerCase();

                final isFlipped = firstLetter.compareTo(secondLetter) > 0;
                final bytes = svgBytesList[index];

                // If null, show placeholder "ERR"
                if (bytes == null) {
                  return Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.red.shade100,
                    alignment: Alignment.center,
                    child: const Text(
                      "ERR",
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  );
                }

                // Otherwise, show the raw SVG
                final svgWidget = SvgPicture.memory(
                  bytes,
                  height: 300,
                  fit: BoxFit.contain,
                );

                // Flip it if needed
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  padding: const EdgeInsets.all(4),
                  color: Colors.transparent,
                  child:
                      isFlipped
                          ? Transform.rotate(angle: pi, child: svgWidget)
                          : svgWidget,
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
