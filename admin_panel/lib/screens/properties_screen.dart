import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- MODERN SLATE & INDIGO PALETTE ---
const Color _bgColor      = Color(0xFFF8FAFC);
const Color _accentIndigo = Color(0xFF6366F1);
const Color _textMain     = Color(0xFF1E293B);
const Color _textMuted    = Color(0xFF64748B);

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Property Listings',
              style: TextStyle(color: _textMain, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 4),
          const Text('Overview of all properties currently listed on the platform',
              style: TextStyle(color: _textMuted, fontSize: 14)),
          const SizedBox(height: 32),

          // Search Bar
          Row(
            children: [
              const Spacer(),
              _searchField(),
            ],
          ),
          const SizedBox(height: 24),

          // Properties Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('properties').snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _accentIndigo));
                }

                var docs = snap.data?.docs ?? [];
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name = (data['propertyName'] ?? '').toString().toLowerCase();
                    final city = (data['city'] ?? '').toString().toLowerCase();
                    final host = (data['hostName'] ?? '').toString().toLowerCase();
                    return name.contains(_search) || city.contains(_search) || host.contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return _emptyState('No properties found. Try a different search term.');
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    return _PropertyCard(data: d);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
        hintText: 'Search properties, cities, or hosts...',
        hintStyle: TextStyle(color: _textMuted.withOpacity(0.5), fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: _textMuted, size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );

  Widget _emptyState(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.home_work_outlined, size: 48, color: _textMuted.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(msg, style: TextStyle(color: _textMuted.withOpacity(0.6), fontSize: 14)),
      ],
    ),
  );
}

class _PropertyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PropertyCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final photos = List<String>.from(data['photos'] ?? []);
    final amenities = Map<String, dynamic>.from(data['amenities'] ?? {});
    final roomTypes = List<dynamic>.from(data['roomTypes'] ?? []);

    List<String> amenityList = [];
    if (amenities['wifi'] == true) amenityList.add('WiFi');
    if (amenities['pool'] == true) amenityList.add('Pool');
    if (amenities['ac'] == true) amenityList.add('AC');
    if (amenities['parking'] == true) amenityList.add('Parking');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                photos.isNotEmpty
                    ? Image.network(photos[0], height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text(data['propertyType'] ?? 'Stay',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: _accentIndigo),
                      const SizedBox(width: 4),
                      Text(data['city'] ?? 'Unknown City',
                          style: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data['propertyName'] ?? 'Untitled Property',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _textMain, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Host: ${data['hostName'] ?? '—'}',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  if (amenityList.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: amenityList.take(3).map((a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(6)),
                        child: Text(a, style: const TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),

                  const Spacer(),
                  const Divider(color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${roomTypes.length} Room Types', style: const TextStyle(color: _textMuted, fontSize: 12)),
                      Text('LKR ${data['pricePerNight'] ?? 0}',
                          style: const TextStyle(color: _accentIndigo, fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 180,
    width: double.infinity,
    color: const Color(0xFFF1F5F9),
    child: const Icon(Icons.home_work_rounded, color: Color(0xFFCBD5E1), size: 48),
  );
}