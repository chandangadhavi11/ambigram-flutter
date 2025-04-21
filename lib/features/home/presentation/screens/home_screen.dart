// home_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:flutter_application_1/core/constants/app_colors.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_application_1/features/preview/presentation/screens/preview_screen.dart';
import 'package:flutter_application_1/shared/widgets/custom_button.dart';

import 'components/header_section.dart';
import 'components/preview_section.dart';
import 'components/color_selection_section.dart';
import 'components/input_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ───────────────────────── Remote‑Config defaults ─────────────────────────
  static const _defAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _defIosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _defAndroidReward = 'ca-app-pub-3940256099942544/5224354917';
  static const _defIosReward = 'ca-app-pub-3940256099942544/1712485313';
  static const _defChips =
      'ANTIOGLYPH,ESCHERESQUE,AMBORATTIC,SPECULON,AETHERGLYPH,GYROGLYPH,ENANTIGRAM';
  static const _defInitialCredits = 25;

  // ───────────────────────── Remote‑controlled values ─────────────────────────
  late String _androidBannerId = _defAndroidBanner;
  late String _iosBannerId = _defIosBanner;
  late String _androidRewardId = _defAndroidReward;
  late String _iosRewardId = _defIosReward;
  late List<String> _chipLabels =
      _defChips.split(',').map((e) => e.trim()).toList();
  int _remoteInitialCredits = _defInitialCredits;

  // ───────────────────────── UI / runtime state ─────────────────────────
  int _selectedChipIndex = 0;
  int _imageCount = 0;
  bool _hasGenerated = false;

  int _credits = _defInitialCredits;
  int _selectedColorIndex = 0;
  late List<NamedColor> _colors;

  String _generatedFirstWord = '';
  String _generatedSecondWord = '';

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  RewardedAd? _rewardedAd;

  // Remote‑Config & listener
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  StreamSubscription<RemoteConfigUpdate>? _rcSub;

  // ───────────────────────── lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();
    _bootstrap(); // single async entry
  }

  Future<void> _bootstrap() async {
    await _setupRemoteConfig();
    await MobileAds.instance.initialize();
    await _loadCredits();
    _createBannerAd();
    _loadRewardedAd();

    // Listen for live Remote‑Config pushes
    _rcSub = _remoteConfig.onConfigUpdated.listen((update) async {
      try {
        await _remoteConfig.activate();
        _applyRemoteValues(forceAdReload: true);
      } catch (e) {
        debugPrint('Remote‑config activate failed: $e');
      }
    });

    if (mounted) setState(() {});
  }

  // INITIAL FETCH & DEFAULTS
  Future<void> _setupRemoteConfig() async {
    await _remoteConfig.setDefaults({
      'android_home_banner_ad_unit_id': _defAndroidBanner,
      'ios_home_banner_ad_unit_id': _defIosBanner,
      'android_rewarded_ad_unit_id': _defAndroidReward,
      'ios_rewarded_ad_unit_id': _defIosReward,
      'chip_labels': _defChips,
      'initial_credits': _defInitialCredits,
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
      // swallow – defaults already set
    }

    _applyRemoteValues();
  }

  // Pull values from Remote Config into local vars and optionally reload ads
  void _applyRemoteValues({bool forceAdReload = false}) {
    final oldBanner = Platform.isAndroid ? _androidBannerId : _iosBannerId;
    final oldReward = Platform.isAndroid ? _androidRewardId : _iosRewardId;

    _androidBannerId = _remoteConfig.getString(
      'android_home_banner_ad_unit_id',
    );
    _iosBannerId = _remoteConfig.getString('ios_home_banner_ad_unit_id');
    _androidRewardId = _remoteConfig.getString('android_rewarded_ad_unit_id');
    _iosRewardId = _remoteConfig.getString('ios_rewarded_ad_unit_id');
    _chipLabels =
        _remoteConfig
            .getString('chip_labels')
            .split(',')
            .map((e) => e.trim())
            .toList();
    _remoteInitialCredits = _remoteConfig.getInt('initial_credits');

    if (forceAdReload) {
      final newBanner = Platform.isAndroid ? _androidBannerId : _iosBannerId;
      final newReward = Platform.isAndroid ? _androidRewardId : _iosRewardId;

      if (newBanner != oldBanner) {
        _bannerAd?.dispose();
        _isBannerAdReady = false;
        _createBannerAd();
      }
      if (newReward != oldReward) {
        _rewardedAd?.dispose();
        _loadRewardedAd();
      }
    }

    setState(() {}); // rebuild UI (chip list, etc.)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colors = ColorPalette.backgroundChoices(context);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _rcSub?.cancel();
    super.dispose();
  }

  // ───────────────────────── Shared‑prefs for credits ─────────────────────────
  Future<void> _loadCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('credit_count');
    setState(() => _credits = stored ?? _remoteInitialCredits);
  }

  Future<void> _saveCredits() async =>
      (await SharedPreferences.getInstance()).setInt('credit_count', _credits);

  // ───────────────────────── Banner Ad ─────────────────────────
  void _createBannerAd() {
    final id = Platform.isAndroid ? _androidBannerId : _iosBannerId;
    _bannerAd = BannerAd(
      adUnitId: id,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner failed: $err');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  // ───────────────────────── Rewarded Ad ─────────────────────────
  void _loadRewardedAd() {
    final id = Platform.isAndroid ? _androidRewardId : _iosRewardId;
    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded failed: $err');
          _rewardedAd = null;
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      debugPrint('Rewarded not ready');
      Navigator.of(context).pop();
      return;
    }
    _rewardedAd?.show(
      onUserEarnedReward: (_, __) async {
        setState(() => _credits += 5);
        await _saveCredits();
      },
    );
    Navigator.of(context).pop();
    _rewardedAd = null;
  }

  // ───────────────────────── Generation callbacks ─────────────────────────
  void _handleGenerate(String first, String second) async {
    if (_credits > 0) {
      setState(() {
        _generatedFirstWord = first;
        _generatedSecondWord = second;
        _imageCount = first.length;
        _hasGenerated = true;
        _credits--;
      });
      await _saveCredits();
    } else {
      _showCreditLimitModal();
    }
  }

  void _onChipSelected(int i) async {
    if (_credits > 0) {
      setState(() {
        _credits--;
        _selectedChipIndex = i;
      });
      await _saveCredits();
    } else {
      _showCreditLimitModal();
      setState(() => _selectedChipIndex = i);
    }
  }

  void _onColorSelected(int i) => setState(() => _selectedColorIndex = i);

  void _handleDownloadTap() => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) => PreviewScreen(
            firstWord: _generatedFirstWord,
            secondWord: _generatedSecondWord,
            selectedChipIndex: _selectedChipIndex,
            selectedColorIndex: _selectedColorIndex,
          ),
    ),
  );

  void _handleInputChanged() {
    if (_hasGenerated) setState(() => _hasGenerated = false);
  }

  // ───────────────────────── Credit‑limit modal ─────────────────────────
  void _showCreditLimitModal() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CreditModal(onWatchAd: _showRewardedAd),
  );

  // ───────────────────────── build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg =
        (_selectedColorIndex >= 0 && _selectedColorIndex < _colors.length)
            ? _colors[_selectedColorIndex].color
            : AppColors.previewBackground(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      HeaderSection(
                        credits: _credits,
                        chipLabels: _chipLabels,
                        selectedChipIndex: _selectedChipIndex,
                        onChipSelected: _onChipSelected,
                      ),
                      const SizedBox(height: 24),
                      PreviewSection(
                        imageCount: _imageCount,
                        backgroundColor: bg,
                        firstWord: _generatedFirstWord,
                        secondWord: _generatedSecondWord,
                        selectedChipIndex: _selectedChipIndex,
                        showImageBackground: false,
                      ),
                      const SizedBox(height: 16),
                      ColorSelectionSection(
                        selectedColorIndex: _selectedColorIndex,
                        onColorSelected: _onColorSelected,
                      ),
                      const SizedBox(height: 16),
                      InputSection(
                        onGenerate: _handleGenerate,
                        hasGenerated: _hasGenerated,
                        onDownload: _handleDownloadTap,
                        onInputChanged: _handleInputChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child:
            _isBannerAdReady
                ? SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
                : const SizedBox.shrink(),
      ),
    );
  }
}

// ───────────────────────── Modal widget ─────────────────────────
class _CreditModal extends StatelessWidget {
  final VoidCallback onWatchAd;
  const _CreditModal({required this.onWatchAd});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/flash_icon.svg',
              width: 40,
              height: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              'CREDIT LIMIT REACHED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'WATCH A SHORT AD TO GET ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                      color: Color(0xFF959399),
                    ),
                  ),
                  const TextSpan(
                    text: '5',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                      color: Color(0xFFBF9B47),
                    ),
                  ),
                  const TextSpan(
                    text: ' MORE CREDITS INSTANTLY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                      color: Color(0xFF959399),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AmbigramButton(text: 'WATCH AD (+5)', onPressed: onWatchAd),
            const SizedBox(height: 12),
            AmbigramButton(
              text: 'BUY UNLIMITED CREDITS',
              onPressed: () {
                HapticFeedback.mediumImpact();
                // In‑app purchase flow here
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
