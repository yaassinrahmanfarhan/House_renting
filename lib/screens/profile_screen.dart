import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  bool _isSaving = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // 1. Fetch & Auto-Create Profile
  Future<Map<String, dynamic>> _getProfileData() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      final newProfile = {
        'id': user.id,
        'username': user.email!.split('@')[0],
        'full_name': '',
        'phone_number': '',
        'bio': '',
      };
      await supabase.from('profiles').insert(newProfile);
      _usernameController.text = newProfile['username'] as String;
      return newProfile;
    }

    _usernameController.text = response['username'] ?? '';
    _fullNameController.text = response['full_name'] ?? '';
    _phoneController.text = response['phone_number'] ?? '';
    _bioController.text = response['bio'] ?? '';

    return response;
  }

  // 2. Update Profile Logic
  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = supabase.auth.currentUser;
      await supabase.from('profiles').update({
        'username': _usernameController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 3. Navigation & Auth Handlers
  Future<void> _handleSignOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _openSettings() {
    // Placeholder for future implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings coming soon!")),
    );
  }

  Future<void> _deleteHouse(int houseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: const Text("Are you sure you want to remove this property?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('houses').delete().eq('id', houseId);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Settings Icon (beside logout)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),

                _buildTextField("Username", _usernameController, Icons.alternate_email),
                const SizedBox(height: 15),
                _buildTextField("Full Name", _fullNameController, Icons.badge_outlined),
                const SizedBox(height: 15),
                _buildTextField("Phone Number", _phoneController, Icons.phone_android_outlined),
                const SizedBox(height: 15),
                _buildTextField("Bio", _bioController, Icons.edit_note_outlined, maxLines: 3),
                
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

                const Divider(height: 60),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("My Listings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('houses')
                      .stream(primaryKey: ['id'])
                      .eq('owner_id', supabase.auth.currentUser!.id),
                  builder: (context, houseSnapshot) {
                    if (!houseSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final myHouses = houseSnapshot.data!;

                    if (myHouses.isEmpty) return const Text("You haven't posted any houses yet.");

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: myHouses.length,
                      itemBuilder: (context, index) {
                        final house = myHouses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: house['image_url'] != null 
                                ? Image.network(house['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.home),
                            ),
                            title: Text(house['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("\$${house['price_per_month']}/mo"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteHouse(house['id']),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}