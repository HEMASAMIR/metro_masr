import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final bool _testMode = kDebugMode;

  // الـ IDs دي للتجربة فقط (Test IDs)، لازم تغيرها بالـ IDs بتاعتك من AdMob قبل الـ Production
  static String get bannerAdUnitId {
    if (_testMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android Test ID
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test ID
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8627401759225156/1217072848' // Android Production Banner
        : 'ca-app-pub-8627401759225156/6928564524'; // iOS Production Banner
  }

  static String get interstitialAdUnitId {
    if (_testMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Android Test ID
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS Test ID
    }
    return Platform.isAndroid
        ? 'ca-app-pub-8627401759225156/8577227110' // Android Production Interstitial
        : 'ca-app-pub-8627401759225156/1489074582'; // iOS Production Interstitial
  }

  static Future<void> init() async {
    // ✅ Register physical test devices so they always get test ads in debug mode
    // This prevents accidental real ad impressions during development
    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [
            '9871C1B254688E1D51298C30EBD8778E', // SM-A325F (dev device)
          ],
        ),
      );
    }
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd({
    void Function(Ad)? onAdLoaded,
    void Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Ad loaded: ${ad.adUnitId}');
          onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Ad failed to load: ${error.message}');
          onAdFailedToLoad?.call(ad, error);
        },
      ),
    )..load();
  }

  static void showInterstitialAd(Function onComplete) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onComplete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (err) => onComplete(),
      ),
    );
  }
}
