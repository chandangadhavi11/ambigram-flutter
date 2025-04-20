import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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
  // ─────────────────────────────────────────────────────────────
  // STATIC APP‑STORE LINKS – replace with your real URLs
  // ─────────────────────────────────────────────────────────────
  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.yourcompany.yourapp';
  static const String _iosStoreUrl = 'https://apps.apple.com/app/id0000000000';

  // Screenshot controller to capture the final widget image
  final ScreenshotController _screenshotController = ScreenshotController();
  Uint8List? _capturedImage;

  // For 180° rotation
  double _rotationAngle = 0.0;

  // Connectivity
  bool _noInternet = false;
  Future<List<Uint8List?>>? _imagesFuture;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Native channel for gallery saving
  static const MethodChannel _methodChannel = MethodChannel('gallery_saver');

  // ──────────────── Google Mobile Ads (interstitial + banner) ────────────────
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  final String _testInterstitialAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';

  int _ambigramActionsCount = 0; // frequency capping

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // ────────────────────────────── lifecycle ──────────────────────────────
  @override
  void initState() {
    super.initState();
    _maybeLoadImages();
    _loadInterstitialAd();
    _loadBannerAd();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      connectivityResults,
    ) {
      if (connectivityResults.contains(ConnectivityResult.none)) {
        setState(() {
          _noInternet = true;
          _imagesFuture = null;
        });
      } else {
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

  // ─────────────────────────── Ads helpers ─────────────────────────────
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _testInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoaded = false;
        },
      ),
    );
  }

  Future<void> _tryShowInterstitialAd() async {
    if (_interstitialAd != null && _isAdLoaded) {
      await _interstitialAd!.show();
      _isAdLoaded = false;
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      size: AdSize.largeBanner,
      adUnitId:
          Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/6300978111'
              : 'ca-app-pub-3940256099942544/2934735716',
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
      request: const AdRequest(),
    )..load();
  }

  // ─────────────── Image‑fetch helpers ───────────────
  Future<void> _maybeLoadImages() async {
    final imageCount =
        widget.firstWord.isNotEmpty ? widget.firstWord.length : 0;
    if (imageCount == 0) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
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

  Future<List<Uint8List?>> _loadAllSvgs(int count) async =>
      Future.wait(List.generate(count, _fetchSvgBytes));

  Future<Uint8List?> _fetchSvgBytes(int i) async {
    try {
      final firstLetter = widget.firstWord[i].toLowerCase();
      final secondLetter =
          widget.secondWord.isNotEmpty
              ? widget.secondWord[widget.secondWord.length - 1 - i]
                  .toLowerCase()
              : widget.firstWord[widget.firstWord.length - 1 - i].toLowerCase();

      final isFlipped = firstLetter.compareTo(secondLetter) > 0;
      final pair =
          isFlipped ? '$secondLetter$firstLetter' : '$firstLetter$secondLetter';
      final uri = Uri.parse(
        'https://d2p3tez4zcgtm0.cloudfront.net/ambigram-${widget.selectedChipIndex}/$pair.svg',
      );

      final res = await http.get(uri);
      return res.statusCode == 200 ? res.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  // ─────────────── UI helpers ───────────────
  void _rotatePreview() {
    HapticFeedback.lightImpact();
    setState(() => _rotationAngle += pi);
  }

  Future<void> _captureScreenshot() async {
    final image = await _screenshotController.capture();
    if (image != null) setState(() => _capturedImage = image);
  }

  // ────────────────────────────── SHARE with dynamic link ──────────────────────────────
  Future<void> _shareScreenshot() async {
    if (_capturedImage == null) await _captureScreenshot();
    if (_capturedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No screenshot to share.')));
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/ambigram_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(path).writeAsBytes(_capturedImage!);

      // Choose correct store link
      final String storeUrl = Platform.isIOS ? _iosStoreUrl : _androidStoreUrl;

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out my ambigram! Download the app here: $storeUrl');

      _ambigramActionsCount++;
      if (_ambigramActionsCount % 2 == 0) _tryShowInterstitialAd();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error while sharing: $e')));
    }
  }

  Future<void> _saveToGallery() async {
    if (_capturedImage == null) await _captureScreenshot();
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

      _ambigramActionsCount++;
      if (_ambigramActionsCount % 2 == 0) _tryShowInterstitialAd();
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image to gallery: $e')),
      );
    }
  }

  // ────────────────────────────── build ──────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bgColor =
        ColorPalette.backgroundChoices(context)[widget
            .selectedColorIndex].color;
    final count = widget.firstWord.isNotEmpty ? widget.firstWord.length : 0;

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
              // back button
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
              // header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'YOU CAN DOWNLOAD THE',
                        style: TextStyle(
                          color: Color(0xFF959398),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PREVIEW',
                        style: TextStyle(
                          color: Color(0xFF2B2733),
                          fontSize: 20,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // preview (tap to rotate)
              Screenshot(
                controller: _screenshotController,
                child: GestureDetector(
                  onTap: _rotatePreview,
                  child: AnimatedRotation(
                    turns: _rotationAngle / (2 * pi),
                    duration: const Duration(milliseconds: 300),
                    child: _buildPreview(bgColor, count),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // share / save buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AmbigramButton(
                  onPressed:
                      _noInternet
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No internet connection. Cannot share.',
                              ),
                            ),
                          )
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
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No internet connection. Cannot save.',
                              ),
                            ),
                          )
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

  // ────────────────────────────── preview builder ──────────────────────────────
  Widget _buildPreview(Color bgColor, int count) {
    if (count == 0) {
      return _placeholder(bgColor, 'CLICK ON GENERATE TO PREVIEW');
    }
    if (_noInternet) {
      return _placeholder(
        bgColor,
        'PLEASE CONNECT TO INTERNET TO GENERATE AMBIGRAM',
      );
    }

    return FutureBuilder<List<Uint8List?>>(
      future: _imagesFuture,
      builder: (context, snapshot) {
        if (_imagesFuture == null ||
            snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return _placeholder(bgColor, 'LOADING...');
        }

        final bytesList = snapshot.data!;
        return Container(
          width: double.infinity,
          height: 220,
          color: bgColor,
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(count, (index) {
                final first = widget.firstWord[index].toLowerCase();
                final second =
                    widget.secondWord.isNotEmpty
                        ? widget
                            .secondWord[widget.secondWord.length - 1 - index]
                            .toLowerCase()
                        : widget.firstWord[widget.firstWord.length - 1 - index]
                            .toLowerCase();
                final isFlipped = first.compareTo(second) > 0;
                final bytes = bytesList[index];

                if (bytes == null) {
                  return Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: Colors.red.shade100,
                    alignment: Alignment.center,
                    child: const Text(
                      'ERR',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  );
                }

                final svg = SvgPicture.memory(
                  bytes,
                  height: 300,
                  fit: BoxFit.contain,
                );
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  padding: const EdgeInsets.all(4),
                  child:
                      isFlipped ? Transform.rotate(angle: pi, child: svg) : svg,
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder(Color bg, String text) => Container(
    width: double.infinity,
    height: 220,
    color: bg,
    alignment: Alignment.center,
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    ),
  );
}
