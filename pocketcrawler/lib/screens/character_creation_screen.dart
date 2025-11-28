import 'package:flutter/material.dart';
import '../pet.dart';
import '../dungeon/game_state.dart';
import '../dungeon/scenario_library.dart';
import 'game_screen.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  Pet? _rolledPet;

  void _rollStats() {
    setState(() {
      _rolledPet = Pet.rollStats(_nameController.text.isEmpty ? 'Hero' : _nameController.text);
    });
  }

  void _startGame() {
    if (_rolledPet == null) return;

    final gameState = GameState(
      pet: _rolledPet!,
      maxFloor: 100,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameState: gameState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Pet'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
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
                        ),
                      ),
                      const Divider(height: 20),
                      _buildStatRow('STR', _rolledPet!.strength),
                      _buildStatRow('DEX', _rolledPet!.dexterity),
                      _buildStatRow('CON', _rolledPet!.constitution),
                      _buildStatRow('INT', _rolledPet!.intelligence),
                      _buildStatRow('WIS', _rolledPet!.wisdom),
                      _buildStatRow('CHA', _rolledPet!.charisma),
                      const Divider(height: 20),
                      Text(
                        'HP: ${_rolledPet!.currentHealth}/${_rolledPet!.maxHealth}',
                        style: const TextStyle(fontSize: 20),
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
                child: const Text('BEGIN DUNGEON', style: TextStyle(fontSize: 18)),
              ),
            ],
          ],
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
            style: const TextStyle(fontSize: 18),
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