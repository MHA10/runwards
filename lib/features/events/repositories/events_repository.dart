import '../../../core/supabase_client.dart';

class EventsRepository {
  Future<List<Map<String, dynamic>>> fetchActiveEvents() async {
    final now = DateTime.now().toIso8601String();
    return await supabase
        .from('events')
        .select()
        .gte('end_date', now)
        .order('end_date');
  }

  Future<List<Map<String, dynamic>>> fetchUserParticipations(String userId) async {
    return await supabase
        .from('event_participants')
        .select()
        .eq('user_id', userId);
  }

  Future<int> getStepsContributed(String userId, String startDateStr, String endDateStr) async {
     final start = DateTime.parse(startDateStr).toIso8601String().substring(0, 10);
     final end = DateTime.parse(endDateStr).toIso8601String().substring(0, 10);
     
     final sumRes = await supabase.from('step_logs')
       .select('steps')
       .eq('user_id', userId)
       .gte('date', start)
       .lte('date', end);
     
     int total = 0;
     for (var row in sumRes) {
       total += row['steps'] as int;
     }
     return total;
  }

  Future<void> updateStepsContributed(String userId, String eventId, int totalSteps) async {
    await supabase.from('event_participants').update({
       'steps_contributed': totalSteps
     }).eq('user_id', userId).eq('event_id', eventId);
  }

  Future<Map<String, dynamic>?> fetchEventByCode(String code) async {
    return await supabase.from('events').select().eq('join_code', code).maybeSingle();
  }

  Future<Map<String, dynamic>?> fetchParticipation(String userId, String eventId) async {
    return await supabase.from('event_participants').select().eq('user_id', userId).eq('event_id', eventId).maybeSingle();
  }

  Future<void> joinEvent(String userId, String eventId) async {
    await supabase.from('event_participants').insert({
      'user_id': userId,
      'event_id': eventId,
    });
  }

  Future<void> donateRC(String userId, String eventId, int amount, int currentBalance, int currentDonated) async {
    // Transaction-like update (Supabase doesn't support transactions on client SDK easily without RPC, doing optimistic chain)
    await supabase.from('users').update({
      'current_rc': currentBalance - amount,
    }).eq('id', userId);
    
    await supabase.from('event_participants').update({
      'credits_donated': currentDonated + amount,
    }).eq('user_id', userId).eq('event_id', eventId);
  }

  Future<List<Map<String, dynamic>>> fetchEventLeaderboard(String eventId) async {
    // We need to join with users to get display names
    // This assumes there is a relation set up or we fetch users separately.
    // fetch participants sorted by steps_contributed
    final participants = await supabase
        .from('event_participants')
        .select('steps_contributed, user_id')
        .eq('event_id', eventId)
        .order('steps_contributed', ascending: false)
        .limit(10);
        
    // For MVP, if we can't easily join in one query without proper foreign key relation config in client (which is fine usually),
    // we fetch user details.
    // Ideally, we create a view or RPC for this.
    // Let's rely on client-side join for small list (top 10).
    
    if (participants.isEmpty) return [];
    
    final userIds = participants.map((p) => p['user_id']).toList();
    final users = await supabase.from('users').select('id, display_name').inFilter('id', userIds);
    
    final userMap = {for (var u in users) u['id']: u['display_name']};
    
    return participants.map((p) => {
      'user_id': p['user_id'],
      'steps_contributed': p['steps_contributed'],
      'display_name': userMap[p['user_id']] ?? 'Unknown User',
    }).toList();
  }
}
