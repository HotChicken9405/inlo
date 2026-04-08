import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _filter = 'all';
  String _search = '';

  String _fmt(DateTime d) {
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
          const Text('Users',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('All registered users in real-time',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              _chip('All', 'all'),
              const SizedBox(width: 10),
              _chip('Customers', 'customer'),
              const SizedBox(width: 10),
              _chip('Hosts', 'host'),
              const Spacer(),
              _searchField(),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _filter == 'all'
                ? FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots()
                : FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: _filter)
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
                  final name = (data['name'] ?? '')
                      .toLowerCase();
                  final email = (data['email'] ?? '')
                      .toLowerCase();
                  return name.contains(_search) ||
                      email.contains(_search);
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
                      _emptyState('No users found')
                    else
                      ...docs.map((doc) {
                        final d = doc.data()
                        as Map<String, dynamic>;
                        final role =
                            d['role'] ?? 'customer';
                        final createdAt =
                        d['createdAt'] as Timestamp?;
                        return _UserRow(
                          name: d['name'] ?? '—',
                          email: d['email'] ?? '—',
                          phone: d['phone'] ?? '—',
                          role: role,
                          joined: createdAt != null
                              ? _fmt(createdAt.toDate())
                              : '—',
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

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          _th('NAME', flex: 3),
          _th('EMAIL', flex: 4),
          _th('PHONE', flex: 2),
          _th('ROLE', flex: 2),
          _th('JOINED', flex: 2),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(
        child: Text(msg,
            style: TextStyle(
                color:
                Colors.white.withOpacity(0.3)))),
  );

  Widget _chip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F8EF7)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F8EF7)
                  : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal)),
      ),
    );
  }

  Widget _searchField() => SizedBox(
    width: 260,
    child: TextField(
      onChanged: (v) =>
          setState(() => _search = v.toLowerCase()),
      style: const TextStyle(color: Colors.white),
      decoration: _searchDeco(
          'Search by name or email...'),
    ),
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

  Widget _th(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label,
        style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8)),
  );
}

class _UserRow extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String joined;

  const _UserRow({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.joined,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                    widget.role == 'host'
                        ? const Color(0xFFFFB703)
                        .withOpacity(0.2)
                        : const Color(0xFF4F8EF7)
                        .withOpacity(0.2),
                    child: Text(
                      widget.name.isNotEmpty
                          ? widget.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: widget.role == 'host'
                              ? const Color(0xFFFFB703)
                              : const Color(0xFF4F8EF7),
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(widget.email,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(widget.phone,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13)),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.role == 'host'
                      ? const Color(0xFFFFB703)
                      .withOpacity(0.12)
                      : const Color(0xFF06D6A0)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.role.toUpperCase(),
                  style: TextStyle(
                      color: widget.role == 'host'
                          ? const Color(0xFFFFB703)
                          : const Color(0xFF06D6A0),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(widget.joined,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}