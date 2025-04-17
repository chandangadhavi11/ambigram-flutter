import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdaptiveBannerAdWidget extends StatefulWidget {
  /// Pass the ad unit ID you want to show in this widget.
  final String adUnitId;

  const AdaptiveBannerAdWidget({Key? key, required this.adUnitId})
    : super(key: key);

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  /// Loads a banner ad using the anchored adaptive size.
  Future<void> _loadAd() async {
    try {
      // Obtain an AnchoredAdaptiveBannerAdSize before loading the ad.
      final AnchoredAdaptiveBannerAdSize? size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate(),
          );

      if (size == null) {
        // The size could be null if there's no valid ad size for the device.
        debugPrint('Error: AnchoredAdaptiveBannerAdSize is null.');
        return;
      }

      final banner = BannerAd(
        size: size,
        adUnitId: widget.adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('$ad loaded.');
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAd failed to load: $error');
            ad.dispose();
          },
        ),
        request: const AdRequest(),
      );

      await banner.load();
    } catch (e) {
      debugPrint('Failed to load an anchored adaptive banner ad: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // Return an empty SizedBox or a placeholder while the ad loads
      return const SizedBox();
    }

    // Once loaded, display the ad in the correct size
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
