import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'search_screen.dart';

class HouseDetailsScreen extends StatefulWidget {
  final SearchProperty property;
  const HouseDetailsScreen({super.key, required this.property});

  @override
  State<HouseDetailsScreen> createState() => _HouseDetailsScreenState();
}

class _HouseDetailsScreenState extends State<HouseDetailsScreen> {
  final supabase = Supabase.instance.client;

  // Check if viewing user is the owner
  bool get isOwner => supabase.auth.currentUser?.id == widget.property.ownerId;

  Future<Map<String, dynamic>?> _getAgentDetails() async {
    try {
      // Fetches data from the profiles table based on the ownerId
      final data = await supabase
          .from('profiles')
          .select('username, full_name, phone_number, avatar_url')
          .eq('id', widget.property.ownerId)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageHeader(),
                _buildContentSection(),
              ],
            ),
          ),
          _buildTopBar(),
          if (!isOwner) _buildBottomBookingBar(),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Image.network(widget.property.image, fit: BoxFit.cover),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 40, left: 20,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.property.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(widget.property.address, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          const Text("Owner Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildAgentCard(), // This fetches and shows the data
          const SizedBox(height: 20),
          const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(widget.property.description),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAgentCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getAgentDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        final agent = snapshot.data;
        if (agent == null) return const Text("Owner info not found");

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: agent['avatar_url'] != null ? NetworkImage(agent['avatar_url']) : null,
                child: agent['avatar_url'] == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent['full_name'] ?? agent['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("@${agent['username']}", style: const TextStyle(color: Colors.blue, fontSize: 12)),
                  Text(agent['phone_number'] ?? "No phone number", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBookingBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {}, // Add booking logic
          child: const Text("Book Now"),
        ),
      ),
    );
  }
}