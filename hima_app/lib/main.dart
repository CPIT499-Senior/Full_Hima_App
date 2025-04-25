import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart'; // Import the login screen
import 'screens/PreviousMissions.dart';
import 'screens/MissionDetails.dart';
import 'package:hima_app/screens/HimaMapPicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hima App',
      initialRoute: '/', // Define the first screen
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/new_mission': (context) => HimaMapPicker(),
        '/previous_missions': (context) {
          final username = ModalRoute.of(context)!.settings.arguments as String;
          return PreviousMissions(username: username);
        },
      },
    );
  }
}
