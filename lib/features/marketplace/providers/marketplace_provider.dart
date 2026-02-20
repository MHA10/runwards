import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

class MarketplaceState {
  final List<Map<String, dynamic>> rewards;
  final bool isLoading;
  final String filter; // 'All' by default

  MarketplaceState({
    required this.rewards,
    this.isLoading = false,
    this.filter = 'All',
  });

  MarketplaceState copyWith({
    List<Map<String, dynamic>>? rewards,
    bool? isLoading,
    String? filter,
  }) {
    return MarketplaceState(
      rewards: rewards ?? this.rewards,
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  MarketplaceNotifier() : super(MarketplaceState(rewards: []));

  Future<void> fetchRewards() async {
    state = state.copyWith(isLoading: true);
    try {
      dynamic query = supabase.from('rewards').select();
      
      if (state.filter != 'All') {
        query = query.eq('category', state.filter);
      }
      
      final data = await query.order('created_at');
      
      state = state.copyWith(
        rewards: List<Map<String, dynamic>>.from(data),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter(String filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    fetchRewards();
  }

  Future<String> redeemReward(String rewardId, int cost) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Fetch user details
    final userRes = await supabase.from('users').select('current_rc, vouchers_redeemed').eq('id', user.id).single();
    final balance = userRes['current_rc'] as int;
    final redeemedCount = userRes['vouchers_redeemed'] as int;

    if (balance < cost) {
      throw Exception('Insufficient Runward Credits');
    }

    // Generate voucher code
    final voucherCode = 'RW-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Insert redemption
    await supabase.from('redemptions').insert({
      'user_id': user.id,
      'reward_id': rewardId,
      'voucher_code': voucherCode,
    });

    // Update user balance
    await supabase.from('users').update({
      'current_rc': balance - cost,
      'vouchers_redeemed': redeemedCount + 1,
    }).eq('id', user.id);

    return voucherCode;
  }
}

final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier();
});
