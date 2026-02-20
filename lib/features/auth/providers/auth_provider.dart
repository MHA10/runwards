import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

// Auth State Stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

// Auth Controller
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no-op
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String city,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user != null) {
        // Create user profile
        // Using upsert to be safe, though insert is fine for new users
        await supabase.from('users').upsert({
          'id': user.id,
          'display_name': displayName,
          'city': city,
          'total_steps': 0,
          'current_rc': 0,
          'vouchers_redeemed': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await supabase.auth.signOut();
    });
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);
