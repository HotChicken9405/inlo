import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'users_screen.dart';
import 'properties_screen.dart';
import 'bookings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: const Color(0xFF1A1A2E),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F8EF7),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Inlo Admin',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(
                    color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  child: Text('NAVIGATION',
                      style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.3),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5)),
                ),
                const SizedBox(height: 8),
                _navItem(0, Icons.dashboard_outlined,
                    Icons.dashboard, 'Dashboard'),
                _navItem(1, Icons.people_outline,
                    Icons.people, 'Users'),
                _navItem(2, Icons.house_outlined,
                    Icons.house, 'Properties'),
                _navItem(3, Icons.book_outlined,
                    Icons.book, 'Bookings'),
                const Spacer(),
                const Divider(
                    color: Colors.white10, height: 1),
                GestureDetector(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(10),
                      border: Border.all(
                          color:
                          Colors.red.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout,
                            color: Colors.redAccent,
                            size: 18),
                        SizedBox(width: 12),
                        Text('Sign Out',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _selectedIndex == 0
                ? _DashboardHome()
                : _selectedIndex == 1
                ? const UsersScreen()
                : _selectedIndex == 2
                ? const PropertiesScreen()
                : const BookingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon,
      IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F8EF7).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
              color: const Color(0xFF4F8EF7)
                  .withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFF4F8EF7)
                  : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF4F8EF7)
                        : Colors.white54,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 32),
          _statsRow(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(child: _recentBookings()),
              const SizedBox(width: 24),
              Expanded(child: _recentUsers()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14)),
        const Text('Admin Dashboard',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _StatCard(
          label: 'Total Users',
          icon: Icons.people,
          color: const Color(0xFF4F8EF7),
          stream: FirebaseFirestore.instance
              .collection('users')
              .snapshots(),
        ),
        const SizedBox(width: 16),
        _StatCard(
          label: 'Customers',
          icon: Icons.person,
          color: const Color(0xFF06D6A0),
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'customer')
              .snapshots(),
        ),
        const SizedBox(width: 16),
        _StatCard(
          label: 'Hosts',
          icon: Icons.house,
          color: const Color(0xFFFFB703),
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'host')
              .snapshots(),
        ),
        const SizedBox(width: 16),
        _StatCard(
          label: 'Properties',
          icon: Icons.apartment,
          color: const Color(0xFFEF476F),
          stream: FirebaseFirestore.instance
              .collection('properties')
              .snapshots(),
        ),
        const SizedBox(width: 16),
        _StatCard(
          label: 'Bookings',
          icon: Icons.book_online,
          color: const Color(0xFF7B2FBE),
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .snapshots(),
        ),
      ],
    );
  }

  Widget _recentBookings() {
    return _SectionCard(
      title: 'Recent Bookings',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .limit(6)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF4F8EF7))),
            );
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return _empty('No bookings yet');
          }
          return Column(
            children: docs.map((doc) {
              final d =
              doc.data() as Map<String, dynamic>;
              return _ListTileRow(
                title: d['propertyName'] ?? '',
                subtitle: d['bookingId'] ?? '',
                trailing:
                'LKR ${(d['totalAmount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                trailingColor:
                const Color(0xFF4F8EF7),
                icon: Icons.book_online,
                iconColor: const Color(0xFF7B2FBE),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _recentUsers() {
    return _SectionCard(
      title: 'Recent Users',
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .limit(6)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF4F8EF7))),
            );
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return _empty('No users yet');
          }
          return Column(
            children: docs.map((doc) {
              final d =
              doc.data() as Map<String, dynamic>;
              final role = d['role'] ?? 'customer';
              return _ListTileRow(
                title: d['name'] ?? '',
                subtitle: d['email'] ?? '',
                trailing: role.toUpperCase(),
                trailingColor: role == 'host'
                    ? const Color(0xFFFFB703)
                    : const Color(0xFF06D6A0),
                icon: Icons.person,
                iconColor: role == 'host'
                    ? const Color(0xFFFFB703)
                    : const Color(0xFF06D6A0),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _empty(String msg) => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(
        child: Text(msg,
            style: TextStyle(
                color:
                Colors.white.withOpacity(0.3)))),
  );
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final count = snap.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child:
                  Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 16),
                Text('$count',
                    style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.5),
                        fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard(
      {required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                20, 20, 20, 12),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
          const Divider(
              color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ListTileRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final IconData icon;
  final Color iconColor;

  const _ListTileRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.4),
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(trailing,
              style: TextStyle(
                  color: trailingColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }
}