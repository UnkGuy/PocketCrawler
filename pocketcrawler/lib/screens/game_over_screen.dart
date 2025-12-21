import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dungeon/game_state.dart';
import '../pet.dart';
import '../petsim/town_service.dart'; // Import TownService
import 'character_creation_screen.dart'; // Import Hatchery

class GameOverScreen extends StatelessWidget {
  final RunSummary summary;
  final Pet pet;

  const GameOverScreen({
    super.key,
    required this.summary,
    required this.pet,
  });

  Future<void> _processLegacyAndRestart(BuildContext context) async {
    // 1. Initialize Town Service to save loot
    final townService = TownService();
    await townService.loadData();

    // 2. Calculate "Inheritance" (Loot salvaged from death)
    // Example: You keep 50% of Gold earned, 0% of materials
    // We can calculate this from the summary stats
    int goldSalvaged = (summary.floorsReached * 5);

    townService.addResources(goldSalvaged, 0, 0);
    townService.currentGeneration++; // Increment Generation
    await townService.saveData();

    // 3. Wipe the current Pet Save (Permadeath)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pet_save_data');

    if (!context.mounted) return;

    // 4. Navigate to Hatchery (Remove all back history)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CharacterCreationScreen()),
          (route) => false, // This removes all previous screens from memory
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Darker vibe for death
      appBar: AppBar(
        title: const Text('Fallen Hero'),
        backgroundColor: Colors.red[900],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.broken_image, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              "${pet.name} has fallen.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Generation ${pet.generation} ends here.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),

            // --- SUMMARY CARD ---
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRow("Floors Reached", "${summary.floorsReached}"),
                    _buildRow("Gold Salvaged", "${summary.floorsReached * 5}"), // Show them what they kept
                    const Divider(color: Colors.white24),
                    _buildRow("Items Found", "${summary.itemsFound}"),
                    _buildRow("Choices Made", "${summary.choicesMade}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- THE RESTART BUTTON ---
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.egg),
                label: const Text("RETURN TO HATCHERY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () => _processLegacyAndRestart(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}