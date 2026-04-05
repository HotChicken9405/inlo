import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_confirmed_screen.dart';

class BookingSummaryScreen extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;
  final Map<String, dynamic> room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int nights;

  const BookingSummaryScreen({
    super.key,
    required this.propertyId,
    required this.propertyData,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.nights,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  double get _totalAmount =>
      (widget.room['price'] as num).toDouble() * widget.nights;

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final bookingId =
          'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

      // Save booking to Firestore
      await FirebaseFirestore.instance.collection('bookings').add({
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
        'totalAmount': _totalAmount,
        'paymentMethod': _paymentMethod,
        'status': 'confirmed',
        'city': widget.propertyData['city'],
        'createdAt': Timestamp.now(),
      });

      // Update booked dates on the room in the property
      final propertyRef = FirebaseFirestore.instance
          .collection('properties')
          .doc(widget.propertyId);

      final propertySnap = await propertyRef.get();
      final roomTypes = List<Map<String, dynamic>>.from(
          propertySnap.data()?['roomTypes'] ?? []);

      for (int i = 0; i < roomTypes.length; i++) {
        if (roomTypes[i]['name'] == widget.room['name']) {
          final bookedDates = List<Map<String, dynamic>>.from(
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
            totalAmount: _totalAmount,
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
    final photos =
    List<String>.from(widget.propertyData['photos'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Booking summary',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: photos.isNotEmpty
                  ? Image.network(photos[0],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover)
                  : Container(
                height: 180,
                color: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 16),

            Text(widget.propertyData['propertyName'] ?? '',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${widget.propertyData['city']}, Sri Lanka',
              style:
              TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Booking details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _detailRow('Room type', widget.room['name']),
                  _detailRow('Check-In', _formatDate(widget.checkIn)),
                  _detailRow(
                      'Check-out', _formatDate(widget.checkOut)),
                  _detailRow('Duration',
                      '${widget.nights} night${widget.nights != 1 ? 's' : ''}'),
                  _detailRow('Guests',
                      '${widget.guests} adult${widget.guests != 1 ? 's' : ''}'),
                  _detailRow('Per night',
                      'LKR ${(widget.room['price'] as num).toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total amount',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                        'LKR ${_totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment method
            const Text('Payment method',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _paymentOption(
              value: 'cash',
              icon: Icons.payments_outlined,
              label: 'Cash on arrival',
              subtitle: 'Pay when you check in',
            ),
            const SizedBox(height: 10),
            _paymentOption(
              value: 'card',
              icon: Icons.credit_card_outlined,
              label: 'Pay by card',
              subtitle: 'Enter card details below',
            ),

            // Card fields (only shown if card selected)
            if (_paymentMethod == 'card') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Card number',
                        hintText: '1234 5678 9012 3456',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Expiry',
                              hintText: 'MM/YY',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              hintText: '•••',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade200),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Cardholder name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm booking',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String value,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
            isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? Colors.blue.shade600
                    : Colors.grey.shade500),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? Colors.blue.shade600
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}