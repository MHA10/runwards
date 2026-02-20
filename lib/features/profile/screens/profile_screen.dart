import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = state.user;
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings logic here
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: theme.colorScheme.surface,
                  title: const Text('Settings'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('Notifications'),
                        value: true, 
                        onChanged: (val) {
                          // Mock logic
                        },
                        secondary: const Icon(Icons.notifications),
                      ),
                      SwitchListTile(
                        title: const Text('Health Sync'),
                        value: true, 
                        onChanged: (val) {
                          // Mock logic or open app settings
                        },
                        secondary: const Icon(Icons.favorite),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          ref.read(authControllerProvider.notifier).signOut();
                          context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(profileProvider.notifier).fetchProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                  border: Border.all(color: primary, width: 3),
                  boxShadow: [
                    BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 20),
                  ],
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                user['display_name'] ?? 'User',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                user['city'] ?? 'Unknown City',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
              
              const SizedBox(height: 32),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(context, 'Total Steps', NumberFormat.compact().format(user['total_steps']), Icons.directions_walk),
                  _buildStat(context, 'Total RC', '${user['current_rc']}', Icons.bolt, highlight: true),
                  _buildStat(context, 'Redeemed', '${user['vouchers_redeemed']}', Icons.card_giftcard),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Heatmap
              Align(
                alignment: Alignment.centerLeft,
                child: Text('30-Day Activity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(30, (index) {
                     // 0 = 29 days ago, 29 = today
                     final date = DateTime.now().subtract(Duration(days: 29 - index));
                     final dateStr = date.toIso8601String().substring(0, 10);
                     final steps = state.heatmap[dateStr] ?? 0;
                     
                     // Max height 80, assume 10k goal
                     double h = (steps / 10000 * 80).clamp(4.0, 80.0);
                     
                     return Container(
                       width: 6,
                       height: h,
                       decoration: BoxDecoration(
                         color: steps >= 10000 ? primary : (steps > 0 ? primary.withValues(alpha: 0.5) : Colors.grey[800]),
                         borderRadius: BorderRadius.circular(3),
                       ),
                     );
                  }),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Badges
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Badges', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.badges.length,
                itemBuilder: (context, index) {
                  final badge = state.badges[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: badge.isUnlocked ? primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badge.isUnlocked ? primary.withValues(alpha: 0.3) : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIconData(badge.icon),
                          color: badge.isUnlocked ? primary : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                badge.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: badge.isUnlocked ? Colors.white : Colors.grey,
                                ),
                              ),
                              Text(
                                badge.isUnlocked ? 'Unlocked' : 'Locked',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon, {bool highlight = false}) {
    final theme = Theme.of(context);
    final color = highlight ? theme.colorScheme.primary : Colors.white;
    
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'directions_walk': return Icons.directions_walk;
      case 'emoji_events': return Icons.emoji_events;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'play_circle': return Icons.play_circle_fill;
      default: return Icons.star;
    }
  }
}
