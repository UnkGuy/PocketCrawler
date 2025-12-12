import 'dart:convert'; // For jsonEncode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving data

import '../dungeon/game_state.dart';
import '../petsim/pet_screen.dart'; // Import PetScreen
import '../pet.dart'; // Import Pet class

class GameOverScreen extends StatefulWidget {
  final RunSummary summary;
  final Pet pet;

  const GameOverScreen({
    super.key,
    required this.summary,
    required this.pet,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {

  Future<void> _returnToPetSim() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get previous hunger
    int preservedHunger = 50;
    String? oldSave = prefs.getString('pet_save_data');
    if (oldSave != null) {
      final oldData = jsonDecode(oldSave);
      preservedHunger = oldData['hunger'] ?? 50;

      // Adventurer's Appetite: make them hungry after a run
      preservedHunger += 20;
      if (preservedHunger > 100) preservedHunger = 100;
    }

    // 2. Create the new save data using the MODIFIED pet from the dungeon
    Map<String, dynamic> updatedData = {
      'name': widget.pet.name,
      'hp': widget.pet.currentHealth <= 0 ? 1 : widget.pet.currentHealth, // Prevent 0 HP death loop
      'maxHp': widget.pet.maxHealth,
      'hunger': preservedHunger,
      'strength': widget.pet.strength,
      'dexterity': widget.pet.dexterity,
      'constitution': widget.pet.constitution,
      'intelligence': widget.pet.intelligence,
      'wisdom': widget.pet.wisdom,
      'charisma': widget.pet.charisma,
    };

    // 3. Save to disk
    await prefs.setString('pet_save_data', jsonEncode(updatedData));

    if (!mounted) return;

    // 4. Go back to Pet Screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PetScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Complete'),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              widget.summary.isDungeonCleared ? Icons.emoji_events : Icons.dangerous,
              size: 100,
              color: widget.summary.isDungeonCleared ? Colors.amber : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              widget.summary.isDungeonCleared ? 'DUNGEON CLEARED!' : 'GAME OVER',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // --- RUN STATISTICS CARD ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Run Statistics',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    _buildStatRow('Floors Reached', '${widget.summary.floorsReached}'),
                    _buildStatRow('Choices Made', '${widget.summary.choicesMade}'),
                    _buildStatRow('Items Found', '${widget.summary.itemsFound}'),
                    _buildStatRow('Floors Skipped', '${widget.summary.floorsSkipped}'),
                    _buildStatRow('Floors Lost', '${widget.summary.floorsLost}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- CURRENT STATS CARD (REPLACED STAT CHANGES) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Final Stats',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    _buildAttributeRow('Strength', widget.pet.strength),
                    _buildAttributeRow('Dexterity', widget.pet.dexterity),
                    _buildAttributeRow('Constitution', widget.pet.constitution),
                    _buildAttributeRow('Intelligence', widget.pet.intelligence),
                    _buildAttributeRow('Wisdom', widget.pet.wisdom),
                    _buildAttributeRow('Charisma', widget.pet.charisma),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _returnToPetSim,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('RETURN TO PET', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for generic text rows
  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper specific for Attributes (calculates the +modifier)
  Widget _buildAttributeRow(String label, int value) {
    int modifier = ((value - 10) / 2).floor();
    String modSign = modifier >= 0 ? '+' : '';
    String displayValue = "$value ($modSign$modifier)";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent, // Highlights the stats nicely
            ),
          ),
        ],
      ),
    );
  }
}