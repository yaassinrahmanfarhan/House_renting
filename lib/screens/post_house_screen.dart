import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPropertyScreen extends StatefulWidget {
  final Map<String, dynamic>? houseData; // Added to receive data for editing

  const AddPropertyScreen({super.key, this.houseData});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Helper to check if we are in Edit Mode
  bool get isEditing => widget.houseData != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _houseNameController.text = widget.houseData!['title'] ?? '';
      _locationController.text = widget.houseData!['location_area'] ?? '';
      _priceController.text = widget.houseData!['price_per_month']?.toString() ?? '';
      _roomsController.text = widget.houseData!['rooms']?.toString() ?? '1';
      _descriptionController.text = widget.houseData!['description'] ?? '';
      // Note: In a real app, you'd handle loading the existing network image here
    } else {
      _roomsController.text = '1';
    }
  }

  @override
  void dispose() {
    _houseNameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _selectLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location picker would open here')),
    );
  }

  Future<void> _publishListing() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)),
        ),
      );

      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;

        if (user == null) throw Exception("Session expired. Please log in again.");

        final data = {
          'owner_id': user.id,
          'title': _houseNameController.text.trim(),
          'location_area': _locationController.text.trim(),
          'price_per_month': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'rooms': int.tryParse(_roomsController.text.trim()) ?? 1,
          'description': _descriptionController.text.trim(),
          'image_url': widget.houseData?['image_url'] ?? 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
          'status': 'active',
        };

        if (isEditing) {
          // UPDATE EXISTING
          await supabase
              .from('houses')
              .update(data)
              .eq('id', widget.houseData!['id']);
        } else {
          // INSERT NEW
          await supabase.from('houses').insert(data);
        }

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'Listing updated!' : 'Listing published!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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
        title: Text(
          isEditing ? 'Edit Property' : 'Add Property', // Dynamic Title
          style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUploadPhotoSection(),
                const SizedBox(height: 32),
                _buildInputField(
                  label: 'House Name',
                  controller: _houseNameController,
                  hintText: 'e.g. Sunny Loft in Downtown',
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter house name' : null,
                ),
                const SizedBox(height: 24),
                _buildLocationField(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildPriceField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRoomsField()),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPhoneField(),
                const SizedBox(height: 24),
                _buildDescriptionField(),
                const SizedBox(height: 40),
                _buildPublishButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPhotoSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 2),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Image.file(_selectedImage!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                    Positioned(
                      top: 12, right: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.white, radius: 20,
                        child: IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: _pickImage, color: const Color(0xFF2196F3)),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isEditing && widget.houseData!['image_url'] != null)
                       Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Image.network(widget.houseData!['image_url'], height: 100),
                       ),
                    const Icon(Icons.add_photo_alternate, size: 50, color: Color(0xFF2196F3)),
                    const SizedBox(height: 20),
                    const Text('Change Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
      ),
    );
  }

  // --- Reuse your existing helper widgets below (unchanged except for dynamic button text) ---

  Widget _buildInputField({required String label, required TextEditingController controller, required String hintText, String? Function(String?)? validator, TextInputType? keyboardType, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller, keyboardType: keyboardType, maxLines: maxLines, validator: validator,
        decoration: InputDecoration(hintText: hintText, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
    ]);
  }

  Widget _buildLocationField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Location Area', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _locationController,
        validator: (value) => (value == null || value.isEmpty) ? 'Please enter location' : null,
        decoration: InputDecoration(hintText: 'Area or City', suffixIcon: IconButton(icon: const Icon(Icons.location_on, color: Color(0xFF2196F3)), onPressed: _selectLocation), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
    ]);
  }

  Widget _buildPriceField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Monthly Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _priceController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
        decoration: InputDecoration(hintText: '0.00', prefixText: '\$ ', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
    ]);
  }

  Widget _buildRoomsField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Rooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _roomsController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
        decoration: InputDecoration(hintText: '1', suffixIcon: const Icon(Icons.bed, color: Colors.grey), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
    ]);
  }

  Widget _buildPhoneField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Phone Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _phoneController, keyboardType: TextInputType.phone,
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
        decoration: InputDecoration(hintText: '+1...', suffixIcon: const Icon(Icons.phone, color: Colors.grey), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
    ]);
  }

  Widget _buildDescriptionField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _descriptionController, maxLines: 5,
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
        decoration: InputDecoration(hintText: 'Describe features...', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
    ]);
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _publishListing,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isEditing ? 'Update Listing' : 'Publish Listing', // Dynamic Text
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_outline, color: Colors.white),
          ],
        ),
      ),
    );
  }
}