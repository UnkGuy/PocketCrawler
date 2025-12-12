import 'package:flutter/material.dart';
import 'character_creation_screen.dart';
// import '../pet.dart'; // Uncomment this when you are ready to link your pet logic

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Theme(
        data: Theme.of(context).copyWith(
          // 1. Change the default font family for ALL Text/Typography widgets
          // in this subtree:
          textTheme: Theme.of(context).textTheme.copyWith(

            // You can target specific text styles (headline, body, title, etc.)
            // Or use apply() to change the font family for all styles:
            bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(fontFamily: 'Pixelify'),
            bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'Pixelify'),
            // ... and so on for other styles like headline, title, label, etc.
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Using a container to mimic your card style for the logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface, // Uses the grey[850] we set
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.pets,
                  size: 80,
                  color: Colors.deepPurpleAccent,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'POCKET CRAWLER',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'A Roguelike Adventure',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 80),

              // Start Button
              SizedBox(
                width: 250,
                height: 60,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CharacterCreationScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'START ADVENTURE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}