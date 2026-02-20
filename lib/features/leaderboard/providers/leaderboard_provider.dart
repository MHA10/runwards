import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

enum LeaderboardFilter { global, local }

class LeaderboardState {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final LeaderboardFilter filter;
  final Map<String, dynamic>? currentUserRank;

  LeaderboardState({
    required this.users,
    this.isLoading = false,
    this.filter = LeaderboardFilter.global,
    this.currentUserRank,
  });

  LeaderboardState copyWith({
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    LeaderboardFilter? filter,
    Map<String, dynamic>? currentUserRank,
  }) {
    return LeaderboardState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
      currentUserRank: currentUserRank ?? this.currentUserRank,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier() : super(LeaderboardState(users: []));

  Future<void> fetchLeaderboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final currentUser = supabase.auth.currentUser;
      String? userCity;
      if (currentUser != null) {
        final userRes = await supabase.from('users').select('city').eq('id', currentUser.id).maybeSingle();
        if (userRes != null) {
          userCity = userRes['city'] as String?;
        }
      }

      String? cityFilter;
      if (state.filter == LeaderboardFilter.local) {
        cityFilter = userCity;
      }

      final data = await supabase.rpc('get_weekly_leaderboard', params: {
        'city_filter': cityFilter,
      });
      
      final List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(data as List);
      
      Map<String, dynamic>? currentRank;
      if (currentUser != null) {
        try {
          currentRank = users.firstWhere((u) => u['user_id'] == currentUser.id);
        } catch (_) {
          // Not in top 50
        }
      }

      state = state.copyWith(
        users: users,
        isLoading: false,
        currentUserRank: currentRank,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter(LeaderboardFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    fetchLeaderboard();
  }
}

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier();
});
