import 'package:flutter/material.dart';
import 'customer_home_screen.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String bookingId;
  final String propertyName;
  final String roomName;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalAmount;
  final String city;

  const BookingConfirmedScreen({
    super.key,
    required this.bookingId,
    required this.propertyName,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.totalAmount,
    required this.city,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day}-${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check,
                    color: Colors.green.shade500, size: 40),
              ),
              const SizedBox(height: 24),

              const Text('Booking confirmed',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 10),
              Text(
                'Your room has been reserved. A confirmation has been sent to your email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    height: 1.5),
              ),
              const SizedBox(height: 24),

              // Booking ID
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('BOOKING ID',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Text(bookingId,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _summaryRow('Hotel', propertyName),
                    _summaryRow('Room', roomName),
                    _summaryRow('Dates',
                        '${_formatDate(checkIn)} – ${_formatDate(checkOut)}'),
                    _summaryRow(
                      'Total paid',
                      'LKR ${totalAmount.toStringAsFixed(0)}',
                      valueColor: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerHomeScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to home',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }
}