// home_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const _defColorJson =
      '[{"name":"Off White","color":"#FAFAFA"},{"name":"Pink","color":"#FFC0CB"}]';

  static const _defMinAndroidBuild = 1;
  static const _defMinIosBuild = 1;

  static const _defAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ambigram.app';
  static const _defIosStoreUrl = 'https://apps.apple.com/app/id123456789';

  static const _defShowBuy = true;
  static const _defAndroidBuyUrl = _defAndroidStoreUrl;
  static const _defIosBuyUrl = _defIosStoreUrl;

  // ───────────────────────── Remote‑controlled values ─────────────────────────
  late String _androidBannerId = _defAndroidBanner;
  late String _iosBannerId = _defIosBanner;
  late String _androidRewardId = _defAndroidReward;
  late String _iosRewardId = _defIosReward;
  late List<String> _chipLabels =
      _defChips.split(',').map((e) => e.trim()).toList();
  int _remoteInitialCredits = _defInitialCredits;
  String _backgroundColorJson = _defColorJson;

  // buy button
  bool _showBuyButton = _defShowBuy;
  String _buyUrl = Platform.isAndroid ? _defAndroidBuyUrl : _defIosBuyUrl;

  // ───────────────────────── UI / runtime state ─────────────────────────
  int _selectedChipIndex = 0;
  int _imageCount = 0;
  bool _hasGenerated = false;
  int _credits = _defInitialCredits;
  int _selectedColorIndex = 0;
  List<NamedColor> _colors = ColorPalette.fromRemote(_defColorJson);

  String _firstWord = '', _secondWord = '';

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  RewardedAd? _rewardedAd;
  bool _rewardReady = false;

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;
  StreamSubscription<RemoteConfigUpdate>? _rcSub;

  // force‑update
  bool _mustUpdate = false;
  String _storeUrl = _defAndroidStoreUrl;

  // ───────────────────────── lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _setupRemoteConfig();
    await MobileAds.instance.initialize();
    await _loadCredits();
    _createBannerAd();
    _loadRewardedAd();
    _rcSub = _rc.onConfigUpdated.listen((_) async {
      await _rc.activate();
      _applyRemoteValues(forceAdReload: true);
      await _checkForForceUpdate();
    });
    if (mounted) setState(() {});
  }

  // ───────────────────────── Remote‑Config ─────────────────────────
  Future<void> _setupRemoteConfig() async {
    await _rc.setDefaults({
      'android_home_banner_ad_unit_id': _defAndroidBanner,
      'ios_home_banner_ad_unit_id': _defIosBanner,
      'android_rewarded_ad_unit_id': _defAndroidReward,
      'ios_rewarded_ad_unit_id': _defIosReward,
      'chip_labels': _defChips,
      'initial_credits': _defInitialCredits,
      'background_colors': _defColorJson,
      'show_buy_button': _defShowBuy,
      'android_buy_url': _defAndroidBuyUrl,
      'ios_buy_url': _defIosBuyUrl,
      'min_android_build': _defMinAndroidBuild,
      'min_ios_build': _defMinIosBuild,
      'android_store_url': _defAndroidStoreUrl,
      'ios_store_url': _defIosStoreUrl,
    });
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          minimumFetchInterval: const Duration(minutes: 10),
          fetchTimeout: const Duration(seconds: 10),
        ),
      );
      await _rc.fetchAndActivate();
    } catch (_) {}
    _applyRemoteValues();
    await _checkForForceUpdate();
  }

  void _applyRemoteValues({bool forceAdReload = false}) {
    final oldBan = Platform.isAndroid ? _androidBannerId : _iosBannerId;
    final oldReward = Platform.isAndroid ? _androidRewardId : _iosRewardId;
    final oldColors = _backgroundColorJson;

    _androidBannerId = _rc.getString('android_home_banner_ad_unit_id');
    _iosBannerId = _rc.getString('ios_home_banner_ad_unit_id');
    _androidRewardId = _rc.getString('android_rewarded_ad_unit_id');
    _iosRewardId = _rc.getString('ios_rewarded_ad_unit_id');
    _chipLabels =
        _rc.getString('chip_labels').split(',').map((e) => e.trim()).toList();
    _remoteInitialCredits = _rc.getInt('initial_credits');

    _backgroundColorJson = _rc.getString('background_colors');
    _showBuyButton = _rc.getBool('show_buy_button');
    _buyUrl =
        Platform.isAndroid
            ? _rc.getString('android_buy_url')
            : _rc.getString('ios_buy_url');

    if (oldColors != _backgroundColorJson) {
      _colors = ColorPalette.fromRemote(_backgroundColorJson);
      _selectedColorIndex = 0;
    }

    if (forceAdReload) {
      final newBan = Platform.isAndroid ? _androidBannerId : _iosBannerId;
      final newReward = Platform.isAndroid ? _androidRewardId : _iosRewardId;
      if (newBan != oldBan) {
        _bannerAd?.dispose();
        _isBannerAdReady = false;
        _createBannerAd();
      }
      if (newReward != oldReward) {
        _rewardedAd?.dispose();
        _rewardedAd = null;
        _rewardReady = false;
        _loadRewardedAd();
      }
    }
    if (mounted) setState(() {});
  }

  // ───────────────────────── credits prefs ─────────────────────────
  Future<void> _loadCredits() async {
    final p = await SharedPreferences.getInstance();
    _credits = p.getInt('credit_count') ?? _remoteInitialCredits;
    if (mounted) setState(() {});
  }

  Future<void> _saveCredits() async =>
      (await SharedPreferences.getInstance()).setInt('credit_count', _credits);

  // ───────────────────────── ads ─────────────────────────
  void _createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? _androidBannerId : _iosBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _isBannerAdReady = false;
        },
      ),
    )..load();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid ? _androidRewardId : _iosRewardId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardReady = false;
              _loadRewardedAd();
              if (mounted) Navigator.of(context).maybePop();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardReady = false;
              _loadRewardedAd();
              if (mounted) Navigator.of(context).maybePop();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
          _rewardReady = false;
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (!_rewardReady || _rewardedAd == null) {
      Navigator.of(context).pop();
      return;
    }
    _rewardedAd!.show(
      onUserEarnedReward: (_, __) async {
        setState(() => _credits += 5);
        await _saveCredits();
        if (mounted) Navigator.of(context).maybePop();
      },
    );
    _rewardedAd = null;
    _rewardReady = false;
  }

  // ───────────────────────── generators ─────────────────────────
  void _handleGenerate(String f, String s) async {
    if (_credits > 0) {
      setState(() => _credits--);
      _firstWord = f;
      _secondWord = s;
      _imageCount = f.length;
      _hasGenerated = true;
      await _saveCredits();
    } else {
      _showCreditLimitModal();
    }
  }

  // CHANGE: only consume a credit if text has been generated
  void _onChipSelected(int i) async {
    if (i == _selectedChipIndex) return;

    // If no ambigram text yet, switch without cost
    if (_firstWord.isEmpty && _secondWord.isEmpty) {
      setState(() => _selectedChipIndex = i);
      return;
    }

    if (_credits > 0) {
      setState(() {
        _credits--;
        _selectedChipIndex = i;
      });
      await _saveCredits();
    } else {
      _showCreditLimitModal();
    }
  }

  void _onColorSelected(int i) => setState(() => _selectedColorIndex = i);

  void _handleDownloadTap() => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) => PreviewScreen(
            firstWord: _firstWord,
            secondWord: _secondWord,
            selectedChipIndex: _selectedChipIndex,
            selectedColorIndex: _selectedColorIndex,
            colors: _colors,
          ),
    ),
  );

  void _handleInputChanged() {
    if (_hasGenerated) setState(() => _hasGenerated = false);
  }

  // ───────────────────────── modals ─────────────────────────
  void _showCreditLimitModal() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => _CreditModal(
          onWatchAd: _showRewardedAd,
          rewardReady: _rewardReady,
          showBuy: _showBuyButton,
          buyUrl: _buyUrl,
        ),
  );

  Future<void> _checkForForceUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final local = int.tryParse(info.buildNumber) ?? 1;
    final min =
        Platform.isAndroid
            ? _rc.getInt('min_android_build')
            : _rc.getInt('min_ios_build');
    _storeUrl =
        Platform.isAndroid
            ? _rc.getString('android_store_url')
            : _rc.getString('ios_store_url');
    if (local < min && !_mustUpdate && mounted) {
      _mustUpdate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showForceUpdateModal();
      });
    }
  }

  void _showForceUpdateModal() => showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ForceUpdateModal(storeUrl: _storeUrl),
  );

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _rcSub?.cancel();
    super.dispose();
  }

  // ───────────────────────── build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final bg =
        (_selectedColorIndex < _colors.length)
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
                        firstWord: _firstWord,
                        secondWord: _secondWord,
                        selectedChipIndex: _selectedChipIndex,
                        showImageBackground: false,
                      ),
                      const SizedBox(height: 16),
                      ColorSelectionSection(
                        colors: _colors,
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

// ───────────────────────── Modal widgets ─────────────────────────
class _CreditModal extends StatelessWidget {
  final VoidCallback onWatchAd;
  final bool rewardReady;
  final bool showBuy;
  final String buyUrl;
  const _CreditModal({
    required this.onWatchAd,
    required this.rewardReady,
    required this.showBuy,
    required this.buyUrl,
  });

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
              style: TextStyle(fontSize: 12, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            const Text(
              'WATCH AN AD TO GET 5 MORE CREDITS OR PURCHASE UNLIMITED CREDITS.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF959399)),
            ),
            const SizedBox(height: 24),
            AmbigramButton(
              text: 'WATCH AD (+5)',
              onPressed: rewardReady ? onWatchAd : () {},
            ),
            if (showBuy) ...[
              const SizedBox(height: 12),
              AmbigramButton(
                text: 'BUY UNLIMITED CREDITS',
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final uri = Uri.parse(buyUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

class _ForceUpdateModal extends StatelessWidget {
  final String storeUrl;
  const _ForceUpdateModal({required this.storeUrl});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'UPDATE REQUIRED',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A newer version is available. Please update to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF7D7A82)),
          ),
          const SizedBox(height: 24),
          AmbigramButton(
            text: 'UPDATE NOW',
            onPressed: () async {
              final uri = Uri.parse(storeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    ),
  );
}
