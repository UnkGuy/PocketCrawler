import 'dart:convert'; // For jsonEncode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving data

import '../pet.dart';
import '../petsim/pet_screen.dart'; // Import the Pet Screen

// import '../dungeon/game_state.dart';
// import '../dungeon/scenario_library.dart';
// import 'game_screen.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  Pet? _rolledPet;

  void _rollStats() {
    // If the name is empty, default to "Hero"
    String nameToUse = _nameController.text.trim();
    if (nameToUse.isEmpty) nameToUse = 'Hero';

    setState(() {
      _rolledPet = Pet.rollStats(nameToUse);
    });
  }

  Future<void> _startGame() async {
    if (_rolledPet == null) return;

    // 1. Get the Shared Preferences instance
    final prefs = await SharedPreferences.getInstance();

    // 2. Prepare the data to match what PetScreen expects
    Map<String, dynamic> petData = {
      'name': _rolledPet!.name,
      'hp': _rolledPet!.currentHealth,
      'maxHp': _rolledPet!.maxHealth,
      'hunger': 0, // New pets start full

      'strength': _rolledPet!.strength,
      'dexterity': _rolledPet!.dexterity,
      'constitution': _rolledPet!.constitution,
      'intelligence': _rolledPet!.intelligence,
      'wisdom': _rolledPet!.wisdom,
      'charisma': _rolledPet!.charisma,
    };

    // 3. Save the data
    await prefs.setString('pet_save_data', jsonEncode(petData));
    await prefs.setString('pet_name', _rolledPet!.name);

    // 4. check if the widget is still on screen before navigating
    if (!mounted) return;

    // 5. Go to the Pet Screen (The Hub)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PetScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This ensures the keyboard doesn't hide the current input field
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Create Your Pet'),
        backgroundColor: Colors.deepPurple,
      ),
      // 1. SafeArea prevents content from hiding behind notches/status bars
      body: SafeArea(
        // 2. SingleChildScrollView allows the column to scroll if it gets too tall
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Name Your Pet',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter name...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _rollStats,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text('ROLL STATS', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 30),
                if (_rolledPet != null) ...[
                  Card(
                    // Added a dark color so the white text inside remains visible
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rolledPet!.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Explicitly set text to white
                            ),
                          ),
                          const Divider(height: 20, color: Colors.white24),
                          _buildStatRow('STR', _rolledPet!.strength),
                          _buildStatRow('DEX', _rolledPet!.dexterity),
                          _buildStatRow('CON', _rolledPet!.constitution),
                          _buildStatRow('INT', _rolledPet!.intelligence),
                          _buildStatRow('WIS', _rolledPet!.wisdom),
                          _buildStatRow('CHA', _rolledPet!.charisma),
                          const Divider(height: 20, color: Colors.white24),
                          Text(
                            'HP: ${_rolledPet!.currentHealth}/${_rolledPet!.maxHealth}',
                            style: const TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('ADOPT PET', style: TextStyle(fontSize: 18)),
                  ),
                  // Add a small spacer at the bottom so the button isn't stuck to the edge when scrolling
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    int modifier = ((value - 10) / 2).floor();
    String modifierStr = modifier >= 0 ? '+$modifier' : '$modifier';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 18, color: Colors.white), // Added color
          ),
          Text(
            '($modifierStr)',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}