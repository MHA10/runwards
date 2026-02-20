import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';
import '../repositories/events_repository.dart';

final eventsRepositoryProvider = Provider((ref) => EventsRepository());

class EventState {
  final List<Map<String, dynamic>> activeEvents;
  final bool isLoading;
  // Map of event_id -> participant info
  final Map<String, Map<String, dynamic>> myParticipations;

  EventState({
    required this.activeEvents,
    this.isLoading = false,
    required this.myParticipations,
  });

  EventState copyWith({
    List<Map<String, dynamic>>? activeEvents,
    bool? isLoading,
    Map<String, Map<String, dynamic>>? myParticipations,
  }) {
    return EventState(
      activeEvents: activeEvents ?? this.activeEvents,
      isLoading: isLoading ?? this.isLoading,
      myParticipations: myParticipations ?? this.myParticipations,
    );
  }
}

class EventsNotifier extends StateNotifier<EventState> {
  final EventsRepository _repo;
  
  EventsNotifier(this._repo) : super(EventState(activeEvents: [], myParticipations: {}));

  Future<void> fetchEvents() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = supabase.auth.currentUser;
      
      final eventsData = await _repo.fetchActiveEvents();
      
      Map<String, Map<String, dynamic>> participations = {};
      
      if (user != null) {
        final partsData = await _repo.fetchUserParticipations(user.id);
        
        for (var part in partsData) {
          participations[part['event_id'] as String] = part;
        }

        // Update contributed steps for joined events
        for (var event in eventsData) {
          final eventId = event['id'] as String;
          if (participations.containsKey(eventId)) {
             final steps = await _repo.getStepsContributed(
               user.id, 
               event['start_date'] as String, 
               event['end_date'] as String
             );
             
             await _repo.updateStepsContributed(user.id, eventId, steps);
          }
        }
        
        // Refetch participations to get updated steps
        final updatedPartsData = await _repo.fetchUserParticipations(user.id);
            
        participations.clear();
        for (var part in updatedPartsData) {
          participations[part['event_id'] as String] = part;
        }
      }

      state = state.copyWith(
        activeEvents: List<Map<String, dynamic>>.from(eventsData),
        myParticipations: participations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> joinEvent(String code) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    
    final eventRes = await _repo.fetchEventByCode(code);
    
    if (eventRes == null) {
      throw Exception('Invalid event code');
    }
    
    final eventId = eventRes['id'] as String;
    
    // Check if already joined
    final existing = await _repo.fetchParticipation(user.id, eventId);
    if (existing != null) {
      throw Exception('Already joined');
    }

    await _repo.joinEvent(user.id, eventId);
    
    await fetchEvents();
  }

  Future<void> donateRC(String eventId, int amount) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    
    final userRes = await supabase.from('users').select('current_rc').eq('id', user.id).single();
    final balance = userRes['current_rc'] as int;
    
    if (balance < amount) {
      throw Exception('Insufficient RC');
    }
    
    final partRes = await _repo.fetchParticipation(user.id, eventId);
    if (partRes == null) throw Exception('Not joined');
    final currentDonated = partRes['credits_donated'] as int;
    
    await _repo.donateRC(user.id, eventId, amount, balance, currentDonated);
    
    await fetchEvents();
  }
  
  Future<List<Map<String, dynamic>>> getEventLeaderboard(String eventId) async {
    return _repo.fetchEventLeaderboard(eventId);
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, EventState>((ref) {
  return EventsNotifier(ref.watch(eventsRepositoryProvider));
});
