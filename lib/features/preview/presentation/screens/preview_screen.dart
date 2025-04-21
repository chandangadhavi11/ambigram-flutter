import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
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
  // ───────────────────────── Remote‑configurable values ─────────────────────────
  // Store links (kept from previous step)
  static const _kDefaultAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.placeholder.android';
  static const _kDefaultIosStoreUrl = 'test';

  late String _androidStoreUrl = _kDefaultAndroidStoreUrl;
  late String _iosStoreUrl = _kDefaultIosStoreUrl;

  // Ad unit IDs (test IDs as sane defaults)
  static const _kDefAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const _kDefIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _kDefAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _kDefIosBanner = 'ca-app-pub-3940256099942544/2934735716';

  late String _androidInterstitialId = _kDefAndroidInterstitial;
  late String _iosInterstitialId = _kDefIosInterstitial;
  late String _androidBannerId = _kDefAndroidBanner;
  late String _iosBannerId = _kDefIosBanner;

  // Firebase Remote Config
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> _initRemoteConfig() async {
    await _remoteConfig.setDefaults({
      'android_store_url': _kDefaultAndroidStoreUrl,
      'ios_store_url': _kDefaultIosStoreUrl,
      'android_interstitial_ad_unit_id': _kDefAndroidInterstitial,
      'ios_interstitial_ad_unit_id': _kDefIosInterstitial,
      'android_banner_ad_unit_id': _kDefAndroidBanner,
      'ios_banner_ad_unit_id': _kDefIosBanner,
    });

    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          minimumFetchInterval: const Duration(hours: 1),
          fetchTimeout: const Duration(seconds: 10),
        ),
      );
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // keep defaults on failure
    }

    setState(() {
      _androidStoreUrl = _remoteConfig.getString('android_store_url');
      _iosStoreUrl = _remoteConfig.getString('ios_store_url');
      _androidInterstitialId = _remoteConfig.getString(
        'android_interstitial_ad_unit_id',
      );
      _iosInterstitialId = _remoteConfig.getString(
        'ios_interstitial_ad_unit_id',
      );
      _androidBannerId = _remoteConfig.getString('android_banner_ad_unit_id');
      _iosBannerId = _remoteConfig.getString('ios_banner_ad_unit_id');
    });
  }

  // ───────────────────────── Controllers / state ─────────────────────────
  final ScreenshotController _screenshotController = ScreenshotController();
  Uint8List? _capturedImage;

  double _rotationAngle = 0.0;
  bool _noInternet = false;
  Future<List<Uint8List?>>? _imagesFuture;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  static const MethodChannel _methodChannel = MethodChannel('gallery_saver');

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _ambigramActionsCount = 0;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // ───────────────────────── lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();
    _initRemoteConfig();
    _maybeLoadImages();
    _loadInterstitialAd();
    _loadBannerAd();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
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

  // ───────────────────────── Ads helpers ─────────────────────────
  void _loadInterstitialAd() {
    final id = Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (_) => _isAdLoaded = false,
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
    final id = Platform.isAndroid ? _androidBannerId : _iosBannerId;
    _bannerAd = BannerAd(
      size: AdSize.largeBanner,
      adUnitId: id,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
      request: const AdRequest(),
    )..load();
  }

  // ───────────────────────── Image helpers ─────────────────────────
  Future<void> _maybeLoadImages() async {
    final cnt = widget.firstWord.length;
    if (cnt == 0) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      setState(() {
        _noInternet = true;
        _imagesFuture = null;
      });
    } else {
      setState(() {
        _noInternet = false;
        _imagesFuture = _loadAllSvgs(cnt);
      });
    }
  }

  Future<List<Uint8List?>> _loadAllSvgs(int count) async =>
      Future.wait(List.generate(count, _fetchSvgBytes));

  Future<Uint8List?> _fetchSvgBytes(int i) async {
    try {
      final first = widget.firstWord[i].toLowerCase();
      final second =
          widget.secondWord.isNotEmpty
              ? widget.secondWord[widget.secondWord.length - 1 - i]
                  .toLowerCase()
              : widget.firstWord[widget.firstWord.length - 1 - i].toLowerCase();

      final pair =
          first.compareTo(second) > 0 ? '$second$first' : '$first$second';
      final uri = Uri.parse(
        'https://d2p3tez4zcgtm0.cloudfront.net/ambigram-${widget.selectedChipIndex}/$pair.svg',
      );
      final res = await http.get(uri);
      return res.statusCode == 200 ? res.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────── UI helpers ─────────────────────────
  void _rotatePreview() {
    HapticFeedback.lightImpact();
    setState(() => _rotationAngle += pi);
  }

  Future<void> _captureScreenshot() async {
    final img = await _screenshotController.capture();
    if (img != null) setState(() => _capturedImage = img);
  }

  Future<void> _shareScreenshot() async {
    if (_capturedImage == null) await _captureScreenshot();
    if (_capturedImage == null) {
      _showSnack('No screenshot to share.');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/ambigram_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(path).writeAsBytes(_capturedImage!);

      final url = Platform.isIOS ? _iosStoreUrl : _androidStoreUrl;

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out my ambigram! Download the app here: $url');

      _ambigramActionsCount++;
      if (_ambigramActionsCount % 2 == 0) _tryShowInterstitialAd();
    } catch (e) {
      _showSnack('Error while sharing: $e');
    }
  }

  Future<void> _saveToGallery() async {
    if (_capturedImage == null) await _captureScreenshot();
    if (_capturedImage == null) {
      _showSnack('No screenshot to save.');
      return;
    }
    try {
      await _methodChannel.invokeMethod('saveImageToGallery', _capturedImage!);
      if (!mounted) return;
      _showSnack('Image saved to gallery successfully.');

      _ambigramActionsCount++;
      if (_ambigramActionsCount % 2 == 0) _tryShowInterstitialAd();
    } on PlatformException catch (e) {
      _showSnack('Error saving image to gallery: $e');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ───────────────────────── build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final bgColor =
        ColorPalette.backgroundChoices(context)[widget
            .selectedColorIndex].color;
    final count = widget.firstWord.length;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child:
            _isBannerAdLoaded
                ? SizedBox(
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
              // back
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
              // preview
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
              // buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AmbigramButton(
                  onPressed:
                      _noInternet
                          ? () => _showSnack(
                            'No internet connection. Cannot share.',
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
                          ? () =>
                              _showSnack('No internet connection. Cannot save.')
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

  // ───────────────────────── preview builder ─────────────────────────
  Widget _buildPreview(Color bg, int count) {
    if (count == 0) return _placeholder(bg, 'CLICK ON GENERATE TO PREVIEW');
    if (_noInternet)
      return _placeholder(
        bg,
        'PLEASE CONNECT TO INTERNET TO GENERATE AMBIGRAM',
      );

    return FutureBuilder<List<Uint8List?>>(
      future: _imagesFuture,
      builder: (context, snapshot) {
        if (_imagesFuture == null ||
            snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return _placeholder(bg, 'LOADING...');
        }

        final bytesList = snapshot.data!;
        return Container(
          width: double.infinity,
          height: 220,
          color: bg,
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(count, (i) {
                final f = widget.firstWord[i].toLowerCase();
                final s =
                    widget.secondWord.isNotEmpty
                        ? widget.secondWord[widget.secondWord.length - 1 - i]
                            .toLowerCase()
                        : widget.firstWord[widget.firstWord.length - 1 - i]
                            .toLowerCase();

                final flip = f.compareTo(s) > 0;
                final bytes = bytesList[i];

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
                  child: flip ? Transform.rotate(angle: pi, child: svg) : svg,
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder(Color bg, String txt) => Container(
    width: double.infinity,
    height: 220,
    color: bg,
    alignment: Alignment.center,
    child: Text(
      txt,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    ),
  );
}
