import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_application_1/shared/widgets/custom_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

  // -----------------------------------------
  // InterstitialAd-related fields
  // -----------------------------------------
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  /// Official test adUnitId during development (replace with your own in production)
  final String _testInterstitialAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Android test unit
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS test unit

  // Simple counter to track how many times user shares/saves
  // We'll only show an interstitial after every 3 actions.
  int _ambigramActionsCount = 0;

  // -----------------------------------------
  // BannerAd-related fields
  // -----------------------------------------
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _maybeLoadImages();
    _loadInterstitialAd();
    _loadBannerAd();

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      connectivityResults,
    ) {
      if (connectivityResults.contains(ConnectivityResult.none)) {
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
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  // -----------------------------------------
  // Load the InterstitialAd
  // -----------------------------------------
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _testInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('Interstitial ad loaded.');
          _interstitialAd = ad;
          _isAdLoaded = true;

          // Set callbacks for full screen content
          _interstitialAd
              ?.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) => debugPrint('Ad shown.'),
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Ad dismissed.');
              ad.dispose();
              // Optionally load another ad if you want to show multiple times
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('Failed to show interstitial: $err');
              ad.dispose();
              // Optionally load another ad here
              _loadInterstitialAd();
            },
            onAdImpression: (ad) => debugPrint('$ad impression occurred.'),
            onAdClicked: (ad) => debugPrint('Ad clicked.'),
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  // -----------------------------------------
  // Show the InterstitialAd if loaded + freq. cap
  // -----------------------------------------
  Future<void> _tryShowInterstitialAd() async {
    if (_interstitialAd != null && _isAdLoaded) {
      _interstitialAd!.show();
      _isAdLoaded = false; // The ad can only be shown once
    } else {
      debugPrint('Interstitial ad not ready yet.');
    }
  }

  // -----------------------------------------
  // Load the BannerAd
  // -----------------------------------------
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      size: AdSize.largeBanner, // Use a large banner (e.g. 320x100)
      adUnitId:
          Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/6300978111' // Android test banner unit
              : 'ca-app-pub-3940256099942544/2934735716', // iOS test banner unit
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('Banner ad loaded.');
          setState(() => _isBannerAdLoaded = true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  // -----------------------------------------
  // Letters logic / fetching
  // -----------------------------------------
  Future<void> _maybeLoadImages() async {
    final imageCount =
        widget.firstWord.isNotEmpty ? widget.firstWord.length : 0;
    if (imageCount == 0) return; // No images needed

    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults == ConnectivityResult.none) {
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

  Future<List<Uint8List?>> _loadAllSvgs(int imageCount) async {
    final fetchFutures = <Future<Uint8List?>>[];
    for (int i = 0; i < imageCount; i++) {
      fetchFutures.add(_fetchSvgBytes(i));
    }
    return Future.wait(fetchFutures);
  }

  Future<Uint8List?> _fetchSvgBytes(int i) async {
    try {
      final firstLetter = widget.firstWord[i].toLowerCase();

      // If secondWord is empty, use reversed firstWord letter.
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

  /// Share the captured screenshot
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = File('${directory.path}/screenshot_$timestamp.png');
      await imagePath.writeAsBytes(_capturedImage!);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text:
            'Check out my ambigram! Download the app here: https://example.com',
      );

      // Increase the actions counter.
      _ambigramActionsCount++;
      // If the user has hit 3 actions, show the interstitial (frequency cap).
      if (_ambigramActionsCount % 2 == 0) {
        _tryShowInterstitialAd();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error while sharing: $e')));
    }
  }

  /// Save the screenshot to the gallery
  Future<void> _saveToGallery() async {
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

      // Increase the actions counter.
      _ambigramActionsCount++;
      // Show the interstitial only after every 3 successful saves or shares.
      if (_ambigramActionsCount % 2 == 0) {
        _tryShowInterstitialAd();
      }
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
    final imageCount =
        widget.firstWord.isNotEmpty ? widget.firstWord.length : 0;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child:
            _isBannerAdLoaded
                ? Container(
                  color: Colors.transparent,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
                : const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Custom back button at top-left
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // Texts at the top, left aligned
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'YOU CAN DOWNLOAD THE',
                        style: TextStyle(
                          color: Color(0xFF959398),
                          fontSize: 12,
                          fontFamily: 'Averta Demo PE Cutted Demo',
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PREVIEW',
                        style: TextStyle(
                          color: Color(0xFF2B2733),
                          fontSize: 20,
                          fontFamily: 'Averta Demo PE Cutted Demo',
                          fontWeight: FontWeight.w400,
                          letterSpacing: 4,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),

              // Wrap preview in Screenshot so we can capture it
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
                  onPressed:
                      _noInternet
                          ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No internet connection. Cannot share.',
                                ),
                              ),
                            );
                          }
                          : _shareScreenshot,
                  text: 'SHARE YOUR AMBIGRAM',
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AmbigramButton(
                  onPressed:
                      _noInternet
                          ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No internet connection. Cannot save.',
                                ),
                              ),
                            );
                          }
                          : _saveToGallery,
                  text: 'SAVE IN GALLERY',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Core preview-building code
  Widget _buildPreview(Color backgroundColor, int imageCount) {
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

    return FutureBuilder<List<Uint8List?>>(
      future: _imagesFuture,
      builder: (context, snapshot) {
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

                // If null, show placeholder
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

                final svgWidget = SvgPicture.memory(
                  bytes,
                  height: 300,
                  fit: BoxFit.contain,
                );

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
