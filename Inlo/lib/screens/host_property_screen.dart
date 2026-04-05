import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostPropertyScreen extends StatelessWidget {
  const HostPropertyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('properties')
            .where('hostId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 20, 20, 0),
                  child: const Text('My Property',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ),
              ),
              if (docs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.house_outlined,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No property registered',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final data = docs[i].data()
                      as Map<String, dynamic>;
                      final propertyId = docs[i].id;
                      final photos = List<String>.from(
                          data['photos'] ?? []);
                      final roomTypes =
                      List<Map<String, dynamic>>.from(
                          data['roomTypes'] ?? []);
                      final amenities =
                      Map<String, dynamic>.from(
                          data['amenities'] ?? {});

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                            20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // Photo
                            ClipRRect(
                              borderRadius:
                              BorderRadius.circular(14),
                              child: photos.isNotEmpty
                                  ? Image.network(
                                photos[0],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                height: 200,
                                color: Colors
                                    .grey.shade200,
                                child: Icon(
                                    Icons.image_outlined,
                                    color: Colors
                                        .grey.shade400,
                                    size: 40),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['propertyName'] ??
                                        '',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight:
                                        FontWeight.bold),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                            context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Edit coming soon!')),
                                        );
                                      },
                                      icon: Icon(
                                          Icons.edit_outlined,
                                          color: Colors
                                              .blue.shade400),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _confirmDelete(
                                            context,
                                            propertyId);
                                      },
                                      icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors
                                              .red.shade400),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '${data['address']}, ${data['city']}',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 16),

                            // Amenities
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (amenities['wifi'] == true)
                                  _chip('WiFi', Icons.wifi),
                                if (amenities['pool'] == true)
                                  _chip('Pool', Icons.pool),
                                if (amenities['ac'] == true)
                                  _chip('AC', Icons.ac_unit),
                                if (amenities['parking'] ==
                                    true)
                                  _chip('Parking',
                                      Icons.local_parking),
                                if (data['animalsAllowed'] ==
                                    true)
                                  _chip('Pets OK', Icons.pets),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Room types
                            if (roomTypes.isNotEmpty) ...[
                              const Text('Room Types',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold)),
                              const SizedBox(height: 12),
                              ...roomTypes.map((room) {
                                final bookedCount =
                                    (room['bookedDates']
                                    as List?)
                                        ?.length ??
                                        0;
                                return Container(
                                  margin: const EdgeInsets
                                      .only(bottom: 10),
                                  padding:
                                  const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                    Colors.grey.shade50,
                                    borderRadius:
                                    BorderRadius.circular(
                                        12),
                                    border: Border.all(
                                        color: Colors
                                            .grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(room['name'],
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight
                                                      .w600,
                                                  fontSize:
                                                  14)),
                                          const SizedBox(
                                              height: 4),
                                          Text(
                                            '${room['bedType']} · ${room['count']} room(s)',
                                            style: TextStyle(
                                                color: Colors
                                                    .grey
                                                    .shade500,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            '$bookedCount booking(s)',
                                            style: TextStyle(
                                                color: Colors
                                                    .orange
                                                    .shade600,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'LKR ${room['price']}',
                                        style: TextStyle(
                                            color: Colors
                                                .blue.shade600,
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 30),
                          ],
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String propertyId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete property?'),
        content: const Text(
            'This will permanently delete your property listing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('properties')
                  .doc(propertyId)
                  .delete();
            },
            child: Text('Delete',
                style:
                TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.blue.shade400),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600)),
        ],
      ),
    );
  }
}