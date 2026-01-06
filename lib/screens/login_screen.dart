import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/validators.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final supabase = Supabase.instance.client; // Added reference for easy access

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Connection failed. Please check your internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW: Forgot Password Logic ---
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    // 1. Check if email field is empty
    if (email.isEmpty) {
      _showError("Please enter your email address in the field above first.");
      return;
    }

    // 2. Validate email format
    final emailError = AppValidators.validateEmail(email);
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Request Supabase to send reset email
      await supabase.auth.resetPasswordForEmail(email);
      
      if (mounted) {
        _showSuccess("Password reset link sent to $email");
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("An error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- NEW: Success Feedback ---
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeaderIcon(),
                  const SizedBox(height: 30),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                  ),
                  const Text(
                    "Sign in to continue your search",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  _buildLabel("Email"),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: AppValidators.validateEmail,
                    decoration: _inputDecoration("hello@example.com", Icons.email_outlined),
                  ),
                  
                  const SizedBox(height: 20),

                  _buildLabel("Password"),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signIn(),
                    validator: AppValidators.validatePassword,
                    decoration: _inputDecoration("••••••••", Icons.lock_outline_rounded).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                  ),

                  _buildForgotPassword(),
                  const SizedBox(height: 30),
                  _buildLoginButton(),
                  const SizedBox(height: 20),
                  _buildSignupLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.home_work_rounded, size: 40, color: Colors.blue),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        // UPDATED: Linked to our new logic
        onPressed: _isLoading ? null : _handleForgotPassword, 
        child: const Text(
          "Forgot Password?", 
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : const Text("Sign In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Create Account", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1D1E))),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
    );
  }
}