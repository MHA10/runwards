import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earn_provider.dart';

class EarnScreen extends ConsumerStatefulWidget {
  const EarnScreen({super.key});

  @override
  ConsumerState<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends ConsumerState<EarnScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(earnProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(earnProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    ref.listen(earnProvider, (previous, next) {
      if (previous != null && !previous.showConfetti && next.showConfetti) {
        _confettiController.play();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Earn RC'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Hero Image or Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Icon(Icons.play_arrow_rounded, size: 60, color: primary),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Watch & Earn',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Watch a short video from our partners to support Runwards and earn +50 RC instantly.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  // Ad Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ads remaining today', style: theme.textTheme.bodyLarge),
                        Text('${5 - state.adsWatchedToday} / 5', 
                             style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: primary)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Watch Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.isLoading || state.adsWatchedToday >= 5
                          ? null
                          : () {
                              ref.read(earnProvider.notifier).watchAd();
                            },
                      icon: state.isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_circle_fill),
                      label: Text(state.isLoading ? 'Loading Ad...' : 'Watch Ad (+50 RC)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (state.adsWatchedToday >= 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'You have reached the daily limit. Come back tomorrow!',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [primary, Colors.white, Colors.yellow],
            ),
          ),
        ],
      ),
    );
  }
}
