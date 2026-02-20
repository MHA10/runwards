import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Test ID
          : 'ca-app-pub-3940256099942544/1712485313', // Test ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
        },
      ),
    );
  }

  bool isAdReady() {
    return _isAdLoaded && _rewardedAd != null;
  }

  Future<bool> showRewardedAd({required Function(int amount) onUserEarnedReward}) async {
    if (_rewardedAd == null) {
      loadRewardedAd(); // Try to load for next time
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward.amount.toInt());
      },
    );
    
    _rewardedAd = null;
    _isAdLoaded = false;
    return true;
  }
}
