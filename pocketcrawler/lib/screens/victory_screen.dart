import 'package:flutter/material.dart';
import '../dungeon/game_state.dart';
import '../pet.dart';
import 'character_creation_screen.dart'; // To start next gen
import 'package:shared_preferences/shared_preferences.dart';

class VictoryScreen extends StatelessWidget {
  final RunSummary summary;
  final Pet pet;

  const VictoryScreen({super.key, required this.summary, required this.pet});

  void _ascend(BuildContext context) async {
    // 1. Clear current pet save (They have ascended)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pet_save_data');

    // 2. Navigate to Hatchery for the next generation
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CharacterCreationScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wb_sunny, size: 120, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "THE GATE OPENS",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 20),
              Text(
                "${pet.name} has proven worthy.\nThe cycle of the dungeon is broken... for now.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _ascend(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                child: const Text("ASCEND (Start Next Gen)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}