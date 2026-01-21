import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/validators.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;
  
  User? get user => supabase.auth.currentUser;

  String get displayName => user?.userMetadata?['display_name'] ?? 'No Name';
  String get userEmail => user?.email ?? 'No Email';
  String get username => user?.userMetadata?['username'] ?? 'User';

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditProfileSheet(
          currentName: displayName,
          onSave: (newName) async {
            try {
              // 1. Update Metadata
              await supabase.auth.updateUser(
                UserAttributes(data: {'display_name': newName}),
              );
              // 2. Update 'profiles' table (Change 'full_name' to your column name)
              await supabase.from('profiles').update({'full_name': newName}).eq('id', user!.id);
              
              await supabase.auth.getUser(); // Force refresh local user
              if (mounted) setState(() {}); 
            } catch (e) {
              _showError("Update failed: ${e.toString()}");
            }
          },
        ),
      ),
    );
  }

  void _changeUsername() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeUsernameScreen(currentUsername: username),
      ),
    ).then((_) => setState(() {})); 
  }

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileSection(),
            const SizedBox(height: 32),
            _buildSectionHeader('ACCOUNT SECURITY'),
            _buildAccountSecuritySection(),
            const SizedBox(height: 32),
            _buildSectionHeader('SUPPORT & INFO'),
            _buildSupportInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.person, size: 50, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(userEmail, style: const TextStyle(color: Colors.grey)),
          TextButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("Edit Name"),
          )
        ],
      ),
    );
  }

  Widget _buildAccountSecuritySection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.alternate_email,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue.withOpacity(0.1),
            title: 'Username',
            trailing: Text(username, style: const TextStyle(color: Colors.grey)),
            onTap: _changeUsername,
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            iconColor: Colors.orange,
            iconBgColor: Colors.orange.withOpacity(0.1),
            title: 'Change Password',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _changePassword,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required Color iconColor, required Color iconBgColor, required String title, required Widget trailing, required VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }
  
  Widget _buildSupportInfoSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Changed Colors: Purple/Deep Purple -> White/Grey
          _buildSettingsTile(
            icon: Icons.help_outline, 
            iconColor: Colors.grey[700]!, // Deep purple changed to Dark Grey
            iconBgColor: Colors.grey[200]!, 
            title: 'Help Center', 
            trailing: const Icon(Icons.chevron_right), 
            onTap: () {}
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined, 
            iconColor: Colors.white, // Purple changed to White
            iconBgColor: Colors.grey[400]!, // Background changed to Grey for visibility
            title: 'Privacy Policy', 
            trailing: const Icon(Icons.chevron_right), 
            onTap: () {}
          ),
        ],
      ),
    );
  }
}

// --- SUB-SCREENS ---

class EditProfileSheet extends StatelessWidget {
  final String currentName;
  final Function(String) onSave;
  EditProfileSheet({super.key, required this.currentName, required this.onSave});

  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _controller.text = currentName;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Edit Full Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _controller, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                onSave(_controller.text);
                Navigator.pop(context);
              },
              child: const Text("Update Name"),
            ),
          )
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    final error = AppValidators.validatePassword(_passController.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passController.text.trim()),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Updated Successfully")));
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Enter New Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator() 
              : ElevatedButton(onPressed: _updatePassword, child: const Text("Save New Password")),
          ],
        ),
      ),
    );
  }
}

class ChangeUsernameScreen extends StatefulWidget {
  final String currentUsername;
  const ChangeUsernameScreen({super.key, required this.currentUsername});
  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  late TextEditingController _userController;
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: widget.currentUsername);
  }

  Future<void> _updateUsername() async {
    setState(() => _isLoading = true);
    try {
      final newUsername = _userController.text.trim();
      
      // 1. Update Auth Metadata
      await supabase.auth.updateUser(
        UserAttributes(data: {'username': newUsername}),
      );

      // 2. Update Database 'profiles' table (CRITICAL FIX)
      await supabase
          .from('profiles')
          .update({'username': newUsername})
          .eq('id', supabase.auth.currentUser!.id);

      // 3. Force refresh local cache before popping (CRITICAL FIX)
      await supabase.auth.getUser();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Username")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username")),
            const SizedBox(height: 20),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _updateUsername, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}