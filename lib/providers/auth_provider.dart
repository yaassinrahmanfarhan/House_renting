import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading; // UI will use this to show a loading spinner

  // 1. SIGN UP (CREATE a user profile)
  Future<void> signUp(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners(); // Tells the UI: "Hey, I'm busy, show a spinner!"

    try {
      // Create user in Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        debugPrint("User created: ${response.user!.id}");
      }
    } catch (e) {
      rethrow; // Pass the error to the UI to show an alert
    } finally {
      _isLoading = false;
      notifyListeners(); // Tells the UI: "I'm done!"
    }
  }

  // 2. SIGN IN (READ user session)
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. SIGN OUT
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }
}