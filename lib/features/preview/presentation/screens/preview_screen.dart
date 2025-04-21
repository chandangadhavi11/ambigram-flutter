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
  // ───────────────────────── Remote‑Config defaults ─────────────────────────
  static const _defAndroidStore =
      'https://play.google.com/store/apps/details?id=com.placeholder.android';
  static const _defIosStore = 'https://apps.apple.com/app/id0000000000';
  static const _defAndroidInt = 'ca-app-pub-3940256099942544/1033173712';
  static const _defIosInt = 'ca-app-pub-3940256099942544/4411468910';
  static const _defAndroidBan = 'ca-app-pub-3940256099942544/6300978111';
  static const _defIosBan = 'ca-app-pub-3940256099942544/2934735716';

  late String _androidStoreUrl = _defAndroidStore;
  late String _iosStoreUrl = _defIosStore;
  late String _androidIntId = _defAndroidInt;
  late String _iosIntId = _defIosInt;
  late String _androidBannerId = _defAndroidBan;
  late String _iosBannerId = _defIosBan;

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;
  StreamSubscription<RemoteConfigUpdate>? _rcSub;

  // ───────────────────────── Controllers / state ─────────────────────────
  final ScreenshotController _shot = ScreenshotController();
  Uint8List? _captured;
  double _rotation = 0;
  bool _noInternet = false;
  Future<List<Uint8List?>>? _imagesFuture;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  static const MethodChannel _methodChannel = MethodChannel('gallery_saver');

  InterstitialAd? _interstitialAd;
  bool _isIntLoaded = false;
  int _actionCount = 0;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // ───────────────────────── lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();
    _setupRemoteConfig();
    _maybeLoadImages();
    _loadInterstitialAd();
    _loadBannerAd();

    // connectivity listener
    _connSub = Connectivity().onConnectivityChanged.listen((r) {
      if (r.contains(ConnectivityResult.none)) {
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

  Future<void> _setupRemoteConfig() async {
    await _rc.setDefaults({
      'android_store_url': _defAndroidStore,
      'ios_store_url': _defIosStore,
      'android_interstitial_ad_unit_id': _defAndroidInt,
      'ios_interstitial_ad_unit_id': _defIosInt,
      'android_banner_ad_unit_id': _defAndroidBan,
      'ios_banner_ad_unit_id': _defIosBan,
    });

    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          minimumFetchInterval: const Duration(hours: 1),
          fetchTimeout: const Duration(seconds: 10),
        ),
      );
      await _rc.fetchAndActivate();
    } catch (_) {
      /* ignore */
    }
    _applyRemoteValues();

    // live updates
    _rcSub = _rc.onConfigUpdated.listen((event) async {
      await _rc.activate();
      _applyRemoteValues(forceAdReload: true);
    });
  }

  void _applyRemoteValues({bool forceAdReload = false}) {
    final oldInt = Platform.isAndroid ? _androidIntId : _iosIntId;
    final oldBan = Platform.isAndroid ? _androidBannerId : _iosBannerId;

    _androidStoreUrl = _rc.getString('android_store_url');
    _iosStoreUrl = _rc.getString('ios_store_url');
    _androidIntId = _rc.getString('android_interstitial_ad_unit_id');
    _iosIntId = _rc.getString('ios_interstitial_ad_unit_id');
    _androidBannerId = _rc.getString('android_banner_ad_unit_id');
    _iosBannerId = _rc.getString('ios_banner_ad_unit_id');

    if (forceAdReload) {
      final newInt = Platform.isAndroid ? _androidIntId : _iosIntId;
      final newBan = Platform.isAndroid ? _androidBannerId : _iosBannerId;
      if (newInt != oldInt) {
        _interstitialAd?.dispose();
        _isIntLoaded = false;
        _loadInterstitialAd();
      }
      if (newBan != oldBan) {
        _bannerAd?.dispose();
        _isBannerLoaded = false;
        _loadBannerAd();
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _rcSub?.cancel();
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  // ───────────────────────── Ads ─────────────────────────
  void _loadInterstitialAd() {
    final id = Platform.isAndroid ? _androidIntId : _iosIntId;
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isIntLoaded = true;
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
        onAdFailedToLoad: (_) => _isIntLoaded = false,
      ),
    );
  }

  void _loadBannerAd() {
    final id = Platform.isAndroid ? _androidBannerId : _iosBannerId;
    _bannerAd = BannerAd(
      adUnitId: id,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerLoaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  Future<void> _tryShowInterstitial() async {
    if (_interstitialAd != null && _isIntLoaded) {
      await _interstitialAd!.show();
      _isIntLoaded = false;
    }
  }

  // ───────────────────────── Image helpers ─────────────────────────
  Future<void> _maybeLoadImages() async {
    final cnt = widget.firstWord.length;
    if (cnt == 0) return;

    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      setState(() {
        _noInternet = true;
        _imagesFuture = null;
      });
    } else {
      setState(() {
        _noInternet = false;
        _imagesFuture = Future.wait(List.generate(cnt, _fetchSvgBytes));
      });
    }
  }

  Future<Uint8List?> _fetchSvgBytes(int i) async {
    try {
      final f = widget.firstWord[i].toLowerCase();
      final s =
          widget.secondWord.isNotEmpty
              ? widget.secondWord[widget.secondWord.length - 1 - i]
                  .toLowerCase()
              : widget.firstWord[widget.firstWord.length - 1 - i].toLowerCase();
      final pair = f.compareTo(s) > 0 ? '$s$f' : '$f$s';
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
  void _rotate() {
    HapticFeedback.lightImpact();
    setState(() => _rotation += pi);
  }

  Future<void> _capture() async {
    final img = await _shot.capture();
    if (img != null) setState(() => _captured = img);
  }

  Future<void> _share() async {
    if (_captured == null) await _capture();
    if (_captured == null) {
      _snack('No screenshot to share');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/ambigram_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(path).writeAsBytes(_captured!);
      final url = Platform.isIOS ? _iosStoreUrl : _androidStoreUrl;

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out my ambigram! Download the app here: $url');

      if (++_actionCount % 2 == 0) _tryShowInterstitial();
    } catch (e) {
      _snack('Error while sharing: $e');
    }
  }

  Future<void> _save() async {
    if (_captured == null) await _capture();
    if (_captured == null) {
      _snack('No screenshot to save');
      return;
    }
    try {
      await _methodChannel.invokeMethod('saveImageToGallery', _captured!);
      _snack('Image saved to gallery!');
      if (++_actionCount % 2 == 0) _tryShowInterstitial();
    } on PlatformException catch (e) {
      _snack('Error saving image: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ───────────────────────── build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg =
        ColorPalette.backgroundChoices(context)[widget
            .selectedColorIndex].color;
    final cnt = widget.firstWord.length;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child:
            _isBannerLoaded
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
            crossAxisAlignment: CrossAxisAlignment.stretch, // <─ NEW
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
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Align(
                  alignment: Alignment.centerLeft, // <─ NEW
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
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
              // preview
              Screenshot(
                controller: _shot,
                child: GestureDetector(
                  onTap: _rotate,
                  child: AnimatedRotation(
                    turns: _rotation / (2 * pi),
                    duration: const Duration(milliseconds: 300),
                    child: _buildPreview(bg, cnt),
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
                          ? () =>
                              _snack('No internet connection. Cannot share.')
                          : _share,
                  text: 'SHARE YOUR AMBIGRAM',
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AmbigramButton(
                  onPressed:
                      _noInternet
                          ? () => _snack('No internet connection. Cannot save.')
                          : _save,
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
    if (_noInternet) {
      return _placeholder(
        bg,
        'PLEASE CONNECT TO INTERNET TO GENERATE AMBIGRAM',
      );
    }

    return FutureBuilder<List<Uint8List?>>(
      future: _imagesFuture,
      builder: (context, snap) {
        if (_imagesFuture == null ||
            snap.connectionState == ConnectionState.waiting ||
            !snap.hasData) {
          return _placeholder(bg, 'LOADING...');
        }

        final bytesList = snap.data!;
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
                final flip = f.compareTo(s) > 0;
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
