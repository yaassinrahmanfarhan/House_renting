import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

// 1. The Entry Point: This is where the app "wakes up".
Future<void> main() async {
  // Tells Flutter to wait until it's ready before starting the engine.
  WidgetsFlutterBinding.ensureInitialized();

  // Connects your app to your Supabase project.
  await Supabase.initialize(
    url: 'https://feycmrjvkgctstpydfex.supabase.co', // Paste your URL from Supabase Settings
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZleWNtcmp2a2djdHN0cHlkZmV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNTIyNzYsImV4cCI6MjA4MjkyODI3Nn0.TnfVTBLe61sQhrWVu6foST7WofrlnIVRzw3OR1fa_Js', // Paste your Anon Key
  );

  runApp(
    // 2. The Provider: This wraps your whole app so everyone can share data.
    // For now, we leave it empty, but we will add AuthProvider here soon.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const HouseRentApp(),
    ),
  );
}

// 3. The App Widget: This sets the "Theme" (colors) and the first screen.
class HouseRentApp extends StatelessWidget {
  const HouseRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // If Supabase says we have a user, go to Home. Otherwise, go to Signup.
          if (snapshot.hasData && snapshot.data!.session != null) {
            return const HomeScreen(); // You need to create this!
          }
          return const SignUpScreen();
        },
      ),
    );
  }
}

