import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/marketplace_provider.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketplaceProvider.notifier).fetchRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rewards Marketplace'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show redemption history
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                'All',
                'Food',
                'Apparel',
                'Fitness',
                'Charity',
              ].map((category) {
                final isSelected = state.filter == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(marketplaceProvider.notifier).setFilter(category);
                      }
                    },
                    selectedColor: primary.withValues(alpha: 0.2),
                    checkmarkColor: primary,
                    backgroundColor: theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? primary : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? primary : Colors.grey.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Grid
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.rewards.isEmpty
                    ? const Center(child: Text('No rewards found', style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: state.rewards.length,
                        itemBuilder: (context, index) {
                          final reward = state.rewards[index];
                          return _buildRewardCard(context, reward);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, Map<String, dynamic> reward) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cost = reward['cost_rc'] as int;
    final title = reward['brand_name'] as String;
    final description = reward['description'] as String;
    final imageUrl = reward['image_url'] as String?;

    return GestureDetector(
      onTap: () => _showRewardDetail(context, reward),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  color: Colors.grey[900],
                  image: imageUrl != null
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: imageUrl == null
                    ? const Center(child: Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.white24))
                    : null,
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(description,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 16, color: primary),
                      const SizedBox(width: 4),
                      Text('$cost RC',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold, color: primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardDetail(BuildContext context, Map<String, dynamic> reward) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(width: 40, height: 4, color: Colors.grey[700], 
                margin: const EdgeInsets.only(bottom: 24)),
            ),
            // Content
            Text(reward['brand_name'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(reward['description'], style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[300])),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.bolt, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 8),
                Text('${reward['cost_rc']} RC', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _redeem(context, reward),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Redeem Reward'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeem(BuildContext context, Map<String, dynamic> reward) async {
    // Ideally check state first but let's just try/catch
    try {
      final code = await ref.read(marketplaceProvider.notifier).redeemReward(
        reward['id'] as String, reward['cost_rc'] as int);
      
      if (context.mounted) {
        Navigator.pop(context); // Close sheet
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text('Redeemed Successfully!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text('Your voucher code:'),
                const SizedBox(height: 8),
                SelectableText(code, 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Theme.of(context).primaryColor)),
                const SizedBox(height: 16),
                const Text('Show this code to the cashier.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
      }
    }
  }
}
