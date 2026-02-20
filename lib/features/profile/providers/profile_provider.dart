import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;

  Badge({required this.id, required this.name, required this.description, required this.icon, required this.isUnlocked});
}

class ProfileState {
  final Map<String, dynamic>? user;
  final List<Badge> badges;
  final Map<String, int> heatmap; // date -> steps
  final bool isLoading;

  ProfileState({
    this.user,
    required this.badges,
    required this.heatmap,
    this.isLoading = false,
  });

  ProfileState copyWith({
    Map<String, dynamic>? user,
    List<Badge>? badges,
    Map<String, int>? heatmap,
    bool? isLoading,
  }) {
    return ProfileState(
      user: user ?? this.user,
      badges: badges ?? this.badges,
      heatmap: heatmap ?? this.heatmap,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState(badges: [], heatmap: {}));

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Fetch user details
      final userRes = await supabase.from('users').select().eq('id', currentUser.id).single();
      
      // Fetch 30 day logs for heatmap
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);
      
      final logsRes = await supabase.from('step_logs')
          .select('date, steps')
          .eq('user_id', currentUser.id)
          .gte('date', startDate);
          
      Map<String, int> heatmap = {};
      for (var log in logsRes) {
        heatmap[log['date'] as String] = log['steps'] as int;
      }
      
      // Calculate Badges
      final totalSteps = userRes['total_steps'] as int;
      final redeemed = userRes['vouchers_redeemed'] as int;
      
      // Additional checks
      final eventCount = await supabase.from('event_participants').count(CountOption.exact).eq('user_id', currentUser.id);
      
      final adCount = await supabase.from('ad_views').count(CountOption.exact).eq('user_id', currentUser.id);
      
      List<Badge> badges = [
        Badge(
          id: 'first_steps',
          name: 'First Steps',
          description: 'Log your first steps',
          icon: 'directions_walk',
          isUnlocked: totalSteps > 0,
        ),
        Badge(
          id: '10k_club',
          name: '10k Club',
          description: 'Walk 10,000 steps in a day',
          icon: 'emoji_events',
          isUnlocked: heatmap.values.any((s) => s >= 10000),
        ),
        Badge(
          id: 'week_warrior',
          name: 'Week Warrior',
          description: 'Active for 7 days in a row',
          icon: 'local_fire_department',
          isUnlocked: _checkStreak(heatmap, 7),
        ),
        Badge(
          id: 'first_reward',
          name: 'First Reward',
          description: 'Redeem your first voucher',
          icon: 'card_giftcard',
          isUnlocked: redeemed > 0,
        ),
        Badge(
          id: 'event_walker',
          name: 'Event Walker',
          description: 'Join a charity event',
          icon: 'volunteer_activism',
          isUnlocked: eventCount > 0,
        ),
        Badge(
          id: 'ad_earner',
          name: 'Ad Earner',
          description: 'Earn credits from ads',
          icon: 'play_circle',
          isUnlocked: adCount > 0,
        ),
      ];

      state = state.copyWith(
        user: userRes,
        heatmap: heatmap,
        badges: badges,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
  
  bool _checkStreak(Map<String, int> heatmap, int days) {
    if (heatmap.isEmpty) return false;
    final sortedDates = heatmap.keys.toList()..sort();
    if (sortedDates.length < days) return false;
    
    int streak = 1;
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final d1 = DateTime.parse(sortedDates[i]);
      final d2 = DateTime.parse(sortedDates[i+1]);
      // Assuming gap of 1 day means consecutive
      if (d2.difference(d1).inDays == 1 && heatmap[sortedDates[i+1]]! > 0) {
        streak++;
        if (streak >= days) return true;
      } else {
        streak = 1;
      }
    }
    return false;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
