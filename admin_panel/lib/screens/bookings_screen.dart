import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() =>
      _BookingsScreenState();
}

class _BookingsScreenState
    extends State<BookingsScreen> {
  String _search = '';

  String _fmt(Timestamp t) {
    final d = t.toDate();
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bookings',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('All bookings in real-time',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13)),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 300,
              child: TextField(
                onChanged: (v) => setState(
                        () => _search = v.toLowerCase()),
                style:
                const TextStyle(color: Colors.white),
                decoration: _searchDeco(
                    'Search by property or booking ID...'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4F8EF7)));
              }
              var docs = snap.data?.docs ?? [];
              if (_search.isNotEmpty) {
                docs = docs.where((d) {
                  final data =
                  d.data() as Map<String, dynamic>;
                  final prop =
                  (data['propertyName'] ?? '')
                      .toLowerCase();
                  final id = (data['bookingId'] ?? '')
                      .toLowerCase();
                  final room = (data['roomName'] ?? '')
                      .toLowerCase();
                  return prop.contains(_search) ||
                      id.contains(_search) ||
                      room.contains(_search);
                }).toList();
              }

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(14),
                  border:
                  Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _tableHeader(),
                    if (docs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                              'No bookings found',
                              style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.3))),
                        ),
                      )
                    else
                      ...docs.map((doc) {
                        final d = doc.data()
                        as Map<String, dynamic>;
                        final checkIn =
                        d['checkIn'] as Timestamp?;
                        final checkOut =
                        d['checkOut'] as Timestamp?;
                        final payment =
                            d['paymentMethod'] ?? 'cash';
                        final status =
                            d['status'] ?? 'confirmed';
                        return _BookingRow(
                          bookingId:
                          d['bookingId'] ?? '—',
                          propertyName:
                          d['propertyName'] ?? '—',
                          roomName:
                          d['roomName'] ?? '—',
                          checkIn: checkIn != null
                              ? _fmt(checkIn)
                              : '—',
                          checkOut: checkOut != null
                              ? _fmt(checkOut)
                              : '—',
                          guests: '${d['guests'] ?? 0}',
                          payment: payment == 'card'
                              ? 'Card'
                              : 'Cash',
                          total:
                          'LKR ${(d['totalAmount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          status: status,
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 20, vertical: 14),
    decoration: const BoxDecoration(
      border: Border(
          bottom:
          BorderSide(color: Colors.white10)),
    ),
    child: Row(
      children: [
        _th('BOOKING ID', flex: 3),
        _th('PROPERTY', flex: 3),
        _th('ROOM', flex: 2),
        _th('CHECK-IN', flex: 2),
        _th('CHECK-OUT', flex: 2),
        _th('GUESTS', flex: 1),
        _th('PAYMENT', flex: 2),
        _th('TOTAL', flex: 2),
        _th('STATUS', flex: 2),
      ],
    ),
  );

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label,
        style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8)),
  );

  InputDecoration _searchDeco(String hint) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 13),
        prefixIcon: Icon(Icons.search,
            color: Colors.white.withOpacity(0.3),
            size: 18),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFF4F8EF7)),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 12),
      );
}

class _BookingRow extends StatefulWidget {
  final String bookingId;
  final String propertyName;
  final String roomName;
  final String checkIn;
  final String checkOut;
  final String guests;
  final String payment;
  final String total;
  final String status;

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
  State<_BookingRow> createState() => _BookingRowState();
}

class _BookingRowState extends State<_BookingRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withOpacity(0.03)
              : Colors.transparent,
          border: const Border(
              bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(widget.bookingId,
                  style: const TextStyle(
                      color: Color(0xFF4F8EF7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 3,
              child: Text(widget.propertyName,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(widget.roomName,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(widget.checkIn,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Text(widget.checkOut,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12)),
            ),
            Expanded(
              flex: 1,
              child: Text(widget.guests,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    widget.payment == 'Card'
                        ? Icons.credit_card
                        : Icons.payments_outlined,
                    size: 13,
                    color: widget.payment == 'Card'
                        ? const Color(0xFF4F8EF7)
                        : const Color(0xFF06D6A0),
                  ),
                  const SizedBox(width: 4),
                  Text(widget.payment,
                      style: TextStyle(
                          color: widget.payment == 'Card'
                              ? const Color(0xFF4F8EF7)
                              : const Color(0xFF06D6A0),
                          fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(widget.total,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF06D6A0)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.status.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF06D6A0),
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}