import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- MODERN SLATE & INDIGO PALETTE ---
const Color _bgColor      = Color(0xFFF8FAFC);
const Color _accentIndigo = Color(0xFF6366F1);
const Color _textMain     = Color(0xFF1E293B);
const Color _textMuted    = Color(0xFF64748B);

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _search = '';

  String _fmt(Timestamp t) {
    final d = t.toDate();
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Management',
              style: TextStyle(color: _textMain, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 4),
          const Text('Track and manage all reservations across properties',
              style: TextStyle(color: _textMuted, fontSize: 14)),
          const SizedBox(height: 32),

          // Search Bar Row
          Row(
            children: [
              const Spacer(),
              _searchField(),
            ],
          ),
          const SizedBox(height: 24),

          // Bookings Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _accentIndigo));
                    }

                    var docs = snap.data?.docs ?? [];
                    if (_search.isNotEmpty) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final prop = (data['propertyName'] ?? '').toString().toLowerCase();
                        final id = (data['bookingId'] ?? '').toString().toLowerCase();
                        final room = (data['roomName'] ?? '').toString().toLowerCase();
                        return prop.contains(_search) || id.contains(_search) || room.contains(_search);
                      }).toList();
                    }

                    return Column(
                      children: [
                        _tableHeader(),
                        Expanded(
                          child: docs.isEmpty
                              ? _emptyState('No bookings found matching your search.')
                              : ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final d = docs[index].data() as Map<String, dynamic>;
                              final checkIn = d['checkIn'] as Timestamp?;
                              final checkOut = d['checkOut'] as Timestamp?;
                              return _BookingRow(
                                bookingId: d['bookingId'] ?? '—',
                                propertyName: d['propertyName'] ?? '—',
                                roomName: d['roomName'] ?? '—',
                                checkIn: checkIn != null ? _fmt(checkIn) : '—',
                                checkOut: checkOut != null ? _fmt(checkOut) : '—',
                                guests: '${d['guests'] ?? 0}',
                                payment: (d['paymentMethod'] ?? 'cash') == 'card' ? 'Card' : 'Cash',
                                total: 'LKR ${(d['totalAmount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                status: d['status'] ?? 'confirmed',
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _th('BOOKING ID', flex: 2),
          _th('PROPERTY & ROOM', flex: 3),
          _th('CHECK IN/OUT', flex: 3),
          _th('TOTAL', flex: 2),
          _th('STATUS', flex: 2),
        ],
      ),
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label, style: const TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
  );

  Widget _emptyState(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today_outlined, size: 48, color: _textMuted.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(msg, style: TextStyle(color: _textMuted.withOpacity(0.6), fontSize: 14)),
      ],
    ),
  );

  Widget _searchField() => Container(
    width: 320,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: TextField(
      onChanged: (v) => setState(() => _search = v.toLowerCase()),
      style: const TextStyle(color: _textMain, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search property or ID...',
        hintStyle: TextStyle(color: _textMuted.withOpacity(0.5), fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: _textMuted, size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}

class _BookingRow extends StatelessWidget {
  final String bookingId, propertyName, roomName, checkIn, checkOut, guests, payment, total, status;

  const _BookingRow({
    required this.bookingId,
    required this.propertyName,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.payment,
    required this.total,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          // Booking ID
          Expanded(
            flex: 2,
            child: Text(bookingId, style: const TextStyle(color: _accentIndigo, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          // Property & Room
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(propertyName, style: const TextStyle(color: _textMain, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(roomName, style: const TextStyle(color: _textMuted, fontSize: 12)),
              ],
            ),
          ),
          // Dates
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In: $checkIn', style: const TextStyle(color: _textMain, fontSize: 13)),
                    Text('Out: $checkOut', style: const TextStyle(color: _textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                  child: Text('$guests Guests', style: const TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Amount & Payment
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(total, style: const TextStyle(color: _textMain, fontWeight: FontWeight.w800, fontSize: 14)),
                Text(payment.toUpperCase(), style: TextStyle(color: payment == 'Card' ? Colors.blue : Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'confirmed' ? const Color(0xFF10B981).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(
                          color: status.toLowerCase() == 'confirmed' ? const Color(0xFF059669) : Colors.orange[800],
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}