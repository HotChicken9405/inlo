import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class HostPropertyRegistrationScreen extends StatefulWidget {
  const HostPropertyRegistrationScreen({super.key});

  @override
  State<HostPropertyRegistrationScreen> createState() =>
      _HostPropertyRegistrationScreenState();
}

class _HostPropertyRegistrationScreenState
    extends State<HostPropertyRegistrationScreen> {
  // ── Cloudinary config ──
  static const String _cloudName = 'dgxp8sv9h';
  static const String _uploadPreset = 'inlo_unsigned';

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Step 1
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 2
  final _propertyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalRoomsController = TextEditingController();

  String _selectedPropertyType = 'House';
  bool _animalsAllowed = false;
  bool _wifiAvailable = false;
  bool _parkingAvailable = false;
  bool _poolAvailable = false;
  bool _acAvailable = false;

  // Room types
  final List<Map<String, dynamic>> _roomTypes = [];

  // Seasonal availability
  DateTime _availableFrom = DateTime.now();
  DateTime _availableTo = DateTime.now().add(const Duration(days: 365));

  final List<String> _propertyTypes = [
    'House', 'Villa', 'Apartment', 'Cottage',
    'Bungalow', 'Resort', 'Cabin', 'Studio', 'Other',
  ];

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 75);
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<String?> _uploadToCloudinary(XFile image) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final body = jsonDecode(await response.stream.bytesToString());
      return body['secure_url'] as String?;
    }
    return null;
  }

  void _addRoomType() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RoomTypeForm(
        onAdd: (room) {
          setState(() => _roomTypes.add(room));
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 0 && !_validateStep1()) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateStep1() {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      _showSnack('Please fill all fields');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_propertyNameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _totalRoomsController.text.trim().isEmpty) {
      _showSnack('Please fill all required fields');
      return false;
    }
    if (_selectedImages.isEmpty) {
      _showSnack('Please add at least one photo of the property');
      return false;
    }
    return true;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitRegistration() async {
    if (!_validateStep2()) return;
    setState(() => _isLoading = true);

    try {
      // Check duplicate email
      final existingEmail = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();
      if (existingEmail.docs.isNotEmpty) {
        _showSnack('An account with this email already exists');
        setState(() => _isLoading = false);
        return;
      }

      // Check duplicate phone
      final existingPhone = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: _phoneController.text.trim())
          .get();
      if (existingPhone.docs.isNotEmpty) {
        _showSnack('An account with this phone number already exists');
        setState(() => _isLoading = false);
        return;
      }

      // Create Firebase Auth account
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // Upload photos to Cloudinary
      _showSnack('Uploading photos...');
      List<String> photoUrls = [];
      for (final image in _selectedImages) {
        final url = await _uploadToCloudinary(image);
        if (url != null) photoUrls.add(url);
      }

      // Save host user to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'host',
        'createdAt': Timestamp.now(),
      });

      // Save property to Firestore
      await FirebaseFirestore.instance.collection('properties').add({
        'hostId': uid,
        'hostName': _nameController.text.trim(),
        'propertyName': _propertyNameController.text.trim(),
        'propertyType': _selectedPropertyType,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'description': _descriptionController.text.trim(),
        'pricePerNight': double.tryParse(_priceController.text.trim()) ?? 0,
        'totalRooms': int.tryParse(_totalRoomsController.text.trim()) ?? 0,
        'animalsAllowed': _animalsAllowed,
        'amenities': {
          'wifi': _wifiAvailable,
          'parking': _parkingAvailable,
          'pool': _poolAvailable,
          'ac': _acAvailable,
        },
        'roomTypes': _roomTypes,
        'availableFrom': Timestamp.fromDate(_availableFrom),
        'availableTo': Timestamp.fromDate(_availableTo),
        'photos': photoUrls,
        'createdAt': Timestamp.now(),
        'isActive': true,
      });

      _showSnack('Host account created successfully!');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed';
      if (e.code == 'email-already-in-use') message = 'Email already in use';
      if (e.code == 'weak-password') message = 'Password is too weak';
      if (e.code == 'invalid-email') message = 'Invalid email address';
      _showSnack(message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Host Registration',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Row(
            children: List.generate(2, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  color: i <= _currentPage
                      ? Colors.blue.shade600
                      : Colors.grey.shade200,
                ),
              );
            }),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [_buildStep1(), _buildStep2()],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text('Your details',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          Text('Step 1 of 2 — Personal information',
              style:
              TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 28),
          _buildLabel('FULL NAME'),
          const SizedBox(height: 8),
          _buildTextField(controller: _nameController, hint: 'John Doe'),
          const SizedBox(height: 20),
          _buildLabel('EMAIL ADDRESS'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'host@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildLabel('PHONE NUMBER'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hint: '+94 77 123 4567',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          _buildLabel('PASSWORD'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: '',
            isPassword: true,
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 20),
          _buildLabel('CONFIRM PASSWORD'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: '',
            isPassword: true,
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child:
              const Text('Continue', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text('Your property',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          Text('Step 2 of 2 — Property information',
              style:
              TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 28),

          _buildLabel('PROPERTY NAME'),
          const SizedBox(height: 8),
          _buildTextField(
              controller: _propertyNameController,
              hint: 'e.g. Sunset Villa'),
          const SizedBox(height: 20),

          _buildLabel('PROPERTY TYPE'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPropertyType,
                isExpanded: true,
                items: _propertyTypes
                    .map((type) =>
                    DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedPropertyType = val!),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildLabel('ADDRESS'),
          const SizedBox(height: 8),
          _buildTextField(
              controller: _addressController, hint: 'Street address'),
          const SizedBox(height: 20),

          _buildLabel('CITY'),
          const SizedBox(height: 8),
          _buildTextField(
              controller: _cityController, hint: 'e.g. Colombo'),
          const SizedBox(height: 20),

          _buildLabel('DESCRIPTION'),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
              'Describe your property, surroundings, nearby attractions...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('PRICE / NIGHT (\$)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _priceController,
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('TOTAL ROOMS'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _totalRoomsController,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildLabel('AMENITIES & RULES'),
          const SizedBox(height: 12),
          _buildSwitchTile(
            label: 'Animals / Pets allowed',
            icon: Icons.pets,
            value: _animalsAllowed,
            onChanged: (v) => setState(() => _animalsAllowed = v),
          ),
          _buildSwitchTile(
            label: 'Wi-Fi available',
            icon: Icons.wifi,
            value: _wifiAvailable,
            onChanged: (v) => setState(() => _wifiAvailable = v),
          ),
          _buildSwitchTile(
            label: 'Parking available',
            icon: Icons.local_parking,
            value: _parkingAvailable,
            onChanged: (v) => setState(() => _parkingAvailable = v),
          ),
          _buildSwitchTile(
            label: 'Swimming pool',
            icon: Icons.pool,
            value: _poolAvailable,
            onChanged: (v) => setState(() => _poolAvailable = v),
          ),
          _buildSwitchTile(
            label: 'Air conditioning',
            icon: Icons.ac_unit,
            value: _acAvailable,
            onChanged: (v) => setState(() => _acAvailable = v),
          ),
          const SizedBox(height: 24),

          // ── Room types ──
          _buildLabel('ROOM TYPES'),
          const SizedBox(height: 12),
          ..._roomTypes.asMap().entries.map((entry) {
            final i = entry.key;
            final room = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${room['bedType']} · Max ${room['maxGuests']} guests · \$${room['price']}/night · ${room['count']} room(s)',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: () =>
                        setState(() => _roomTypes.removeAt(i)),
                  ),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addRoomType,
            icon: const Icon(Icons.add),
            label: const Text('Add room type'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 20),
              side: BorderSide(color: Colors.blue.shade400),
              foregroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),

          // ── Seasonal availability ──
          _buildLabel('SEASONAL AVAILABILITY'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _availableFrom,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 730)),
                    );
                    if (picked != null)
                      setState(() => _availableFrom = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OPEN FROM',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${_availableFrom.day}/${_availableFrom.month}/${_availableFrom.year}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _availableTo,
                      firstDate: _availableFrom,
                      lastDate: DateTime.now()
                          .add(const Duration(days: 730)),
                    );
                    if (picked != null)
                      setState(() => _availableTo = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OPEN UNTIL',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${_availableTo.day}/${_availableTo.month}/${_availableTo.year}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Photos ──
          _buildLabel('PROPERTY PHOTOS'),
          const SizedBox(height: 12),
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(
                                File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add photos'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 20),
              side: BorderSide(color: Colors.blue.shade400),
              foregroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 24),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back',
                    style: TextStyle(color: Colors.black87)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Submit',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        title: Text(label,
            style:
            const TextStyle(fontSize: 14, color: Colors.black87)),
        secondary: Icon(icon, color: Colors.blue.shade400, size: 22),
        value: value,
        activeThumbColor: Colors.blue.shade600,
        activeTrackColor: Colors.blue.shade200,
        onChanged: onChanged,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: isPassword
            ? TextButton(
          onPressed: onToggle,
          child: Text(
            obscure ? 'Show' : 'Hide',
            style: TextStyle(color: Colors.blue.shade700),
          ),
        )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────
// Room Type Form (bottom sheet)
// ─────────────────────────────────────────
class _RoomTypeForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const _RoomTypeForm({required this.onAdd});

  @override
  State<_RoomTypeForm> createState() => _RoomTypeFormState();
}

class _RoomTypeFormState extends State<_RoomTypeForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _countController = TextEditingController();
  String _bedType = 'Double';
  int _maxGuests = 2;

  final List<String> _bedTypes = [
    'Single', 'Double', 'Queen', 'King', 'Custom'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add room type',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('ROOM NAME',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Standard Double, Ocean Suite',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            const Text('BED TYPE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _bedType,
                  isExpanded: true,
                  items: _bedTypes
                      .map((b) =>
                      DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _bedType = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PRICE/NIGHT (\$)',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NO. OF ROOMS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '1',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('MAX GUESTS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_maxGuests > 1) setState(() => _maxGuests--);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_maxGuests',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: () => setState(() => _maxGuests++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isEmpty ||
                      _priceController.text.trim().isEmpty ||
                      _countController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill all fields')),
                    );
                    return;
                  }
                  widget.onAdd({
                    'name': _nameController.text.trim(),
                    'bedType': _bedType,
                    'price':
                    double.tryParse(_priceController.text.trim()) ??
                        0,
                    'count':
                    int.tryParse(_countController.text.trim()) ?? 1,
                    'maxGuests': _maxGuests,
                    'bookedDates': [],
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add room type'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}