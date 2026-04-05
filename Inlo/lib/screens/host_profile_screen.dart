import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class HostProfileScreen extends StatelessWidget {
  const HostProfileScreen({super.key});

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 20),

            // Host info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final data =
                snap.data!.data() as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10)
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person,
                            color: Colors.blue.shade600,
                            size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(data['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(data['email'] ?? '',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(data['phone'] ?? '',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Revenue & stats
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
                            dynamic>)['totalAmount']
                        as num? ??
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Revenue Overview',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
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
                                fontWeight: FontWeight.bold),
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
                                      'Card Payments',
                                      '$cardPayments')),
                              Expanded(
                                  child: _revenueChip(
                                      'Cash Payments',
                                      '$cashPayments')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Booking history
            const Text('Booking History',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('hostId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text('No bookings yet',
                        style: TextStyle(
                            color: Colors.grey.shade400)),
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
                              Text(data['bookingId'] ?? '',
                                  style: TextStyle(
                                      color: Colors
                                          .grey.shade400,
                                      fontSize: 11)),
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
                          const SizedBox(height: 8),
                          Text(data['roomName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(data['checkIn'] as Timestamp)} → ${_formatDate(data['checkOut'] as Timestamp)}',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                data['paymentMethod'] ==
                                    'card'
                                    ? Icons.credit_card
                                    : Icons.payments_outlined,
                                size: 13,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data['paymentMethod'] ==
                                    'card'
                                    ? 'Card payment'
                                    : 'Cash on arrival',
                                style: TextStyle(
                                    color:
                                    Colors.grey.shade500,
                                    fontSize: 12),
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
                  if (!context.mounted) return;
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
                    style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(
                      color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
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