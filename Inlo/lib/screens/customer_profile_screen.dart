import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends State<CustomerProfileScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isEditing = false;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _profilePhotoUrl = '';

  static const String _cloudName = 'dgxp8sv9h';
  static const String _uploadPreset = 'inlo_unsigned';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data() ?? {};
    setState(() {
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _profilePhotoUrl = data['profilePhoto'] ?? '';
    });
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
      ..files
          .add(await http.MultipartFile.fromPath('file', image.path));
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
        _emailController.text.trim().isEmpty) {
      _showSnack('Name and email cannot be empty');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profilePhoto': _profilePhotoUrl,
      });

      // Update email in Firebase Auth if changed
      final currentEmail =
          FirebaseAuth.instance.currentUser!.email;
      if (_emailController.text.trim() != currentEmail) {
        await FirebaseAuth.instance.currentUser!
            .verifyBeforeUpdateEmail(
            _emailController.text.trim());
        _showSnack(
            'Verification email sent. Please verify new email.');
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Profile',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold)),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () =>
                  setState(() => _isEditing = true),
              child: Text('Edit',
                  style:
                  TextStyle(color: Colors.blue.shade600)),
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
                    backgroundImage: _profilePhotoUrl.isNotEmpty
                        ? NetworkImage(_profilePhotoUrl)
                        : null,
                    child: _profilePhotoUrl.isEmpty
                        ? Icon(Icons.person,
                        size: 52,
                        color: Colors.blue.shade400)
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
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Fields
            _buildLabel('FULL NAME'),
            const SizedBox(height: 8),
            _buildField(
              controller: _nameController,
              hint: 'Full name',
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),

            _buildLabel('EMAIL ADDRESS'),
            const SizedBox(height: 8),
            _buildField(
              controller: _emailController,
              hint: 'Email',
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _buildLabel('PHONE NUMBER'),
            const SizedBox(height: 8),
            _buildField(
              controller: _phoneController,
              hint: 'Phone number',
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),

            if (_isEditing) ...[
              const SizedBox(height: 28),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                  ),
                  child: const Text('Save changes',
                      style:
                      TextStyle(fontSize: 16)),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Booking history
            const Text('Booking History',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('customerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 40,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No bookings yet',
                              style: TextStyle(
                                  color:
                                  Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data =
                    doc.data() as Map<String, dynamic>;
                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.05),
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
                                data['bookingId'] ?? '',
                                style: TextStyle(
                                    color:
                                    Colors.grey.shade400,
                                    fontSize: 11),
                              ),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                  Colors.green.shade50,
                                  borderRadius:
                                  BorderRadius.circular(
                                      6),
                                ),
                                child: Text('Confirmed',
                                    style: TextStyle(
                                        color: Colors
                                            .green.shade600,
                                        fontSize: 11,
                                        fontWeight:
                                        FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['propertyName'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['roomName'] ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 13,
                                  color:
                                  Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatDate(data['checkIn'] as Timestamp)} → ${_formatDate(data['checkOut'] as Timestamp)}',
                                style: TextStyle(
                                    color:
                                    Colors.grey.shade500,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 13,
                                      color: Colors
                                          .grey.shade400),
                                  const SizedBox(width: 6),
                                  Text(
                                      '${data['guests']} guest(s) · ${data['nights']} night(s)',
                                      style: TextStyle(
                                          color: Colors
                                              .grey.shade500,
                                          fontSize: 12)),
                                ],
                              ),
                              Text(
                                'LKR ${(data['totalAmount'] as num).toStringAsFixed(0)}',
                                style: TextStyle(
                                    color:
                                    Colors.blue.shade600,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
                        builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout,
                    color: Colors.redAccent),
                label: const Text('Sign Out',
                    style:
                    TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
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
    );
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
        fillColor:
        enabled ? Colors.grey.shade100 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }
}