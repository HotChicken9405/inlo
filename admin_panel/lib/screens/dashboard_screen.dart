import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'users_screen.dart';
import 'properties_screen.dart';
import 'bookings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // --- MODERN SLATE & INDIGO PALETTE ---
  static const Color _sidebarBg = Color(0xFF1E293B);
  static const Color _mainBg = Color(0xFFF8FAFC);
  static const Color _accentIndigo = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mainBg,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 260,
            color: _sidebarBg,
            child: Column(
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentIndigo,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Inlo Admin',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _navItem(0, Icons.grid_view_rounded, 'Overview'),
                _navItem(1, Icons.group_rounded, 'Users'),
                _navItem(2, Icons.maps_home_work_rounded, 'Properties'),
                _navItem(3, Icons.calendar_today_rounded, 'Bookings'),
                const Spacer(),
                _signOutButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // MAIN CONTENT
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

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _accentIndigo : Colors.white60, size: 20),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _signOutButton() {
    return InkWell(
      onTap: () async => await FirebaseAuth.instance.signOut(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
            SizedBox(width: 12),
            Text('Logout', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// --- DASHBOARD HOME VIEW ---

class _DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 32),
          _statsRow(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _ChartCard(title: "Booking Revenue Trend", child: _lineChart())),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _ChartCard(title: "User Distribution", child: _pieChart())),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SectionCard(title: "Recent Bookings", child: _recentBookings())),
              const SizedBox(width: 24),
              Expanded(child: _SectionCard(title: "Recent Users", child: _recentUsers())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back, Admin', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        Text('System Overview',
            style: TextStyle(
                color: Color(0xFF1E293B), fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
      ],
    );
  }

  // --- LIVE FIRESTORE DATA COMPONENTS ---

  Widget _statsRow() {
    return Row(
      children: [
        _StatCard(
          label: 'Total Users',
          icon: Icons.people,
          color: const Color(0xFF6366F1),
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
        ),
        const SizedBox(width: 20),
        _StatCard(
          label: 'Hosts',
          icon: Icons.person_pin_circle,
          color: const Color(0xFF10B981),
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'host').snapshots(),
        ),
        const SizedBox(width: 20),
        _StatCard(
          label: 'Properties',
          icon: Icons.maps_home_work,
          color: const Color(0xFFF59E0B),
          stream: FirebaseFirestore.instance.collection('properties').snapshots(),
        ),
        const SizedBox(width: 20),
        _StatCard(
          label: 'Bookings',
          icon: Icons.book_online,
          color: const Color(0xFFEC4899),
          stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        ),
      ],
    );
  }

  Widget _pieChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No users found"));

        int customers = docs.where((d) => (d.data() as Map)['role'] == 'customer').length;
        int hosts = docs.where((d) => (d.data() as Map)['role'] == 'host').length;
        int total = docs.length;

        return Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  sections: [
                    PieChartSectionData(
                      color: const Color(0xFF6366F1),
                      value: customers.toDouble(),
                      title: '${((customers / total) * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFF10B981),
                      value: hosts.toDouble(),
                      title: '${((hosts / total) * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _indicator(color: const Color(0xFF6366F1), text: "Customers"),
                const SizedBox(width: 16),
                _indicator(color: const Color(0xFF10B981), text: "Hosts"),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _indicator({required Color color, required String text}) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _lineChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: false).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));

        final docs = snapshot.data!.docs;
        List<FlSpot> spots = [];

        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          double amount = (data['totalAmount'] as num? ?? 0).toDouble();
          spots.add(FlSpot(i.toDouble(), amount / 1000));
        }

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.black12, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('B${value.toInt() + 1}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()}k', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                isCurved: true,
                color: const Color(0xFF6366F1),
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: const Color(0xFF6366F1).withOpacity(0.1)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _recentBookings() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF6366F1))));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No recent bookings", style: TextStyle(color: Color(0xFF94A3B8)))));

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.book_online, color: Color(0xFF6366F1), size: 20),
              ),
              title: Text(d['propertyName'] ?? 'Unknown Property', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              subtitle: Text(d['bookingId'] ?? 'No ID', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              trailing: Text('LKR ${(d['totalAmount'] as num?)?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _recentUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF10B981))));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No recent users", style: TextStyle(color: Color(0xFF94A3B8)))));

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final role = d['role'] ?? 'customer';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFF1F5F9),
                child: Icon(Icons.person, color: role == 'host' ? const Color(0xFFF59E0B) : const Color(0xFF10B981), size: 20),
              ),
              title: Text(d['name'] ?? 'Unknown User', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              subtitle: Text(d['email'] ?? 'No email', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              trailing: Text(role.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: role == 'host' ? const Color(0xFFF59E0B) : const Color(0xFF10B981))),
            );
          }).toList(),
        );
      },
    );
  }
}

// --- SUPPORTING UI WRAPPERS ---

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;

  const _StatCard({required this.label, required this.icon, required this.color, required this.stream});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final count = snap.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 20),
                Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}