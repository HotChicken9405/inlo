import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class HostProfileScreen extends StatefulWidget {
  const HostProfileScreen({super.key});

  @override
  State<HostProfileScreen> createState() =>
      _HostProfileScreenState();
}

class _HostProfileScreenState extends State<HostProfileScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isEditing = false;
  bool _isLoading = false;

  static const String _cloudName = 'dgxp8sv9h';
  static const String _uploadPreset = 'inlo_unsigned';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _profilePhotoUrl = '';

  // Property edit fields
  final _propertyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _propertyId = '';
  bool _wifiAvailable = false;
  bool _parkingAvailable = false;
  bool _poolAvailable = false;
  bool _acAvailable = false;
  bool _animalsAllowed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final userData = userDoc.data() ?? {};
    _nameController.text = userData['name'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _phoneController.text = userData['phone'] ?? '';
    _profilePhotoUrl = userData['profilePhoto'] ?? '';

    final propSnap = await FirebaseFirestore.instance
        .collection('properties')
        .where('hostId', isEqualTo: uid)
        .limit(1)
        .get();

    if (propSnap.docs.isNotEmpty) {
      final propData =
      propSnap.docs.first.data();
      _propertyId = propSnap.docs.first.id;
      _propertyNameController.text =
          propData['propertyName'] ?? '';
      _addressController.text = propData['address'] ?? '';
      _cityController.text = propData['city'] ?? '';
      _descriptionController.text =
          propData['description'] ?? '';
      _priceController.text =
          propData['pricePerNight']?.toString() ?? '';
      final amenities = Map<String, dynamic>.from(
          propData['amenities'] ?? {});
      _wifiAvailable = amenities['wifi'] ?? false;
      _parkingAvailable = amenities['parking'] ?? false;
      _poolAvailable = amenities['pool'] ?? false;
      _acAvailable = amenities['ac'] ?? false;
      _animalsAllowed = propData['animalsAllowed'] ?? false;
    }
    setState(() {});
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (image == null) return;

    setState(() => _isLoading = true);
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
          await http.MultipartFile.fromPath('file', image.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final body =
      jsonDecode(await response.stream.bytesToString());
      setState(() {
        _profilePhotoUrl = body['secure_url'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showSnack('Failed to upload photo');
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showSnack('Please fill all personal details');
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Update user doc
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profilePhoto': _profilePhotoUrl,
      });

      // Update property doc
      if (_propertyId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(_propertyId)
            .update({
          'propertyName': _propertyNameController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'description': _descriptionController.text.trim(),
          'pricePerNight':
          double.tryParse(_priceController.text.trim()) ??
              0,
          'hostName': _nameController.text.trim(),
          'animalsAllowed': _animalsAllowed,
          'amenities': {
            'wifi': _wifiAvailable,
            'parking': _parkingAvailable,
            'pool': _poolAvailable,
            'ac': _acAvailable,
          },
        });
      }

      // Update email in Firebase Auth if changed
      final currentEmail =
          FirebaseAuth.instance.currentUser!.email;
      if (_emailController.text.trim() != currentEmail) {
        await FirebaseAuth.instance.currentUser!
            .verifyBeforeUpdateEmail(
            _emailController.text.trim());
        _showSnack(
            'Verification sent. Please verify new email.');
      } else {
        _showSnack('Profile updated successfully!');
      }

      setState(() => _isEditing = false);
    } catch (e) {
      _showSnack('Failed to update: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(Timestamp t) {
    final d = t.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('Profile',
              style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
          actions: [
            if (!_isEditing)
              TextButton(
                onPressed: () =>
                    setState(() => _isEditing = true),
                child: Text('Edit',
                    style: TextStyle(
                        color: Colors.blue.shade600)),
              )
            else
              TextButton(
                onPressed: () =>
                    setState(() => _isEditing = false),
                child: Text('Cancel',
                    style: TextStyle(
                        color: Colors.grey.shade500)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                      _profilePhotoUrl.isNotEmpty
                          ? NetworkImage(_profilePhotoUrl)
                          : null,
                      child: _profilePhotoUrl.isEmpty
                          ? Icon(Icons.person,
                          size: 52,
                          color: Colors.blue.shade600)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadPhoto,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white,
                                  width: 2),
                            ),
                            child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Personal details section
              _sectionTitle('Personal Details'),
              const SizedBox(height: 14),
              _buildLabel('FULL NAME'),
              const SizedBox(height: 8),
              _buildField(
                  controller: _nameController,
                  hint: 'Full name',
                  enabled: _isEditing),
              const SizedBox(height: 14),
              _buildLabel('EMAIL ADDRESS'),
              const SizedBox(height: 8),
              _buildField(
                controller: _emailController,
                hint: 'Email',
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildLabel('PHONE NUMBER'),
              const SizedBox(height: 8),
              _buildField(
                controller: _phoneController,
                hint: 'Phone number',
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Property details section
              if (_propertyId.isNotEmpty) ...[
                _sectionTitle('Property Details'),
                const SizedBox(height: 14),
                _buildLabel('PROPERTY NAME'),
                const SizedBox(height: 8),
                _buildField(
                    controller: _propertyNameController,
                    hint: 'Property name',
                    enabled: _isEditing),
                const SizedBox(height: 14),
                _buildLabel('ADDRESS'),
                const SizedBox(height: 8),
                _buildField(
                    controller: _addressController,
                    hint: 'Address',
                    enabled: _isEditing),
                const SizedBox(height: 14),
                _buildLabel('CITY'),
                const SizedBox(height: 8),
                _buildField(
                    controller: _cityController,
                    hint: 'City',
                    enabled: _isEditing),
                const SizedBox(height: 14),
                _buildLabel('DESCRIPTION'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  enabled: _isEditing,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Property description',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400),
                    filled: true,
                    fillColor: _isEditing
                        ? Colors.grey.shade100
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 14),
                _buildLabel('PRICE PER NIGHT (LKR)'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _priceController,
                  hint: '0.00',
                  enabled: _isEditing,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Amenities toggles
                _buildLabel('AMENITIES & RULES'),
                const SizedBox(height: 10),
                _buildSwitchTile(
                    'Animals / Pets allowed',
                    Icons.pets,
                    _animalsAllowed,
                        (v) => setState(
                            () => _animalsAllowed = v)),
                _buildSwitchTile(
                    'Wi-Fi available',
                    Icons.wifi,
                    _wifiAvailable,
                        (v) => setState(
                            () => _wifiAvailable = v)),
                _buildSwitchTile(
                    'Parking available',
                    Icons.local_parking,
                    _parkingAvailable,
                        (v) => setState(
                            () => _parkingAvailable = v)),
                _buildSwitchTile(
                    'Swimming pool',
                    Icons.pool,
                    _poolAvailable,
                        (v) =>
                        setState(() => _poolAvailable = v)),
                _buildSwitchTile(
                    'Air conditioning',
                    Icons.ac_unit,
                    _acAvailable,
                        (v) =>
                        setState(() => _acAvailable = v)),
                const SizedBox(height: 8),
              ],

              if (_isEditing) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(
                      child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(
                          vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              12)),
                    ),
                    child: const Text('Save changes',
                        style: TextStyle(
                            fontSize: 16)),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Revenue overview
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('hostId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  final totalRevenue = docs.fold<double>(
                      0,
                          (sum, d) =>
                      sum +
                          ((d.data() as Map<String,
                              dynamic>)[
                          'totalAmount'] as num? ??
                              0)
                              .toDouble());
                  final totalBookings = docs.length;
                  final cardPayments = docs
                      .where((d) =>
                  (d.data() as Map<String,
                      dynamic>)['paymentMethod'] ==
                      'card')
                      .length;
                  final cashPayments =
                      totalBookings - cardPayments;

                  return Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Revenue Overview'),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade700,
                              Colors.blue.shade500
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text('Total Revenue',
                                style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.8),
                                    fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              'LKR ${totalRevenue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight:
                                  FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                    child: _revenueChip(
                                        'Bookings',
                                        '$totalBookings')),
                                Expanded(
                                    child: _revenueChip(
                                        'Card',
                                        '$cardPayments')),
                                Expanded(
                                    child: _revenueChip(
                                        'Cash',
                                        '$cashPayments')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Booking history
                      _sectionTitle('Booking History'),
                      const SizedBox(height: 14),
                      ...docs.map((doc) {
                        final data = doc.data()
                        as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(
                              bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.04),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text(
                                      data['bookingId'] ??
                                          '',
                                      style: TextStyle(
                                          color: Colors
                                              .grey.shade400,
                                          fontSize: 11)),
                                  Text(
                                    'LKR ${(data['totalAmount'] as num).toStringAsFixed(0)}',
                                    style: TextStyle(
                                        color: Colors
                                            .blue.shade600,
                                        fontWeight:
                                        FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(data['roomName'] ?? '',
                                  style: const TextStyle(
                                      fontWeight:
                                      FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(data['checkIn'] as Timestamp)} → ${_formatDate(data['checkOut'] as Timestamp)}',
                                style: TextStyle(
                                    color:
                                    Colors.grey.shade500,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    data['paymentMethod'] ==
                                        'card'
                                        ? Icons.credit_card
                                        : Icons
                                        .payments_outlined,
                                    size: 13,
                                    color:
                                    Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['paymentMethod'] ==
                                        'card'
                                        ? 'Card payment'
                                        : 'Cash on arrival',
                                    style: TextStyle(
                                        color: Colors
                                            .grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Sign out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const LoginScreen()),
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout,
                      color: Colors.redAccent),
                  label: const Text('Sign Out',
                      style: TextStyle(
                          color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    side: const BorderSide(
                        color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87));
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.8));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: enabled
            ? Colors.grey.shade100
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSwitchTile(
      String label,
      IconData icon,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, color: Colors.black87)),
        secondary:
        Icon(icon, color: Colors.blue.shade400, size: 22),
        value: value,
        activeThumbColor: Colors.blue.shade600,
        activeTrackColor: Colors.blue.shade200,
        onChanged: _isEditing ? onChanged : null,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 2),
      ),
    );
  }

  Widget _revenueChip(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}