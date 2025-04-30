import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class HimaMapPicker extends StatefulWidget {
  @override
  _HimaMapPickerState createState() => _HimaMapPickerState();
}

class _HimaMapPickerState extends State<HimaMapPicker> {
  GoogleMapController? _mapController;
  List<LatLng> _regionCorners = [];
  LatLng? _startPoint;
  LatLng? _endPoint;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  TextEditingController _searchController = TextEditingController();
  bool _isSelectingRegion = false;

  void _onMapTap(LatLng latLng) {
    setState(() {
      if (_isSelectingRegion && _regionCorners.length < 2) {
        _regionCorners.add(latLng);
        _markers.add(Marker(
          markerId: MarkerId('corner${_regionCorners.length}'),
          position: latLng,
          infoWindow: InfoWindow(
            title: _regionCorners.length == 1 ? 'Top-Left' : 'Bottom-Right',
          ),
        ));

        if (_regionCorners.length == 2) {
          _drawRegion();
          _isSelectingRegion = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Region selected — now tap start and end points inside.")),
          );
        }
      } else if (_regionCorners.length == 2 && _isWithinSelectedRegion(latLng)) {
        if (_startPoint == null) {
          _startPoint = latLng;
          _markers.add(Marker(
            markerId: MarkerId('start'),
            position: latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Start'),
          ));
        } else if (_endPoint == null) {
          _endPoint = latLng;
          _markers.add(Marker(
            markerId: MarkerId('end'),
            position: latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'End'),
          ));

          _saveMission();
        }
      } else if (_regionCorners.length == 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🚫 Tap inside the selected region only')),
        );
      }
    });
  }

  void _drawRegion() {
    if (_regionCorners.length == 2) {
      LatLng topLeft = _regionCorners[0];
      LatLng bottomRight = _regionCorners[1];

      setState(() {
        _polygons.add(Polygon(
          polygonId: PolygonId('region'),
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
          points: [
            LatLng(topLeft.latitude, topLeft.longitude),
            LatLng(topLeft.latitude, bottomRight.longitude),
            LatLng(bottomRight.latitude, bottomRight.longitude),
            LatLng(bottomRight.latitude, topLeft.longitude),
          ],
        ));
      });
    }
  }

  bool _isWithinSelectedRegion(LatLng point) {
    if (_regionCorners.length < 2) return false;

    final lat1 = _regionCorners[0].latitude;
    final lat2 = _regionCorners[1].latitude;
    final lng1 = _regionCorners[0].longitude;
    final lng2 = _regionCorners[1].longitude;

    final minLat = lat1 < lat2 ? lat1 : lat2;
    final maxLat = lat1 > lat2 ? lat1 : lat2;
    final minLng = lng1 < lng2 ? lng1 : lng2;
    final maxLng = lng1 > lng2 ? lng1 : lng2;

    return point.latitude >= minLat &&
        point.latitude <= maxLat &&
        point.longitude >= minLng &&
        point.longitude <= maxLng;
  }

  Future<void> _saveMission() async {
    try {
      if (_regionCorners.length < 2 || _startPoint == null || _endPoint == null) return;

      final mission = {
        'region': {
          'top_left': [_regionCorners[0].latitude, _regionCorners[0].longitude],
          'bottom_right': [_regionCorners[1].latitude, _regionCorners[1].longitude],
        },
        'start': [_startPoint!.latitude, _startPoint!.longitude],
        'end': [_endPoint!.latitude, _endPoint!.longitude],
      };

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/mission.json');
      await file.writeAsString(jsonEncode(mission));

      await sendMissionToFlask(mission);
    } catch (e) {
      _hideLoadingDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to save mission')),
      );
    }
  }

  Future<void> sendMissionToFlask(Map<String, dynamic> missionJson) async {
    final url = Uri.parse('http://10.0.2.2:5000/run-mission');

    try {
      _showLoadingDialog(); // Show loading

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(missionJson),
      );

      _hideLoadingDialog(); // Hide after getting response

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final missionName = data['mission'] ?? 'unknown';

        Navigator.of(context).pushReplacementNamed(
          '/mission-details',
          arguments: {'missionName': missionName},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Flask error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      _hideLoadingDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error sending mission to Flask: $e')),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Processing mission..."),
          ],
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _resetMission() {
    setState(() {
      _regionCorners.clear();
      _startPoint = null;
      _endPoint = null;
      _markers.clear();
      _polygons.clear();
      _isSelectingRegion = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔄 Mission reset.')),
    );
  }

  Future<void> _searchAndNavigate(String placeName) async {
    try {
      List<Location> locations = await locationFromAddress(placeName);
      if (locations.isNotEmpty) {
        final target = LatLng(locations.first.latitude, locations.first.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Location permission denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Permission denied permanently. Please enable it in settings.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📡 Getting current location...')),
      );

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final current = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(current, 17));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to get location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HIMA Mission Picker'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _goToCurrentLocation();
              });
            },
            tooltip: 'Use My Location',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetMission,
            tooltip: 'Reset Mission',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: _searchAndNavigate,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isSelectingRegion = true;
                      _regionCorners.clear();
                      _startPoint = null;
                      _endPoint = null;
                      _polygons.clear();
                      _markers.clear();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("📍 Tap two corners on the map to define your region."),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Text('Select Area'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(21.558, 39.206),
                zoom: 15,
              ),
              onTap: _onMapTap,
              markers: _markers,
              polygons: _polygons,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
