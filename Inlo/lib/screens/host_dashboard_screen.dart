import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'host_bookings_screen.dart';
import 'host_property_screen.dart';
import 'host_profile_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() =>
      _HostDashboardScreenState();
}

class _HostDashboardScreenState
    extends State<HostDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HostHomeTab(),
    const HostBookingsScreen(),
    const HostPropertyScreen(),
    const HostProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.house_outlined),
              activeIcon: Icon(Icons.house),
              label: 'Property'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _HostHomeTab extends StatelessWidget {
  const _HostHomeTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snap) {
                final name = snap.hasData
                    ? (snap.data!.data()
                as Map<String, dynamic>)['name'] ??
                    'Host'
                    : 'Host';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13)),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Stats row
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('hostId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                final total = docs.length;
                final revenue = docs.fold<double>(
                    0,
                        (sum, d) =>
                    sum +
                        ((d.data() as Map<String,
                            dynamic>)['totalAmount']
                        as num? ??
                            0)
                            .toDouble());
                final active = docs
                    .where((d) =>
                (d.data() as Map<String,
                    dynamic>)['status'] ==
                    'confirmed')
                    .length;

                return Row(
                  children: [
                    Expanded(
                        child: _statCard('Total Bookings',
                            '$total', Icons.book_online,
                            Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _statCard('Active',
                            '$active', Icons.check_circle,
                            Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _statCard(
                            'Revenue',
                            'LKR ${revenue.toStringAsFixed(0)}',
                            Icons.payments,
                            Colors.orange)),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            const Text('Recent Bookings',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('hostId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .limit(5)
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
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
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data =
                    doc.data() as Map<String, dynamic>;
                    return _bookingCard(data);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value,
      IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade400, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color.shade700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: color.shade400,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.king_bed_outlined,
                color: Colors.blue.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['roomName'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(data['bookingId'] ?? '',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LKR ${(data['totalAmount'] as num).toStringAsFixed(0)}',
                style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Confirmed',
                    style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}