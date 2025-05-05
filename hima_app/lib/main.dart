import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/PreviousMissions.dart';
import 'screens/MissionDetails.dart';
import 'package:hima_app/screens/HimaMapPicker.dart';

void main() {
  runApp(const MyApp()); // Launch the main app widget
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner
      title: 'Hima App',
      initialRoute: '/', // Define the start (welcome) screen route
      routes: {
        // Welcome screen (first screen)
        '/': (context) => WelcomeScreen(),

        // Login screen
        '/login': (context) => LoginScreen(),

        // New mission screen (map picker)
        '/new_mission': (context) => HimaMapPicker(),

        // Previous missions screen, receives username as argument
        '/previous_missions': (context) {
          final username = ModalRoute.of(context)!.settings.arguments as String;
          return PreviousMissions(username: username);
        },

        // Mission details screen, receives missionName as argument
        '/mission-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return MissionDetails(missionName: args['missionName']);
        },
      },
    );
  }
}
