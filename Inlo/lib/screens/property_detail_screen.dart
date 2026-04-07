import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'room_selection_screen.dart';
import '../utils/maps_helper.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> data;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    required this.data,
  });

  @override
  State<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState
    extends State<PropertyDetailScreen> {
  int _currentPhoto = 0;
  bool _isSaved = false;
  WebViewController? _mapController;

  @override
  void initState() {
    super.initState();
    _initMapController();
  }

  void _initMapController() {
    final embedUrl = widget.data['mapEmbedUrl'] as String?;
    final lat = (widget.data['latitude'] as num?)?.toDouble();
    final lng = (widget.data['longitude'] as num?)?.toDouble();

    String? iframeSrc;

    if (embedUrl != null && embedUrl.isNotEmpty) {
      // Use the stored embed URL directly
      iframeSrc = embedUrl;
    } else if (lat != null && lng != null && !(lat == 0.0 && lng == 0.0)) {
      // Fallback: build a basic embed from coordinates
      iframeSrc =
      'https://maps.google.com/maps?q=$lat,$lng&output=embed';
    }

    if (iframeSrc == null) return;

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: none; display: block; }
  </style>
</head>
<body>
  <iframe
    src="$iframeSrc"
    allowfullscreen=""
    loading="lazy"
    referrerpolicy="no-referrer-when-downgrade">
  </iframe>
</body>
</html>
''';

    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(html);
  }

  Widget _buildMapView() {
    final hasEmbed = (widget.data['mapEmbedUrl'] as String?)?.isNotEmpty == true;
    final lat = (widget.data['latitude'] as num?)?.toDouble();
    final lng = (widget.data['longitude'] as num?)?.toDouble();
    final hasCoords =
        lat != null && lng != null && !(lat == 0.0 && lng == 0.0);

    if (_mapController == null && !hasEmbed && !hasCoords) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No location available',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            if (_mapController != null)
              WebViewWidget(controller: _mapController!)
            else
              Container(color: Colors.grey.shade100),

            // "Open in Maps" overlay button (bottom-right)
            if (hasCoords || hasEmbed)
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () async {
                    final url = hasCoords
                        ? MapsHelper.buildPinUrl(
                      lat!,
                      lng!,
                      widget.data['propertyName'] ?? 'Property',
                    )
                        : _extractMapsLink(
                        widget.data['mapEmbedUrl'] ?? '');
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new,
                            size: 14, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Open Maps',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Converts an embed src URL back into a shareable Google Maps link
  String _extractMapsLink(String embedSrc) {
    // Try to pull out a place_id or query from the embed URL
    final pbMatch = RegExp(r'q=([^&]+)').firstMatch(embedSrc);
    if (pbMatch != null) {
      return 'https://www.google.com/maps/search/?api=1&query=${pbMatch.group(1)}';
    }
    return 'https://maps.google.com';
  }

  @override
  Widget build(BuildContext context) {
    final photos = List<String>.from(widget.data['photos'] ?? []);
    final amenities =
    Map<String, dynamic>.from(widget.data['amenities'] ?? {});
    final animalsAllowed = widget.data['animalsAllowed'] ?? false;

    List<String> amenityChips = [];
    if (amenities['wifi'] == true) amenityChips.add('WiFi');
    if (amenities['pool'] == true) amenityChips.add('Pool');
    if (amenities['ac'] == true) amenityChips.add('AC');
    if (amenities['parking'] == true) amenityChips.add('Parking');
    if (animalsAllowed) amenityChips.add('Pets OK');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Photo header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.white,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.black87),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isSaved = !_isSaved),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: Text(
                        _isSaved ? 'Saved' : 'Save',
                        style: TextStyle(
                          color: _isSaved
                              ? Colors.blue.shade600
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: photos.isNotEmpty
                      ? PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (i) =>
                        setState(() => _currentPhoto = i),
                    itemBuilder: (_, i) => Image.network(
                      photos[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey.shade200),
                    ),
                  )
                      : Container(color: Colors.grey.shade200),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo dots
                      if (photos.length > 1)
                        Row(
                          children: List.generate(
                            photos.length,
                                (i) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              width: _currentPhoto == i ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentPhoto == i
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade300,
                                borderRadius:
                                BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      if (photos.length > 1)
                        const SizedBox(height: 16),

                      Text(
                        widget.data['propertyName'] ?? '',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.data['address']}, ${widget.data['city']}',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // Amenity chips
                      if (amenityChips.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: amenityChips
                              .map((a) => Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(a,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w500)),
                          ))
                              .toList(),
                        ),
                      const SizedBox(height: 20),

                      // Description
                      const Text('About',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text(
                        widget.data['description'] ?? '',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.5,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 20),

                      // Host
                      const Text('Hosted by',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(Icons.person,
                                color: Colors.blue.shade400),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.data['hostName'] ?? 'Host',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Location
                      const Text('Location',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 10),
                      _buildMapView(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
              const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomSelectionScreen(
                        propertyId: widget.propertyId,
                        data: widget.data,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Check availability',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}