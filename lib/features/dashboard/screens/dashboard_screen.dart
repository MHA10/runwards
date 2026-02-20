import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider data fetch
    // Using simple read in initState. 
    // Usually provider is watched, but init actions should be called once.
    // However, if we leave and come back, dashboardProvider keeps state?
    // autoDispose is not used, so yes.
    // But we might want to refresh on focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).init();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today\'s Activity', 
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${state.todaySteps} steps', 
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt, color: primary, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${state.rcBalance} RC',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Progress Ring
                Center(
                  child: CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 15.0,
                    animation: true,
                    percent: (state.todaySteps / 10000).clamp(0.0, 1.0),
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_run, size: 40, color: primary),
                        const SizedBox(height: 8),
                        Text(
                          '${state.todaySteps}',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '/ 10,000',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor: theme.colorScheme.surface,
                    progressColor: primary,
                    arcType: ArcType.FULL,
                    arcBackgroundColor: theme.colorScheme.surface,
                    startAngle: 0,
                    animateFromLastPercent: true,
                    backgroundWidth: 15,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Earn More Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/earn');
                    },
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('Watch Ad (+50 RC)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Streak
                Text('Streak', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${state.streakDays} Day Streak', 
                               style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: primary)),
                          const Icon(Icons.local_fire_department, color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          // Index 0 is 6 days ago, Index 6 is Today.
                          final isActive = state.last7DaysActivity[index];
                          final isToday = index == 6;
                          
                          final date = DateTime.now().subtract(Duration(days: 6 - index));
                          const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final label = weekDays[date.weekday - 1];
                          
                          return Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isActive ? primary : (isToday ? primary.withValues(alpha: 0.2) : Colors.transparent),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isActive ? primary : (isToday ? primary : Colors.grey.withValues(alpha: 0.3)),
                                    width: 2,
                                  ),
                                ),
                                child: isActive 
                                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                                  : null,
                              ),
                              const SizedBox(height: 8),
                              Text(label, style: theme.textTheme.bodySmall?.copyWith(
                                color: isToday ? primary : Colors.grey,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal
                              )),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
