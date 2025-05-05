import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SafePathMapViewer extends StatefulWidget {
  final String missionName;
  const SafePathMapViewer({Key? key, required this.missionName})
      : super(key: key);

  @override
  State<SafePathMapViewer> createState() => _SafePathMapViewerState();
}

class _SafePathMapViewerState extends State<SafePathMapViewer> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {}; // Stores map markers (landmines, start, end)
  Set<Polyline> _polylines = {}; // Stores the safe path line
  bool _loading = true; // Tracks loading state

  @override
  void initState() {
    super.initState();
    _loadMissionData(); // Load mission data when the screen initializes
  }

  // Fetches mission result JSON from the Flask backend and updates the map
  Future<void> _loadMissionData() async {
    final url = Uri.parse(
        'http://10.0.2.2:5000/missions/${widget.missionName}/result.json');
    print('🛰️ Trying to load result for mission: ${widget.missionName}');

    try {
      final response = await http.get(url);
      print('📤 Flask response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> path = data['safePath'] ?? [];
        List<dynamic> landmines = data['detectedLandmines'] ?? [];

        List<LatLng> pathPoints =
            path.map<LatLng>((p) => LatLng(p[0], p[1])).toList();

        setState(() {
          _loading = false;

          // Draw the safe path as a green polyline
          _polylines.add(Polyline(
            polylineId: PolylineId('safe_path'),
            points: pathPoints,
            color: Colors.green,
            width: 5,
          ));

          // Add red markers for each landmine
          for (int i = 0; i < landmines.length; i++) {
            final latLng = LatLng(landmines[i]['lat'], landmines[i]['lon']);
            _markers.add(Marker(
              markerId: MarkerId('landmine_$i'),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(title: '⚠️ Landmine'),
            ));
          }

          // Add blue marker for start and green marker for end of path
          if (pathPoints.isNotEmpty) {
            _markers.add(Marker(
              markerId: const MarkerId('start'),
              position: pathPoints.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'Start'),
            ));
            _markers.add(Marker(
              markerId: const MarkerId('end'),
              position: pathPoints.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: 'End'),
            ));

            // Calculate map bounds to fit the entire safe path
            final bounds = LatLngBounds(
              southwest: LatLng(
                pathPoints
                    .map((p) => p.latitude)
                    .reduce((a, b) => a < b ? a : b),
                pathPoints
                    .map((p) => p.longitude)
                    .reduce((a, b) => a < b ? a : b),
              ),
              northeast: LatLng(
                pathPoints
                    .map((p) => p.latitude)
                    .reduce((a, b) => a > b ? a : b),
                pathPoints
                    .map((p) => p.longitude)
                    .reduce((a, b) => a > b ? a : b),
              ),
            );

            // Animate the camera to fit the path within view
            _mapController
                ?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          }
        });
      } else {
        print('❌ Failed to load result data');
      }
    } catch (e) {
      print('❌ Error loading mission result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Path Viewer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(21.558, 39.206),
                zoom: 14,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              zoomControlsEnabled: true,
            ),
    );
  }
}
