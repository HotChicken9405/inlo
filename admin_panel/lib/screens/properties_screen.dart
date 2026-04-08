import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() =>
      _PropertiesScreenState();
}

class _PropertiesScreenState
    extends State<PropertiesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Properties',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('All listed properties in real-time',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13)),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 260,
              child: TextField(
                onChanged: (v) => setState(
                        () => _search = v.toLowerCase()),
                style:
                const TextStyle(color: Colors.white),
                decoration: _searchDeco(
                    'Search properties...'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('properties')
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
                  final name =
                  (data['propertyName'] ?? '')
                      .toLowerCase();
                  final city = (data['city'] ?? '')
                      .toLowerCase();
                  final host = (data['hostName'] ?? '')
                      .toLowerCase();
                  return name.contains(_search) ||
                      city.contains(_search) ||
                      host.contains(_search);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Text('No properties found',
                        style: TextStyle(
                            color: Colors.white
                                .withOpacity(0.3))),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data()
                  as Map<String, dynamic>;
                  final photos = List<String>.from(
                      d['photos'] ?? []);
                  final roomTypes = List<dynamic>.from(
                      d['roomTypes'] ?? []);
                  final amenities =
                  Map<String, dynamic>.from(
                      d['amenities'] ?? {});

                  List<String> amenityList = [];
                  if (amenities['wifi'] == true)
                    amenityList.add('WiFi');
                  if (amenities['pool'] == true)
                    amenityList.add('Pool');
                  if (amenities['ac'] == true)
                    amenityList.add('AC');
                  if (amenities['parking'] == true)
                    amenityList.add('Parking');

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                          const BorderRadius.vertical(
                              top:
                              Radius.circular(14)),
                          child: photos.isNotEmpty
                              ? Image.network(
                            photos[0],
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __,
                                ___) =>
                                _placeholder(),
                          )
                              : _placeholder(),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                            const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['propertyName'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.bold,
                                      fontSize: 13),
                                  overflow: TextOverflow
                                      .ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${d['city'] ?? ''} · ${d['propertyType'] ?? ''}',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.4),
                                      fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Host: ${d['hostName'] ?? '—'}',
                                  style: TextStyle(
                                      color: const Color(
                                          0xFFFFB703)
                                          .withOpacity(0.8),
                                      fontSize: 11),
                                ),
                                if (amenityList
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    children: amenityList
                                        .take(3)
                                        .map((a) =>
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal:
                                              6,
                                              vertical:
                                              2),
                                          decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(
                                                  0.05),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  4)),
                                          child: Text(
                                              a,
                                              style: TextStyle(
                                                  color: Colors.white.withOpacity(
                                                      0.5),
                                                  fontSize:
                                                  10)),
                                        ))
                                        .toList(),
                                  ),
                                ],
                                const Spacer(),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      '${roomTypes.length} room type(s)',
                                      style: TextStyle(
                                          color: Colors
                                              .white
                                              .withOpacity(
                                              0.4),
                                          fontSize: 11),
                                    ),
                                    Text(
                                      'LKR ${d['pricePerNight'] ?? 0}',
                                      style: const TextStyle(
                                          color: Color(
                                              0xFF4F8EF7),
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 130,
    color: Colors.white.withOpacity(0.05),
    child: Icon(Icons.image_outlined,
        color: Colors.white.withOpacity(0.2),
        size: 32),
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
}