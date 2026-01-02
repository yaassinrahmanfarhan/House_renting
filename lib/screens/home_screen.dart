import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_house_screen.dart'; // Ensure this filename matches yours (e.g., add_property_screen.dart)
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final supabase = Supabase.instance.client;

  // Real-time stream for houses
  final Stream<List<Map<String, dynamic>>> _housesStream = Supabase.instance.client
      .from('houses')
      .stream(primaryKey: ['id'])
      .order('created_at');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F5),
      // The body changes based on the index. If index is 0, show Home feed.
      body: _selectedIndex == 0 
          ? _buildHomeBody() 
          : const Center(child: Text("Search Screen Coming Soon")), 
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Separated the Home Content for better organization
  Widget _buildHomeBody() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchSection(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Explore Houses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _housesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error: ${snapshot.error}'),
                );
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final houses = snapshot.data!;
                if (houses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text("No houses available yet."),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: houses.length,
                  itemBuilder: (context, index) {
                    final data = houses[index];
                    return _buildPropertyCard(data);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userEmail = supabase.auth.currentUser?.email ?? "User";
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome,', style: TextStyle(color: Colors.grey, fontSize: 16)),
              Text(
                userEmail.split('@')[0],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Clicking the Avatar also goes to Profile
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
            child: const CircleAvatar(
              radius: 25, 
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by area...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> house) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              house['image_url'] ?? 'https://via.placeholder.com/400x200',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50),
              ),
            ),
          ),
          ListTile(
            title: Text(house['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(house['location_area']),
            trailing: Text(
              '\$${house['price_per_month']}',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == 2) {
          // POST button: Opens the screen as a temporary page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
          );
        } else if (index == 3) {
          // PROFILE button: Opens the screen as a temporary page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          // Change tabs for Home and Search
          setState(() => _selectedIndex = index);
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Post'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}