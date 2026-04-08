import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- COLORS ACCESSIBLE TO ALL CLASSES IN THIS FILE ---
const Color _bgColor      = Color(0xFFF8FAFC);
const Color _accentIndigo = Color(0xFF6366F1);
const Color _textMain     = Color(0xFF1E293B);
const Color _textMuted    = Color(0xFF64748B);

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _filter = 'all';
  String _search = '';

  String _fmt(DateTime d) {
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
          const Text('User Management',
              style: TextStyle(color: _textMain, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 4),
          const Text('Manage and monitor all registered accounts',
              style: TextStyle(color: _textMuted, fontSize: 14)),
          const SizedBox(height: 32),

          Row(
            children: [
              _chip('All Users', 'all'),
              const SizedBox(width: 12),
              _chip('Customers', 'customer'),
              const SizedBox(width: 12),
              _chip('Hosts', 'host'),
              const Spacer(),
              _searchField(),
            ],
          ),
          const SizedBox(height: 24),

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
                  stream: _filter == 'all'
                      ? FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots()
                      : FirebaseFirestore.instance.collection('users')
                      .where('role', isEqualTo: _filter)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _emptyState('Query error. If this is a new filter, Firebase may still be building the index.');
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: _accentIndigo));
                    }

                    var docs = snap.data?.docs ?? [];
                    if (_search.isNotEmpty) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final email = (data['email'] ?? '').toString().toLowerCase();
                        return name.contains(_search) || email.contains(_search);
                      }).toList();
                    }

                    return Column(
                      children: [
                        _tableHeader(),
                        Expanded(
                          child: docs.isEmpty
                              ? _emptyState('No users found in this category')
                              : ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final d = docs[index].data() as Map<String, dynamic>;
                              final createdAt = d['createdAt'] as Timestamp?;
                              return _UserRow(
                                name: d['name'] ?? 'No Name',
                                email: d['email'] ?? 'No Email',
                                phone: d['phone'] ?? '—',
                                role: d['role'] ?? 'customer',
                                joined: createdAt != null ? _fmt(createdAt.toDate()) : '—',
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
          _th('NAME & CONTACT', flex: 4),
          _th('PHONE', flex: 2),
          _th('ROLE', flex: 2),
          _th('JOINED DATE', flex: 2),
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
        Icon(Icons.person_off_outlined, size: 48, color: _textMuted.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(msg, textAlign: TextAlign.center, style: TextStyle(color: _textMuted.withOpacity(0.6), fontSize: 14)),
      ],
    ),
  );

  Widget _chip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accentIndigo : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _accentIndigo : const Color(0xFFE2E8F0)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : _textMuted,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }

  Widget _searchField() => Container(
    width: 300,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: TextField(
      onChanged: (v) => setState(() => _search = v.toLowerCase()),
      style: const TextStyle(color: _textMain, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search by name or email...',
        hintStyle: TextStyle(color: _textMuted.withOpacity(0.5), fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: _textMuted, size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}

class _UserRow extends StatelessWidget {
  final String name, email, phone, role, joined;
  const _UserRow({required this.name, required this.email, required this.phone, required this.role, required this.joined});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _accentIndigo.withOpacity(0.1),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: _accentIndigo, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(phone, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'host' ? const Color(0xFFF59E0B).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(role.toUpperCase(),
                      style: TextStyle(
                          color: role == 'host' ? const Color(0xFFD97706) : const Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(joined, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13))),
        ],
      ),
    );
  }
}