import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pet.dart';
import '../../dungeon/game_state.dart';
import '../../dungeon/item.dart';
import '../screens/game_screen.dart';
import '../screens/character_creation_screen.dart';
import '../../petsim/town_service.dart';

class PetGameManager extends ChangeNotifier {
  // --- CORE DATA ---
  final TownService townService = TownService();
  late Pet myPet;
  bool isLoading = true;

  // --- GAME STATE ---
  List<Offset> dirtPatches = [];
  String selectedTool = 'hand';
  double rubMeter = 0.0;
  int hunger = 0; // 0 = Full, 100 = Starving

  // --- TIMERS ---
  Timer? _hungerTimer;
  Timer? _cooldownTimer;
  DateTime? lastRewardTime;
  int secondsRemaining = 0;

  // --- IMAGES ---
  File? mobileImage;
  Uint8List? webImage;
  final ImagePicker _picker = ImagePicker();

  // ========================================================================
  // INITIALIZATION
  // ========================================================================

  Future<void> initialize() async {
    await townService.loadData();
    await _loadCustomImage();
    await _loadPetStats();
    _generateDirt();
    _startHungerTimer();

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ========================================================================
  // ACTIONS (CALLED BY UI)
  // ========================================================================

  void selectTool(String tool) {
    if (tool == 'hand' && secondsRemaining > 0) return;
    selectedTool = (selectedTool == tool ? 'hand' : tool);
    notifyListeners();
  }

  void feedPet(int amount) {
    // Kitchen Bonus
    double multiplier = 1.0 + (townService.kitchenLevel * 0.2);
    int realAmount = (amount * multiplier).round();

    hunger = max(0, hunger - 20);
    if (myPet.currentHealth < myPet.maxHealth) {
      myPet.heal(realAmount);
    }
    _savePetStats();
    notifyListeners();
  }

  void handlePetting(BuildContext context) {
    if (lastRewardTime != null) {
      final difference = DateTime.now().difference(lastRewardTime!);
      if (difference.inSeconds < 60) return;
    }

    rubMeter += 5.0;
    if (rubMeter > 100) {
      _triggerPettingReward(context);
    }
    notifyListeners();
  }

  void handleCleaning(Offset touchPosition, BuildContext context) {
    int before = dirtPatches.length;
    dirtPatches.removeWhere((d) => (d - touchPosition).distance < 40.0);

    if (before > 0 && dirtPatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sparkling Clean!")));
    }
    notifyListeners();
  }

  Future<void> pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await prefs.setString('custom_pet_web', base64Encode(bytes));
        webImage = bytes;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final newPath = '${dir.path}/custom_pet.png';
        await File(picked.path).copy(newPath);
        await prefs.setString('custom_pet_path', newPath);
        mobileImage = File(newPath);
      }
      notifyListeners();
    }
  }

  // Helper to force save (Used by Shop Sheet)
  void forceSave() {
    _savePetStats();
    notifyListeners();
  }

  // ========================================================================
  // DUNGEON LOGIC
  // ========================================================================

  void goToDungeon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text("Enter Dungeon?", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "There is no turning back.\n\nYour pet will not return until they Conquer Floor 100 or Perish.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            // FIXED: Used Icons.dangerous instead of the non-existent Icons.skull
            icon: const Icon(Icons.dangerous),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
            label: const Text("ENTER", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(context);
              _launchDungeon(context);
            },
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

  // ========================================================================
  // HELPERS (PRIVATE)
  // ========================================================================

  void _triggerPettingReward(BuildContext context) {
    final stats = ['strength', 'dexterity', 'constitution', 'intelligence', 'wisdom', 'charisma'];
    String buffStat = stats[Random().nextInt(stats.length)];
    myPet.applyTempModifier(buffStat, 1);

    rubMeter = 0;
    lastRewardTime = DateTime.now();
    secondsRemaining = 60;
    _startCooldownTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Good boy! +1 $buffStat (Temp)"), backgroundColor: Colors.purpleAccent),
    );
  }

  void _startHungerTimer() {
    _hungerTimer?.cancel();
    _hungerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      hunger += 2;
      if (hunger > 100) hunger = 100;
      if (hunger >= 80 && myPet.currentHealth > 0) {
        myPet.currentHealth = max(0, myPet.currentHealth - 2);
      }
      _savePetStats();
      notifyListeners();
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        secondsRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void _generateDirt() {
    final random = Random();
    dirtPatches = List.generate(5, (index) => Offset(random.nextDouble() * 150, random.nextDouble() * 150));
  }

  // --- PERSISTENCE ---

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
      'name': myPet.name,
      'hp': myPet.currentHealth,
      'maxHp': myPet.maxHealth,
      'hunger': hunger,
      'generation': myPet.generation,
      'strength': myPet.strength,
      'dexterity': myPet.dexterity,
      'constitution': myPet.constitution,
      'intelligence': myPet.intelligence,
      'wisdom': myPet.wisdom,
      'charisma': myPet.charisma,
    };
    await prefs.setString('pet_save_data', jsonEncode(petData));
  }

  Future<void> _loadCustomImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      String? b64 = prefs.getString('custom_pet_web');
      if (b64 != null) webImage = base64Decode(b64);
    } else {
      String? path = prefs.getString('custom_pet_path');
      if (path != null && await File(path).exists()) {
        mobileImage = File(path);
      }
    }
  }

  ImageProvider? getCustomPetImage() {
    if (kIsWeb && webImage != null) return MemoryImage(webImage!);
    if (!kIsWeb && mobileImage != null) return FileImage(mobileImage!);
    return null;
  }
}