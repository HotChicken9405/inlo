class MapsHelper {
  // Extracts lat,lng from any Google Maps URL format
  static Map<String, double>? extractCoordinates(String url) {
    try {
      // Format 1: @lat,lng,zoom  e.g. @6.9325497,79.835213,16z
      final atPattern = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)');
      final atMatch = atPattern.firstMatch(url);
      if (atMatch != null) {
        final lat = double.tryParse(atMatch.group(1)!);
        final lng = double.tryParse(atMatch.group(2)!);
        if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
        }
      }

      // Format 2: !3dlat!4dlng  e.g. !3d6.9325497!4d79.8447402
      final dPattern =
      RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)');
      final dMatch = dPattern.firstMatch(url);
      if (dMatch != null) {
        final lat = double.tryParse(dMatch.group(1)!);
        final lng = double.tryParse(dMatch.group(2)!);
        if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
        }
      }

      // Format 3: q=lat,lng
      final qPattern =
      RegExp(r'q=(-?\d+\.?\d*),(-?\d+\.?\d*)');
      final qMatch = qPattern.firstMatch(url);
      if (qMatch != null) {
        final lat = double.tryParse(qMatch.group(1)!);
        final lng = double.tryParse(qMatch.group(2)!);
        if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Builds a Google Maps URL to open the pin
  static String buildPinUrl(double lat, double lng,
      String label) {
    final encodedLabel = Uri.encodeComponent(label);
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$encodedLabel';
  }
}