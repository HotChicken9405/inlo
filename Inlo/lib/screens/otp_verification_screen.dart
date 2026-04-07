import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_confirmed_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String otp;
  final String email;
  final String propertyId;
  final Map<String, dynamic> propertyData;
  final Map<String, dynamic> room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int nights;
  final double totalAmount;
  final String paymentMethod;

  const OtpVerificationScreen({
    super.key,
    required this.otp,
    required this.email,
    required this.propertyId,
    required this.propertyData,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.nights,
    required this.totalAmount,
    required this.paymentMethod,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _hasError = false;

  String get _enteredOtp =>
      _controllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _hasError = false);
  }

  Future<void> _notifyHost(String bookingId) async {
    try {
      // Get host email
      final hostDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.propertyData['hostId'])
          .get();
      final hostEmail = hostDoc.data()?['email'] ?? '';
      final hostName = hostDoc.data()?['name'] ?? 'Host';

      if (hostEmail.isEmpty) return;

      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': 'service_5zr6udv',
          'template_id': 'template_g7wvulb',
          'user_id': 'rfgvvlUuiI-wgNGr6',
          'template_params': {
            'to_email': hostEmail,
            'to_name': hostName,
            'otp_code': 'NEW BOOKING',
            'property_name':
            widget.propertyData['propertyName'] ?? '',
            'total_amount':
            'Booking ID: $bookingId\nRoom: ${widget.room['name']}\nCheck-in: ${widget.checkIn.day}/${widget.checkIn.month}/${widget.checkIn.year}\nCheck-out: ${widget.checkOut.day}/${widget.checkOut.month}/${widget.checkOut.year}\nGuests: ${widget.guests}\nTotal: LKR ${widget.totalAmount.toStringAsFixed(0)}',
          },
        }),
      );
    } catch (e) {
      // Silently fail — don't block booking if email fails
      print('Host notification failed: $e');
    }
  }

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length < 6) {
      setState(() => _hasError = true);
      return;
    }

    if (_enteredOtp != widget.otp) {
      setState(() => _hasError = true);
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final bookingId =
          'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

      await FirebaseFirestore.instance
          .collection('bookings')
          .add({
        'bookingId': bookingId,
        'customerId': uid,
        'propertyId': widget.propertyId,
        'propertyName': widget.propertyData['propertyName'],
        'hostId': widget.propertyData['hostId'],
        'roomName': widget.room['name'],
        'roomType': widget.room['bedType'],
        'checkIn': Timestamp.fromDate(widget.checkIn),
        'checkOut': Timestamp.fromDate(widget.checkOut),
        'nights': widget.nights,
        'guests': widget.guests,
        'pricePerNight': widget.room['price'],
        'totalAmount': widget.totalAmount,
        'paymentMethod': widget.paymentMethod,
        'status': 'confirmed',
        'city': widget.propertyData['city'],
        'createdAt': Timestamp.now(),
      });

      // Update booked dates
      final propertyRef = FirebaseFirestore.instance
          .collection('properties')
          .doc(widget.propertyId);

      final propertySnap = await propertyRef.get();
      final roomTypes = List<Map<String, dynamic>>.from(
          propertySnap.data()?['roomTypes'] ?? []);

      for (int i = 0; i < roomTypes.length; i++) {
        if (roomTypes[i]['name'] == widget.room['name']) {
          final bookedDates =
          List<Map<String, dynamic>>.from(
              roomTypes[i]['bookedDates'] ?? []);
          bookedDates.add({
            'from': Timestamp.fromDate(widget.checkIn),
            'to': Timestamp.fromDate(widget.checkOut),
            'bookingId': bookingId,
          });
          roomTypes[i]['bookedDates'] = bookedDates;
          break;
        }
      }

      await propertyRef.update({'roomTypes': roomTypes});

      // Send email to host
      await _notifyHost(bookingId);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmedScreen(
            bookingId: bookingId,
            propertyName: widget.propertyData['propertyName'],
            roomName: widget.room['name'],
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            totalAmount: widget.totalAmount,
            city: widget.propertyData['city'],
          ),
        ),
            (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_unread_outlined,
                  color: Colors.blue.shade600, size: 30),
            ),
            const SizedBox(height: 24),
            const Text('Verify your email',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    height: 1.5),
                children: [
                  const TextSpan(text: 'We sent a 6-digit OTP to\n'),
                  TextSpan(
                    text: widget.email,
                    style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onChanged: (v) => _onOtpChanged(index, v),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                      _hasError ? Colors.red : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _hasError
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _hasError
                              ? Colors.red
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _hasError
                              ? Colors.red.shade300
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _hasError
                              ? Colors.red
                              : Colors.blue.shade400,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            if (_hasError) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 6),
                  Text('Incorrect OTP. Please try again.',
                      style: TextStyle(
                          color: Colors.red.shade400, fontSize: 13)),
                ],
              ),
            ],

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verify & Confirm',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Change email or payment method',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}