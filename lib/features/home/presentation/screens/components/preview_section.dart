import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PreviewSection extends StatefulWidget {
  final int imageCount;
  final Color backgroundColor;
  final String firstWord;
  final String secondWord;
  final int selectedChipIndex;
  final bool showImageBackground;

  const PreviewSection({
    Key? key,
    required this.imageCount,
    required this.backgroundColor,
    required this.firstWord,
    required this.secondWord,
    required this.selectedChipIndex,
    required this.showImageBackground,
  }) : super(key: key);

  @override
  _PreviewSectionState createState() => _PreviewSectionState();
}

class _PreviewSectionState extends State<PreviewSection> {
  bool _noInternet = false;
  double _rotationAngle = 0.0;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<List<Uint8List?>>?
  _imagesFuture; // store Uint8List? instead of Uint8List

  @override
  void initState() {
    super.initState();
    _maybeLoadImages();

    // Listen for connectivity changes:
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
        setState(() {
          _noInternet = true;
          _imagesFuture = null; // Clear old data
        });
      } else {
        setState(() {
          _noInternet = false;
          if (widget.imageCount > 0) {
            _imagesFuture = _loadAllSvgs();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant PreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If any relevant fields changed, re-fetch:
    if (widget.imageCount != oldWidget.imageCount ||
        widget.firstWord != oldWidget.firstWord ||
        widget.secondWord != oldWidget.secondWord ||
        widget.selectedChipIndex != oldWidget.selectedChipIndex ||
        widget.showImageBackground != oldWidget.showImageBackground) {
      setState(() {
        _imagesFuture = null;
        _maybeLoadImages();
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Checks connectivity once and, if online, sets `_imagesFuture`.
  Future<void> _maybeLoadImages() async {
    if (widget.imageCount == 0) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _noInternet = true;
      });
    } else {
      setState(() {
        _noInternet = false;
        _imagesFuture = _loadAllSvgs();
      });
    }
  }

  /// Fetch all SVGs and return them as a list of bytes.
  /// If a single request fails, store `null` for that index,
  /// so we can still show partial results for the rest.
  Future<List<Uint8List?>> _loadAllSvgs() async {
    final List<Future<Uint8List?>> fetchFutures = [];

    for (int i = 0; i < widget.imageCount; i++) {
      fetchFutures.add(_fetchSvgBytes(i));
    }

    return Future.wait(fetchFutures);
  }

  /// Safely fetch the SVG for index `i`. Returns `null` if fetch fails.
  Future<Uint8List?> _fetchSvgBytes(int i) async {
    try {
      final firstLetter = widget.firstWord[i].toLowerCase();
      final secondLetter =
          widget.secondWord.isNotEmpty
              ? widget.secondWord[widget.secondWord.length - 1 - i]
                  .toLowerCase()
              : widget.firstWord[widget.firstWord.length - 1 - i].toLowerCase();

      final isFlipped = firstLetter.compareTo(secondLetter) > 0;
      final letterPair =
          isFlipped ? '$secondLetter$firstLetter' : '$firstLetter$secondLetter';

      final svgUrl =
          'https://d2p3tez4zcgtm0.cloudfront.net/ambigram-${widget.selectedChipIndex}/$letterPair.svg';

      final response = await http.get(Uri.parse(svgUrl));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        // Return null (image fail)
        return null;
      }
    } catch (e) {
      // Return null on any fetch error
      return null;
    }
  }

  void _rotatePreview() {
    HapticFeedback.lightImpact();
    setState(() {
      _rotationAngle += pi; // Rotate 180 degrees
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no images are requested:
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

    // If there's no internet:
    if (_noInternet) {
      return Container(
        width: double.infinity,
        height: 220,
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "PLEASE CONNECT TO INTERNET TO GENERATE AMBIGRAM",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      );
    }

    // Otherwise, show the FutureBuilder
    return GestureDetector(
      onTap: _rotatePreview,
      child: AnimatedRotation(
        turns: _rotationAngle / (2 * pi),
        duration: const Duration(milliseconds: 300),
        child: FutureBuilder<List<Uint8List?>>(
          future: _imagesFuture,
          builder: (context, snapshot) {
            // Show "LOADING..." if waiting:
            if (_imagesFuture == null ||
                snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
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

            // Data loaded: either valid bytes or null for each image
            final svgBytesList = snapshot.data!;

            return Container(
              width: double.infinity,
              height: 220,
              color: widget.backgroundColor,
              padding: const EdgeInsets.all(4),
              // FittedBox with BoxFit.contain prevents cropping
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.imageCount, (index) {
                    final firstLetter = widget.firstWord[index].toLowerCase();
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
                    final isFlipped = firstLetter.compareTo(secondLetter) > 0;

                    final bytes = svgBytesList[index];

                    // If null, show error placeholder
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

                    // Construct the image widget:
                    final svgWidget = SvgPicture.memory(
                      bytes,
                      height: 60,
                      fit: BoxFit.contain,
                    );

                    // Wrap with a background color if needed:
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      padding: const EdgeInsets.all(4),
                      color:
                          widget.showImageBackground
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.transparent,
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
        ),
      ),
    );
  }
}
