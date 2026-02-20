import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardProvider.notifier).fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final theme = Theme.of(context);
    
    final top3 = state.users.take(3).toList();
    final rest = state.users.skip(3).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Filter Toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(child: _buildToggleBtn('Global', LeaderboardFilter.global)),
                Expanded(child: _buildToggleBtn('Local', LeaderboardFilter.local)),
              ],
            ),
          ),
          
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.read(leaderboardProvider.notifier).fetchLeaderboard();
                    },
                    child: CustomScrollView(
                      slivers: [
                        // Podium
                        SliverToBoxAdapter(
                          child: _buildPodium(top3),
                        ),
                        // List
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final user = rest[index];
                                final rank = index + 4;
                                final isMe = state.currentUserRank != null && user['user_id'] == state.currentUserRank!['user_id'];
                                return _buildRankRow(user, rank, isMe);
                              },
                              childCount: rest.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          if (state.currentUserRank != null)
             _buildMyRank(state.currentUserRank!),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, LeaderboardFilter filter) {
    final state = ref.watch(leaderboardProvider);
    final isSelected = state.filter == filter;
    final primary = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () => ref.read(leaderboardProvider.notifier).setFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return const SizedBox.shrink();
    
    final first = users.isNotEmpty ? users[0] : null;
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd
          if (second != null) Expanded(child: _buildPodiumUser(second, 2)),
          // 1st
          if (first != null) Expanded(child: _buildPodiumUser(first, 1)),
          // 3rd
          if (third != null) Expanded(child: _buildPodiumUser(third, 3)),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(Map<String, dynamic> user, int rank) {
    final height = rank == 1 ? 160.0 : (rank == 2 ? 130.0 : 100.0);
    final color = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey[300] : Colors.brown[300]);
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 40 : 30,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Text(user['display_name'].toString().substring(0,1).toUpperCase()),
        ),
        const SizedBox(height: 8),
        Text(user['display_name'], style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        Text('${user['weekly_steps']}', style: TextStyle(color: primary, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(top: BorderSide(color: color!, width: 4)),
          ),
          child: Center(child: Text('$rank', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))),
        ),
      ],
    );
  }

  Widget _buildRankRow(Map<String, dynamic> user, int rank, bool isMe) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold))),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[800],
            child: Text(user['display_name'].toString().substring(0,1).toUpperCase(), style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['display_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(user['city'] ?? 'Unknown', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Text('${user['weekly_steps']}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
  
  Widget _buildMyRank(Map<String, dynamic> user) {
    final rank = user['rank'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))),
          const Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${user['weekly_steps']} Steps', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}
