import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../../../services/health_service.dart';

final healthServiceProvider = Provider((ref) => HealthService());

class DashboardState {
  final int todaySteps;
  final int rcBalance;
  final int streakDays;
  final List<bool> last7DaysActivity; // True if steps > 0. Index 0 = 6 days ago, Index 6 = Today.
  final bool isLoading;

  DashboardState({
    required this.todaySteps,
    required this.rcBalance,
    required this.streakDays,
    required this.last7DaysActivity,
    this.isLoading = false,
  });

  DashboardState copyWith({
    int? todaySteps,
    int? rcBalance,
    int? streakDays,
    List<bool>? last7DaysActivity,
    bool? isLoading,
  }) {
    return DashboardState(
      todaySteps: todaySteps ?? this.todaySteps,
      rcBalance: rcBalance ?? this.rcBalance,
      streakDays: streakDays ?? this.streakDays,
      last7DaysActivity: last7DaysActivity ?? this.last7DaysActivity,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final HealthService _healthService;
  
  DashboardNotifier(this._healthService) : super(DashboardState(
    todaySteps: 0, 
    rcBalance: 0, 
    streakDays: 0,
    last7DaysActivity: List.filled(7, false),
  ));

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Request Health Permissions
      await _healthService.requestPermissions();
      
      // 2. Fetch Steps
      final steps = await _healthService.getTodaySteps();
      state = state.copyWith(todaySteps: steps);
      
      // 3. Sync to Supabase
      await _syncSteps(steps);

      // 4. Fetch Profile & Logs
      await _fetchData();
      
    } catch (e) {
      // Handle error
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _syncSteps(int steps) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Get previous logged steps for today
    final logsRes = await supabase
        .from('step_logs')
        .select('steps')
        .eq('user_id', user.id)
        .eq('date', today)
        .maybeSingle();
        
    int oldSteps = 0;
    if (logsRes != null) {
      oldSteps = logsRes['steps'] as int;
    }
    
    // Only update if steps increased
    if (steps < oldSteps) return; 

    // Calculate RC difference
    int oldRC = _calculateRC(oldSteps);
    int newRC = _calculateRC(steps);
    int rcDelta = newRC - oldRC;
    
    // Upsert step log
    await supabase.from('step_logs').upsert({
      'user_id': user.id,
      'date': today,
      'steps': steps,
    }, onConflict: 'user_id, date');

    // Update User Balance & Total Steps
    if (rcDelta != 0 || steps != oldSteps) {
       final userRes = await supabase.from('users').select('current_rc, total_steps').eq('id', user.id).single();
       int currentBalance = userRes['current_rc'] as int;
       int totalSteps = userRes['total_steps'] as int;
       
       int stepDelta = steps - oldSteps;
       
       await supabase.from('users').update({
         'current_rc': currentBalance + rcDelta,
         'total_steps': totalSteps + stepDelta,
       }).eq('id', user.id);
    }
  }

  int _calculateRC(int steps) {
    int rc = (steps / 1000).floor() * 10;
    if (steps >= 10000) rc += 50; // Bonus for 10k
    return rc;
  }

  Future<void> _fetchData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Fetch user profile
    final userRes = await supabase.from('users').select('current_rc').eq('id', user.id).single();
    int rc = userRes['current_rc'] as int;

    // Fetch last 30 days logs for streak calculation
    final now = DateTime.now();
    final streakStartDate = now.subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);
    
    final allLogs = await supabase.from('step_logs')
        .select('date, steps')
        .eq('user_id', user.id)
        .gte('date', streakStartDate)
        .order('date', ascending: false); // descending date
        
    Map<String, int> fullLogsMap = {};
    for (var log in allLogs) {
      fullLogsMap[log['date'] as String] = log['steps'] as int;
    }
    
    // Calculate streak
    int currentStreak = 0;
    for (int i = 0; i < 30; i++) {
       final d = now.subtract(Duration(days: i));
       final dateStr = d.toIso8601String().substring(0, 10);
       int s = fullLogsMap[dateStr] ?? 0;
       
       if (s > 0) {
         currentStreak++;
       } else {
         // If today (i=0) is 0 steps, don't break streak yet, assuming user just started day
         if (i == 0) continue; 
         break;
       }
    }
    
    // Fill last 7 days activity
    List<bool> activity = List.filled(7, false);
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    for (int i = 0; i < 7; i++) {
       final d = sevenDaysAgo.add(Duration(days: i)); // 0..6
       final dateStr = d.toIso8601String().substring(0, 10);
       int s = fullLogsMap[dateStr] ?? 0;
       activity[i] = s > 0;
    }

    state = state.copyWith(
      rcBalance: rc,
      streakDays: currentStreak,
      last7DaysActivity: activity,
    );
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(healthServiceProvider));
});
