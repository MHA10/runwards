import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router.dart';
import 'core/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  
  try {
    // Requires google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed (expected if missing config): $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Runwards',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.black,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF1E1E1E),
            indicatorColor: const Color(0xFF00E676).withValues(alpha: 0.2),
            labelTextStyle: WidgetStateProperty.all(
               const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
            )
        )
      ),
      routerConfig: router,
    );
  }
}
