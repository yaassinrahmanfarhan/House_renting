import 'package:flutter/material.dart';
import 'search_screen.dart'; // Import to access the SearchProperty model

class HouseDetailsScreen extends StatelessWidget {
  final SearchProperty property;

  const HouseDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(property.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              property.image,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => 
                  Container(height: 300, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$${property.price}/month', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  Text(property.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      Text(property.address, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    "This beautiful property features modern amenities, spacious rooms, and is located in a prime neighborhood. Perfect for families or professionals.",
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}