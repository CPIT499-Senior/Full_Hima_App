import 'package:flutter/material.dart';
import 'package:hima_app/screens/HimaMapPicker.dart';

class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/login_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  'Image not found!',
                  style: TextStyle(color: Colors.red, fontSize: 20),
                ),
              );
            },
          ),

          // Main layout
          Column(
            children: [
              // Top White Banner with Profile
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
                          username,
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Welcome',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Buttons in center
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMissionButton(
                        text: 'Start New Mission',
                        onTap: () => Navigator.pushNamed(context, '/new_mission'),
                      ),
                      const SizedBox(height: 30),
                      _buildMissionButton(
                        text: 'Previous Missions',
                        onTap: () => Navigator.pushNamed(context, '/previous_missions',arguments: username),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown.shade800, // Match design
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        shadowColor: Colors.black54,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 30,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: Colors.white,
        ),
      ),
    );
  }
}
