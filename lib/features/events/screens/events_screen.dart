import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/events_provider.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsProvider.notifier).fetchEvents();
    });
  }

  void _showJoinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Join Event'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Event Code (6 digits)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(eventsProvider.notifier).joinEvent(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showDonateDialog(BuildContext context, String eventId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Donate RC'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Amount'),
          keyboardType: TextInputType.number,
        ),
        actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
           TextButton(
             onPressed: () async {
                final amount = int.tryParse(controller.text);
                if (amount == null || amount <= 0) return;
                try {
                  await ref.read(eventsProvider.notifier).donateRC(eventId, amount);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donated!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
             },
             child: const Text('Donate'),
           ),
        ],
      ),
    );
  }

  void _showEventLeaderboard(BuildContext context, String eventId, String eventTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(eventsProvider.notifier).getEventLeaderboard(eventId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return SizedBox(height: 200, child: Center(child: Text('Error: ${snapshot.error}')));
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return const SizedBox(height: 200, child: Center(child: Text('No participants yet.')));
            }
            
            return Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: Column(
                children: [
                  Text('Top Participants - $eventTitle', 
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(item['display_name']),
                          trailing: Text('${item['steps_contributed']} steps'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('NGO Events'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Join with Code',
            onPressed: _showJoinDialog,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.activeEvents.isEmpty
              ? const Center(child: Text('No active events.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.activeEvents.length,
                  itemBuilder: (context, index) {
                    final event = state.activeEvents[index];
                    final eventId = event['id'] as String;
                    final isJoined = state.myParticipations.containsKey(eventId);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event['image_url'] != null)
                            Image.network(
                              event['image_url'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event['title'], style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                Text(event['organization'], style: theme.textTheme.bodyMedium?.copyWith(color: primary)),
                                const SizedBox(height: 8),
                                Text(event['description'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                                const SizedBox(height: 16),
                                
                                // Progress
                                if (isJoined) ...[
                                  _buildProgress(context, event, state.myParticipations[eventId]!),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildDonateButton(context, eventId),
                                      TextButton.icon(
                                        onPressed: () => _showEventLeaderboard(context, eventId, event['title']),
                                        icon: const Icon(Icons.leaderboard),
                                        label: const Text('Top 10'),
                                      )
                                    ],
                                  ),
                                ] else ...[
                                  ElevatedButton(
                                    onPressed: _showJoinDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Join Event'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildProgress(BuildContext context, Map<String, dynamic> event, Map<String, dynamic> participation) {
    final goal = event['goal_steps'] as int;
    final current = participation['steps_contributed'] as int; 
    
    final percent = (current / goal).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Contribution', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$current / $goal steps'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.grey[800],
        ),
      ],
    );
  }
  
  Widget _buildDonateButton(BuildContext context, String eventId) {
     return OutlinedButton.icon(
       onPressed: () {
         _showDonateDialog(context, eventId);
       },
       icon: const Icon(Icons.volunteer_activism),
       label: const Text('Donate RC'),
     );
  }
}
