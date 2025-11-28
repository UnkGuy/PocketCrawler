import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DungeonPetApp());
}

class DungeonPetApp extends StatelessWidget {
  const DungeonPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dungeon Pet',
      debugShowCheckedModeBanner: false,
      // We use Material 3 (the modern standard)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Defining colors via ColorScheme is the safest way to avoid conflicts
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          // This 'surface' color will automatically be used by Cards
          surface: Colors.grey[850]!,
          // This sets the background
          surfaceContainer: Colors.grey[900],
          onSurface: Colors.white,
        ),

        // We explicitly set the scaffold background to match your design
        scaffoldBackgroundColor: Colors.grey[900],

        // Text Theme
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}