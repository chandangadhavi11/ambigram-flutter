import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Replace with your actual paths:
import 'package:flutter_application_1/core/constants/app_colors.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_application_1/features/preview/presentation/screens/preview_screen.dart';
import 'package:flutter_application_1/shared/widgets/custom_button.dart';

import 'components/header_section.dart';
import 'components/preview_section.dart';
import 'components/color_selection_section.dart';
import 'components/input_section.dart';

/// The main screen that hosts all the sections and orchestrates the logic.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _chipLabels = [
    'ANTIOGLYPH',
    'ESCHERESQUE',
    'AMBORATTIC',
    'SPECULON',
    'AETHERGLYPH',
    'GYROGLYPH',
    'ENANTIGRAM',
  ];
  int _selectedChipIndex = 0;

  int _imageCount = 0;
  bool _hasGenerated = false;
  int _credits = 25;

  int _selectedColorIndex = 0;
  late List<NamedColor> _colors;

  String _generatedFirstWord = '';
  String _generatedSecondWord = '';

  /// AdMob Banner
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  /// Rewarded Ad
  RewardedAd? _rewardedAd; // <--- ADD THIS

  @override
  void initState() {
    super.initState();
    _loadCredits();
    _initGoogleMobileAds();
    _createBannerAd();

    /// Load the Rewarded Ad as soon as the app initializes
    _loadRewardedAd(); // <--- ADD THIS
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;
    _colors = ColorPalette.backgroundChoices(context);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initGoogleMobileAds() async {
    // Initialize the Mobile Ads SDK
    await MobileAds.instance.initialize();
  }

  void _createBannerAd() {
    _bannerAd = BannerAd(
      // Use your real Ad Unit IDs in production.
      // The below are test Ad Unit IDs.
      adUnitId:
          Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/6300978111'
              : 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('BannerAd failed to load: $error');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  /// Load Rewarded Ad method
  void _loadRewardedAd() {
    RewardedAd.load(
      // Use test IDs for testing. Replace with your real IDs when ready.
      adUnitId:
          Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/5224354917' // Test ID for Android
              : 'ca-app-pub-3940256099942544/1712485313', // Test ID for iOS
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('Rewarded Ad loaded.');
          _rewardedAd = ad;

          // Set up callbacks for full-screen events
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Rewarded Ad dismissed.');
              ad.dispose();
              // Load a new ad for next time.
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              debugPrint('Failed to show Rewarded Ad: $err');
              ad.dispose();
              // Load a new ad for next time.
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Failed to load Rewarded Ad: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<void> _loadCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCredits = prefs.getInt('credit_count') ?? 25;
    setState(() {
      _credits = storedCredits;
    });
  }

  Future<void> _saveCredits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('credit_count', _credits);
  }

  void _handleGenerate(String firstWord, String secondWord) async {
    if (_credits > 0) {
      setState(() {
        _generatedFirstWord = firstWord;
        _generatedSecondWord = secondWord;
        _imageCount = firstWord.length;
        _hasGenerated = true;
        _credits--;
      });
      await _saveCredits();
    } else {
      _showCreditLimitModal();
    }
  }

  void _showCreditLimitModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        final deviceWidth = MediaQuery.of(context).size.width;
        return SingleChildScrollView(
          child: Container(
            width: deviceWidth,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/images/flash_icon.svg',
                        width: 40,
                        height: 40,
                        semanticsLabel: 'Icon',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'CREDIT LIMIT REACHED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Averta Demo PE Cutted Demo',
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
                                fontFamily: 'Averta Demo PE Cutted Demo',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1,
                                color: Color(0xFF959399),
                              ),
                            ),
                            const TextSpan(
                              text: '5',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Averta Demo PE Cutted Demo',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1,
                                color: Color(0xFFBF9B47),
                              ),
                            ),
                            const TextSpan(
                              text: ' MORE CREDITS INSTANTLY',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Averta Demo PE Cutted Demo',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1,
                                color: Color(0xFF959399),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons Section
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      AmbigramButton(
                        text: "WATCH AD (+5)",
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showRewardedAd(); // <--- USE METHOD TO SHOW THE AD
                        },
                      ),
                      const SizedBox(height: 12),
                      AmbigramButton(
                        text: "BUY UNLIMITED CREDITS",
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          // Implement your in-app purchase flow here
                          setState(() {
                            _credits = 999;
                          });
                          _saveCredits();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show the Rewarded Ad
  void _showRewardedAd() async {
    if (_rewardedAd == null) {
      debugPrint('Rewarded Ad not ready.');
      Navigator.of(context).pop();
      return;
    }

    // Show the ad
    _rewardedAd?.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        // The user watched the video; reward them.
        setState(() {
          _credits += 5;
        });
        await _saveCredits();
        debugPrint('User rewarded with ${reward.amount} ${reward.type}');
      },
    );
    // Once the ad is shown, close the bottom sheet.
    Navigator.of(context).pop();
    _rewardedAd = null;
  }

  void _onColorSelected(int index) {
    setState(() {
      _selectedColorIndex = index;
    });
  }

  void _onChipSelected(int index) async {
    if (_credits > 0) {
      setState(() {
        _credits--;
        _selectedChipIndex = index;
      });
      await _saveCredits();
    } else {
      _showCreditLimitModal();
      setState(() {
        _selectedChipIndex = index;
      });
    }
  }

  void _handleDownloadTap() {
    Navigator.push(
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
  }

  void _handleInputChanged() {
    if (_hasGenerated) {
      setState(() {
        _hasGenerated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        (_selectedColorIndex >= 0 && _selectedColorIndex < _colors.length)
            ? _colors[_selectedColorIndex].color
            : AppColors.previewBackground(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Wrap main content in Expanded + SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                // Add extra bottom padding to create space above the ad
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
                        backgroundColor: backgroundColor,
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
      // BannerAd pinned at the bottom
      bottomNavigationBar: SafeArea(
        child:
            _isBannerAdReady
                ? Container(
                  color: Colors.transparent,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
                : const SizedBox.shrink(),
      ),
    );
  }
}
