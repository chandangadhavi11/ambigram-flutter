import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preview Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('PreviewSection Example')),
        body: Center(
          // Toggle this true/false to show/hide the image background:
          child: PreviewSection(
            imageCount: 5,
            backgroundColor: Colors.grey.shade300,
            firstWord: "Hello",
            secondWord: "World",
            selectedChipIndex: 1,
            showImageBackground: true, // <--- Toggle from here
          ),
        ),
      ),
    );
  }
}

class PreviewSection extends StatefulWidget {
  final int imageCount;
  final Color backgroundColor;
  final String firstWord;
  final String secondWord;
  final int selectedChipIndex;

  /// This variable controls whether each image has a background color or not.
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
  bool _toastShown = false;
  double _rotationAngle = 0.0;
  bool _noInternet = false;

  /// We'll keep a subscription to the connectivity stream so we can react
  /// to changes in real-time.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// This will hold the Future used by the FutureBuilder for fetching images.
  Future<List<Uint8List>>? _imagesFuture;

  @override
  void initState() {
    super.initState();

    // 1. Check internet connectivity on init
    _maybeLoadImages();

    // 2. Listen to connectivity changes in real-time
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
        setState(() {
          _noInternet = true;
          _imagesFuture = null; // So we no longer show old images
        });
      } else {
        // If we currently have no images loaded, load them now.
        // Or you can force a reload if you prefer, depending on your logic.
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
    // If any relevant fields changed, we can re-check or re-fetch
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
    // Cancel the connectivity subscription when the widget is removed
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
  /// If a fetch fails (including if there's no network),
  /// we set `_noInternet = true` to show a message in the UI.
  Future<List<Uint8List>> _loadAllSvgs() async {
    final List<Future<Uint8List>> fetchFutures = [];

    for (int i = 0; i < widget.imageCount; i++) {
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

      fetchFutures.add(
        http.get(Uri.parse(svgUrl)).then((response) {
          if (response.statusCode == 200) {
            return response.bodyBytes;
          } else {
            throw Exception('Failed to load SVG for $letterPair');
          }
        }),
      );
    }

    try {
      return await Future.wait(fetchFutures);
    } catch (e) {
      // If any request fails or no connectivity, handle error
      setState(() {
        _noInternet = true;
      });
      rethrow;
    }
  }

  void _rotatePreview() {
    HapticFeedback.lightImpact();
    setState(() {
      _rotationAngle += pi; // Rotate 180°
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no images are requested, show "CLICK ON GENERATE..."
    if (widget.imageCount == 0) {
      return Container(
        width: double.infinity,
        height: 220,
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "CLICK ON GENERATE TO PREVIEW",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      );
    }

    // If there's no internet, show "Please connect to internet..."
    if (_noInternet) {
      return Container(
        width: double.infinity,
        height: 220,
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "PLEASE CONNECT TO INTERNET TO GENERATE AMBIGRAM",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      );
    }

    // Otherwise, show the FutureBuilder
    return GestureDetector(
      onTap: _rotatePreview,
      child: AnimatedRotation(
        turns: _rotationAngle / (2 * pi),
        duration: const Duration(milliseconds: 300),
        child: FutureBuilder<List<Uint8List>>(
          future: _imagesFuture,
          builder: (context, snapshot) {
            // If the Future is null or not complete, show "LOADING..."
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              );
            }

            // We have successfully loaded data
            final svgBytesList = snapshot.data!;

            return Container(
              width: double.infinity,
              height: 220,
              color: widget.backgroundColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 60,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (!_toastShown &&
                            scrollInfo is ScrollStartNotification) {
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
                            final firstLetter =
                                widget.firstWord[index].toLowerCase();
                            final secondLetter =
                                widget.secondWord.isNotEmpty
                                    ? widget
                                        .secondWord[widget.secondWord.length -
                                            1 -
                                            index]
                                        .toLowerCase()
                                    : widget
                                        .firstWord[widget.firstWord.length -
                                            1 -
                                            index]
                                        .toLowerCase();

                            final isFlipped =
                                firstLetter.compareTo(secondLetter) > 0;
                            final svgWidget = SvgPicture.memory(
                              svgBytesList[index],
                              height: 60,
                              fit: BoxFit.fitHeight,
                            );

                            // Wrap each image in a background container if showImageBackground is true
                            return Container(
                              color:
                                  widget.showImageBackground
                                      ? Colors.amber.withOpacity(
                                        0.2,
                                      ) // Example color
                                      : Colors.transparent,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.all(4),
                              child:
                                  isFlipped
                                      ? Transform.rotate(
                                        angle: pi,
                                        child: svgWidget,
                                      )
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
          },
        ),
      ),
    );
  }
}
