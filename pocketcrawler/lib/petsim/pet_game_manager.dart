import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../pet.dart';
import '../../dungeon/game_state.dart';
import '../screens/game_screen.dart';
import '../screens/character_creation_screen.dart';
import '../../petsim/town_service.dart';

class PetGameManager extends ChangeNotifier {
  final TownService townService = TownService();
  late Pet myPet;
  bool isLoading = true;

  // State
  List<Offset> dirtPatches = [];
  int hunger = 0;
  Timer? _hungerTimer;

  // --- INITIALIZATION ---
  Future<void> initialize() async {
    await townService.loadData();
    await _loadPetStats();
    _generateDirt();
    _startHungerTimer();
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    super.dispose();
  }

  // --- ACTIONS (Simplified) ---

  String feedPet() {
    if (hunger == 0 && myPet.currentHealth == myPet.maxHealth) return "Pet is full!";

    // Kitchen Bonus
    int healAmount = (5 * (1.0 + (townService.kitchenLevel * 0.2))).round();
    hunger = max(0, hunger - 20);
    myPet.heal(healAmount);
    _savePetStats();
    notifyListeners();
    return "Yum! Recovered $healAmount HP.";
  }

  String cleanPet() {
    if (dirtPatches.isEmpty) return "It's already clean!";
    dirtPatches.clear();
    notifyListeners();
    return "Sparkling clean!";
  }

  String petPet() {
    // Simple logic: small random buff chance
    if (Random().nextBool()) {
      myPet.applyTempModifier('charisma', 1);
      return "Pet looks happy! (+1 CHA Temp)";
    }
    return "Pet purrs contentedly.";
  }

  // --- DUNGEON ---
  void goToDungeon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text("Enter the Deep?", style: TextStyle(color: Colors.redAccent)),
        content: const Text("Your pet will not return until they Conquer Floor 100 or Perish.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () { Navigator.pop(context); _launchDungeon(context); },
            child: const Text("ENTER", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _launchDungeon(BuildContext context) {
    final gameState = GameState(pet: myPet, maxFloor: 100);
    _hungerTimer?.cancel();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(gameState: gameState)),
          (route) => false,
    );
  }

  // --- HELPERS ---
  void _startHungerTimer() {
    _hungerTimer?.cancel();
    _hungerTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      hunger += 1;
      if (hunger > 100) hunger = 100;

      // Make dirt appear randomly
      if (Random().nextInt(100) < 5 && dirtPatches.length < 5) {
        dirtPatches.add(Offset(Random().nextDouble() * 150, Random().nextDouble() * 150));
      }

      _savePetStats();
      notifyListeners();
    });
  }

  void _generateDirt() {
    dirtPatches = List.generate(3, (index) => Offset(Random().nextDouble() * 150, Random().nextDouble() * 150));
  }

  Future<void> _loadPetStats() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('pet_save_data');
    if (jsonString != null) {
      Map<String, dynamic> petData = jsonDecode(jsonString);
      myPet = Pet.rollStats(petData['name']);
      myPet.currentHealth = petData['hp'];
      myPet.maxHealth = petData['maxHp'];
      myPet.generation = petData['generation'] ?? 1;
      hunger = petData['hunger'] ?? 0;
      myPet.strength = petData['strength'];
      myPet.dexterity = petData['dexterity'];
      myPet.constitution = petData['constitution'];
      myPet.intelligence = petData['intelligence'];
      myPet.wisdom = petData['wisdom'];
      myPet.charisma = petData['charisma'];
    } else {
      myPet = Pet.rollStats("New Hero");
    }
  }

  Future<void> _savePetStats() async {
    if (!myPet.isAlive) return;
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> petData = {
      'name': myPet.name, 'hp': myPet.currentHealth, 'maxHp': myPet.maxHealth, 'hunger': hunger,
      'generation': myPet.generation, 'strength': myPet.strength, 'dexterity': myPet.dexterity,
      'constitution': myPet.constitution, 'intelligence': myPet.intelligence, 'wisdom': myPet.wisdom, 'charisma': myPet.charisma,
    };
    await prefs.setString('pet_save_data', jsonEncode(petData));
  }
  // Add this inside PetGameManager class
  void forceSave() {
    _savePetStats();
    notifyListeners();
  }
}