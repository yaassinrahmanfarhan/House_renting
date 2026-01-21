import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'house_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  // State for Filters
  //String _selectedSort = 'Newest';
  String _searchQuery = '';
  RangeValues _currentPriceRange = const RangeValues(0, 10000);
  int? _minRooms;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        initialPriceRange: _currentPriceRange,
        initialRooms: _minRooms ?? 1,
        onApplyFilters: (filters) {
          setState(() {
            _currentPriceRange = filters['priceRange'];
            _minRooms = filters['rooms'];
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _currentPriceRange = const RangeValues(0, 10000);
      _minRooms = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // BUILDING THE QUERY
    var query = supabase.from('houses').stream(primaryKey: ['id']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildSearchBar(),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 18),
                  label: const Text("Filters"),
                  onPressed: _openFilters,
                ),
                const SizedBox(width: 8),
                if (_searchQuery.isNotEmpty || _minRooms != null)
                  ActionChip(
                    label: const Text("Reset"),
                    onPressed: _resetFilters,
                    backgroundColor: Colors.red[50],
                  ),
              ],
            ),
          ),

          // RESULTS STREAM
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: query,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No properties found."));
                }

                final filteredList = snapshot.data!.where((house) {
                  final matchesSearch =
                      house['title'].toString().toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                      house['location_area'].toString().toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                  final matchesPrice =
                      house['price_per_month'] >= _currentPriceRange.start &&
                      house['price_per_month'] <= _currentPriceRange.end;
                  final matchesRooms =
                      _minRooms == null || house['rooms'] >= _minRooms;

                  return matchesSearch && matchesPrice && matchesRooms;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return _buildPropertyCard(
                      SearchProperty.fromMap(filteredList[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search title or location...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildPropertyCard(SearchProperty property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              property.image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.home_work,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${property.price}/mo',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  property.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  property.address,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.bed, size: 20, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${property.rooms} Rooms'),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HouseDetailsScreen(property: property),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "View Details",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final RangeValues initialPriceRange;
  final int initialRooms;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.onApplyFilters,
    required this.initialPriceRange,
    required this.initialRooms,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late int _selectedRooms;

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialPriceRange;
    _selectedRooms = widget.initialRooms;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Filter Properties",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text("Price Range"),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (v) => setState(() => _priceRange = v),
          ),
          const SizedBox(height: 20),
          const Text("Minimum Rooms"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 2, 3, 4, 5]
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text("$r+"),
                      selected: _selectedRooms == r,
                      onSelected: (s) => setState(() => _selectedRooms = r),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApplyFilters({
                'priceRange': _priceRange,
                'rooms': _selectedRooms,
              }),
              child: const Text("Apply Filters"),
            ),
          ),
        ],
      ),
    );
  }
}
class SearchProperty {
  final String id;
  final String ownerId;
  final String title;
  final String address;
  final String description;
  final int price;
  final int rooms;
  final String image;

  SearchProperty({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.address,
    required this.description,
    required this.price,
    required this.rooms,
    required this.image,
  });

  factory SearchProperty.fromMap(Map<String, dynamic> map) {
    return SearchProperty(
      id: map['id'].toString(),
      ownerId: map['owner_id'].toString(), // Critical for fetching owner data
      title: map['title'] ?? 'No Title',
      address: map['location_area'] ?? 'No Location',
      description: map['description'] ?? 'No description provided.',
      price: (map['price_per_month'] ?? 0).toInt(),
      rooms: map['rooms'] ?? 0,
      image: map['image_url'] ?? '',
    );
  }
}