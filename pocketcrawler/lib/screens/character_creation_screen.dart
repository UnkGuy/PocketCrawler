import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pet.dart';
import 'pet_screen.dart'; // Ensure path is correct
import '../petsim/town_service.dart'; // Import the new service

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TownService _townService = TownService();

  Pet? _hatchedPet;
  bool _isHatching = false;

  @override
  void initState() {
    super.initState();
    _townService.loadData(); // Load town upgrades
  }

  void _hatchEgg() async {
    setState(() => _isHatching = true);

    // Fake delay for suspense
    await Future.delayed(const Duration(seconds: 1));

    String nameToUse = _nameController.text.trim();
    if (nameToUse.isEmpty) nameToUse = 'Hero Gen ${_townService.currentGeneration}';

    // --- ROGUELITE INHERITANCE LOGIC ---
    // Base rolls (4-18)
    final pet = Pet.rollStats(nameToUse);

    // Apply Incubator Bonus (Legacy Upgrade)
    // Example: Each level adds +1 to all stats
    int bonus = _townService.incubatorLevel - 1;

    // Apply Generation Bonus (Evolution)
    // Example: +1 to two random stats per generation
    int genBonus = _townService.currentGeneration;

    setState(() {
      pet.strength += bonus;
      pet.dexterity += bonus;
      pet.constitution += bonus;
      pet.intelligence += bonus;
      pet.wisdom += bonus;
      pet.charisma += bonus;

      // Heal up the new max HP
      pet.heal(999);

      _hatchedPet = pet;
      _isHatching = false;
    });
  }

  Future<void> _adoptAndStart() async {
    if (_hatchedPet == null) return;

    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> petData = {
      'name': _hatchedPet!.name,
      'hp': _hatchedPet!.currentHealth,
      'maxHp': _hatchedPet!.maxHealth,
      'hunger': 0,
      'strength': _hatchedPet!.strength,
      'dexterity': _hatchedPet!.dexterity,
      'constitution': _hatchedPet!.constitution,
      'intelligence': _hatchedPet!.intelligence,
      'wisdom': _hatchedPet!.wisdom,
      'charisma': _hatchedPet!.charisma,
      'generation': _townService.currentGeneration, // Save generation
    };

    await prefs.setString('pet_save_data', jsonEncode(petData));
    await prefs.setString('pet_name', _hatchedPet!.name);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        title: Text('Hatchery (Gen ${_townService.currentGeneration})'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.egg, size: 100, color: Colors.amberAccent),
              const SizedBox(height: 20),
              Text(
                "Incubator Level: ${_townService.incubatorLevel}",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 30),

              if (_hatchedPet == null) ...[
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Name your successor',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isHatching ? null : _hatchEgg,
                    icon: _isHatching
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                        : const Icon(Icons.flash_on),
                    label: Text(_isHatching ? "HATCHING..." : "CRACK EGG"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                  ),
                ),
              ] else ...[
                // PET STAT CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amberAccent)
                  ),
                  child: Column(
                    children: [
                      Text(
                          _hatchedPet!.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                      const Divider(color: Colors.white24),
                      _buildStatRow("STR", _hatchedPet!.strength),
                      _buildStatRow("DEX", _hatchedPet!.dexterity),
                      _buildStatRow("CON", _hatchedPet!.constitution),
                      _buildStatRow("INT", _hatchedPet!.intelligence),
                      _buildStatRow("WIS", _hatchedPet!.wisdom),
                      _buildStatRow("CHA", _hatchedPet!.charisma),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _adoptAndStart,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("BEGIN JOURNEY"),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}