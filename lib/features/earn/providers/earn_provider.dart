import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../../../services/ad_service.dart';

final adServiceProvider = Provider((ref) => AdService());

class EarnState {
  final int adsWatchedToday;
  final bool isLoading;
  final bool showConfetti;

  EarnState({
    required this.adsWatchedToday,
    this.isLoading = false,
    this.showConfetti = false,
  });
  
  EarnState copyWith({
    int? adsWatchedToday,
    bool? isLoading,
    bool? showConfetti,
  }) {
    return EarnState(
      adsWatchedToday: adsWatchedToday ?? this.adsWatchedToday,
      isLoading: isLoading ?? this.isLoading,
      showConfetti: showConfetti ?? this.showConfetti,
    );
  }
}

class EarnNotifier extends StateNotifier<EarnState> {
  final AdService _adService;
  
  EarnNotifier(this._adService) : super(EarnState(adsWatchedToday: 0));

  Future<void> init() async {
    await _adService.init();
    _adService.loadRewardedAd();
    await _fetchDailyStats();
  }

  Future<void> _fetchDailyStats() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String();
    
    final count = await supabase
        .from('ad_views')
        .count(CountOption.exact)
        .eq('user_id', user.id)
        .gte('viewed_at', startOfDay);
        
    state = state.copyWith(adsWatchedToday: count);
  }

  Future<void> watchAd() async {
    if (state.adsWatchedToday >= 5) return;
    
    state = state.copyWith(isLoading: true);
    
    bool shown = await _adService.showRewardedAd(
      onUserEarnedReward: (amount) async {
        // Credit User
        final user = supabase.auth.currentUser;
        if (user == null) return;
        
        await supabase.from('ad_views').insert({
          'user_id': user.id,
        });
        
        // Add 50 RC
        final userRes = await supabase.from('users').select('current_rc').eq('id', user.id).single();
        final current = userRes['current_rc'] as int;
        
        await supabase.from('users').update({
          'current_rc': current + 50,
        }).eq('id', user.id);
        
        state = state.copyWith(
          adsWatchedToday: state.adsWatchedToday + 1,
          isLoading: false,
          showConfetti: true,
        );
        
        // Hide confetti after delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) state = state.copyWith(showConfetti: false);
        });
      },
    );
    
    if (!shown) {
      // Ad not ready or failed to show
      // In real app, retry load or show error
    }
    
    state = state.copyWith(isLoading: false);
  }
}

final earnProvider = StateNotifierProvider<EarnNotifier, EarnState>((ref) {
  return EarnNotifier(ref.watch(adServiceProvider));
});
