import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Displays a list of nearby pharmacies based on the user's current location
class NearbyPharmacyPage extends StatefulWidget {
  const NearbyPharmacyPage({super.key});

  @override
  State<NearbyPharmacyPage> createState() => _NearbyPharmacyPageState();
}

class _NearbyPharmacyPageState extends State<NearbyPharmacyPage> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color cardColor = const Color(0xFFF6EFE6);

  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;

  // Google Places API Key
  final String googleApiKey = "AIzaSyCNPLcA-6TLDNRtHZPxrGIgFh7gr9fCYo0";

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();
  }

  // Fetches current location and retrieves nearby pharmacies from Google Places API
  Future<void> _fetchPharmacies() async {
    // Retrieves current device location
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enable GPS')));
      }
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Fetches pharmacy data from Google Places API
    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=5000&type=pharmacy&key=$googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];

        List<Map<String, dynamic>> tempPharmacies = [];

        for (var place in results) {
          // Calculates distance from user to pharmacy
          double pLat = place['geometry']['location']['lat'];
          double pLng = place['geometry']['location']['lng'];
          double distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            pLat,
            pLng,
          );
          double distanceInKm = distanceInMeters / 1000;

          // Extracts operational status
          bool? isOpen;
          if (place['opening_hours'] != null) {
            isOpen = place['opening_hours']['open_now'];
          }

          // Extracts photo reference if available
          String? photoRef;
          if (place['photos'] != null && place['photos'].isNotEmpty) {
            photoRef = place['photos'][0]['photo_reference'];
          }

          tempPharmacies.add({
            'name': place['name'],
            'distance': distanceInKm,
            'rating': (place['rating'] ?? 0.0).toDouble(),
            'is_open': isOpen,
            'photo_ref': photoRef,
          });
        }

        // Sorts pharmacies by distance (nearest first)
        tempPharmacies.sort((a, b) => a['distance'].compareTo(b['distance']));

        setState(() {
          _pharmacies = tempPharmacies;
          _isLoading = false;
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching pharmacies: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 15,
                left: 15,
                right: 20,
                bottom: 10,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: textColor.withOpacity(0.6),
                        size: 16,
                      ),
                      label: Text(
                        'My Stock',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'Nearby Pharmacy',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pharmacies.isEmpty
                  ? Center(
                      child: Text(
                        'No pharmacies found nearby.',
                        style: TextStyle(color: textColor.withOpacity(0.6)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _pharmacies.length,
                      itemBuilder: (context, index) {
                        var pharmacy = _pharmacies[index];

                        // Constructs Google Places Photo URL
                        String? photoRef = pharmacy['photo_ref'];
                        String imageUrl = photoRef != null
                            ? "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoRef&key=$googleApiKey"
                            : "";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: textColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      "${pharmacy['name']} - ${pharmacy['distance'].toStringAsFixed(1)} km",
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 100,
                                      height: 70,
                                      color: Colors.grey.shade300,
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  const Icon(
                                                    Icons.store,
                                                    color: Colors.white,
                                                    size: 30,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.store,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              color: textColor.withOpacity(0.6),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              "08:00 - 20:00 ",
                                              style: TextStyle(
                                                color: textColor.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              pharmacy['is_open'] == true
                                                  ? 'open'
                                                  : (pharmacy['is_open'] ==
                                                            false
                                                        ? 'closed'
                                                        : ''),
                                              style: TextStyle(
                                                color:
                                                    pharmacy['is_open'] == true
                                                    ? const Color(0xFF38CC00)
                                                    : Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star_border,
                                              color: textColor.withOpacity(0.6),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              "${pharmacy['rating'] > 0 ? pharmacy['rating'] : '-'}",
                                              style: TextStyle(
                                                color: textColor.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
