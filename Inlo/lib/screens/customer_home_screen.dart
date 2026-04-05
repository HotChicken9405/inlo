import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'property_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = [
    'All', 'Budget', 'Luxury', 'Beach', 'Mountain', 'City', 'Villa', 'Resort'
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? '';
    return name.isNotEmpty ? name.split(' ').first : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getGreeting(),
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                      const Text('Find your stay',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade100,
                    child: Icon(Icons.person_outline,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search hotels, cities...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon:
                  Icon(Icons.search, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filters
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.black87
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.black87
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Properties list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'Search results'
                    : 'Popular hotels',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('properties')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.house_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No properties found',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['propertyName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final city =
                    (data['city'] ?? '').toString().toLowerCase();
                    final type = (data['propertyType'] ?? '')
                        .toString()
                        .toLowerCase();

                    final matchesSearch = _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        city.contains(_searchQuery) ||
                        type.contains(_searchQuery);

                    final matchesFilter = _selectedFilter == 'All' ||
                        type.contains(
                            _selectedFilter.toLowerCase()) ||
                        name.contains(
                            _selectedFilter.toLowerCase());

                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text('No results for "$_searchQuery"',
                          style:
                          TextStyle(color: Colors.grey.shade400)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                      docs[index].data() as Map<String, dynamic>;
                      final propertyId = docs[index].id;
                      return _PropertyCard(
                        propertyId: propertyId,
                        data: data,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final String propertyId;
  final Map<String, dynamic> data;

  const _PropertyCard({required this.propertyId, required this.data});

  @override
  Widget build(BuildContext context) {
    final photos = List<String>.from(data['photos'] ?? []);
    final roomTypes =
    List<Map<String, dynamic>>.from(data['roomTypes'] ?? []);
    double minPrice = 0;
    if (roomTypes.isNotEmpty) {
      minPrice = roomTypes
          .map((r) => (r['price'] as num).toDouble())
          .reduce((a, b) => a < b ? a : b);
    } else {
      minPrice = (data['pricePerNight'] ?? 0).toDouble();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(
              propertyId: propertyId,
              data: data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: photos.isNotEmpty
                      ? Image.network(
                    photos[0],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_outlined,
                          color: Colors.grey.shade400, size: 40),
                    ),
                  )
                      : Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_outlined,
                        color: Colors.grey.shade400, size: 40),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['city'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['propertyName'] ?? '',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data['city']}, Sri Lanka',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: Colors.amber.shade400, size: 14),
                            const SizedBox(width: 4),
                            Text('4.5',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'LKR ${minPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      Text('/night',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}