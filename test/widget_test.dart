import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runwards/features/auth/screens/splash_screen.dart';
import 'package:runwards/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock AuthState
// Since we can't easily mock Supabase static instance without dependency injection rework or a wrapper,
// We will test that the widget renders basic UI elements.
// Ideally, we would mock Supabase client.

void main() {
  testWidgets('Splash Screen renders logo and text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Verify that text is present
    expect(find.text('Runwards'), findsOneWidget);
    expect(find.text('Watch and Earn RC'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });
}
