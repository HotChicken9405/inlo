import 'package:flutter/material.dart';
import 'payment_screen.dart';

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
  State<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState
    extends State<BookingSummaryScreen> {
  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  double get _totalAmount =>
      (widget.room['price'] as num).toDouble() * widget.nights;

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
          icon: const Icon(Icons.arrow_back,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Booking summary',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold)),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${widget.propertyData['city']}, Sri Lanka',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13),
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
                  _detailRow(
                      'Check-In', _formatDate(widget.checkIn)),
                  _detailRow('Check-out',
                      _formatDate(widget.checkOut)),
                  _detailRow('Duration',
                      '${widget.nights} night${widget.nights != 1 ? 's' : ''}'),
                  _detailRow('Guests',
                      '${widget.guests} adult${widget.guests != 1 ? 's' : ''}'),
                  _detailRow('Per night',
                      'LKR ${(widget.room['price'] as num).toStringAsFixed(0)}'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
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
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        propertyId: widget.propertyId,
                        propertyData: widget.propertyData,
                        room: widget.room,
                        checkIn: widget.checkIn,
                        checkOut: widget.checkOut,
                        guests: widget.guests,
                        nights: widget.nights,
                        totalAmount: _totalAmount,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Proceed to Payment',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
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
}