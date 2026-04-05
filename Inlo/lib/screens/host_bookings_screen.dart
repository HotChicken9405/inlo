import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostBookingsScreen extends StatelessWidget {
  const HostBookingsScreen({super.key});

  String _formatDate(Timestamp t) {
    final d = t.toDate();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('Bookings',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('hostId', isEqualTo: uid)
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
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No bookings yet',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data()
                    as Map<String, dynamic>;
                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(14),
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
                                    fontSize: 12),
                              ),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                  Colors.green.shade50,
                                  borderRadius:
                                  BorderRadius.circular(
                                      8),
                                ),
                                child: Text('Confirmed',
                                    style: TextStyle(
                                        color: Colors
                                            .green.shade600,
                                        fontWeight:
                                        FontWeight.w600,
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(data['roomName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          const SizedBox(height: 8),
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
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 13,
                                  color:
                                  Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(
                                  '${data['guests']} guest(s) · ${data['nights']} night(s)',
                                  style: TextStyle(
                                      color: Colors
                                          .grey.shade500,
                                      fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.payment,
                                  size: 13,
                                  color:
                                  Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Text(
                                  data['paymentMethod'] ==
                                      'cash'
                                      ? 'Cash on arrival'
                                      : 'Card payment',
                                  style: TextStyle(
                                      color: Colors
                                          .grey.shade500,
                                      fontSize: 13)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              Text('Total',
                                  style: TextStyle(
                                      color: Colors
                                          .grey.shade500,
                                      fontSize: 13)),
                              Text(
                                'LKR ${(data['totalAmount'] as num).toStringAsFixed(0)}',
                                style: TextStyle(
                                    color:
                                    Colors.blue.shade600,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}