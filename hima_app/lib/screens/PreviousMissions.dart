import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'MissionDetails.dart';

class PreviousMissions extends StatefulWidget {
  final String username;
  const PreviousMissions({Key? key, required this.username}) : super(key: key);

  @override
  _PreviousMissionsState createState() => _PreviousMissionsState();
}

class _PreviousMissionsState extends State<PreviousMissions> {
  List<dynamic> _missions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchMissions();
  }

  Future<void> fetchMissions() async {
    final url = Uri.parse('http://10.0.2.2:5000/missions');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _missions = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        print('❌ Failed to fetch missions');
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/login_bg.png', fit: BoxFit.cover),
          Column(
            children: [
              Container(
                height: 130,
                color: Colors.white.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, size: 60, color: Colors.black),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Text(
                          'Welcome',
                          style: TextStyle(fontSize: 25, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Previous missions:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  itemCount: _missions.length,
                  itemBuilder: (context, index) {
                    final mission = _missions[index];
                    return _missionCard(mission, context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _missionCard(Map mission, BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mission['id']}', // fixed
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Detected landmines: ${mission['landmineCount'] ?? 0}'),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MissionDetails(missionName: mission['id']),
                  ),
                );
              },
              child: const Text('Show more', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
