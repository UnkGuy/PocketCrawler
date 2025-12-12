import 'dart:async'; // For Timer
import 'dart:convert'; // For Web: encoding images to text
import 'dart:io'; // For Mobile: File handling
import 'dart:math'; // For Random

import 'package:flutter/foundation.dart'; // To check kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pet.dart';
import '../dungeon/game_state.dart'; // Required for Dungeon logic
import '../screens/game_screen.dart'; // Required for Navigation

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  late Pet myPet;

  // --- GAME STATE ---
  List<Offset> dirtPatches = [];
  String selectedTool = 'hand';
  double rubMeter = 0.0;

  // --- HUNGER STATE ---
  int hunger = 0; // 0 = Full, 100 = Starving
  Timer? hungerTimer;

  // --- CUSTOM IMAGE STATE (HYBRID) ---
  File? mobileImage;          // Used for Android/iOS
  Uint8List? webImage;        // Used for Web/Chrome
  final ImagePicker _picker = ImagePicker();

  // --- COOLDOWN STATE ---
  DateTime? lastRewardTime;
  Timer? cooldownTimer;
  int secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    myPet = Pet.rollStats("Loading...");
    _generateDirt();
    _loadCustomImage();

    // LOAD SAVED STATS
    _loadPetStats();

    // Start the hunger timer
    _startHungerTimer();
  }

  @override
  void dispose() {
    cooldownTimer?.cancel();
    hungerTimer?.cancel();
    super.dispose();
  }

  // --- DUNGEON NAVIGATION ---
  void _goToDungeon() async {
    // 1. Create GameState from current Pet
    final gameState = GameState(
      pet: myPet,
      maxFloor: 100,
    );

    // 2. Pause hunger so they don't starve while fighting
    hungerTimer?.cancel();

    // 3. Navigate to Dungeon
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameState: gameState),
      ),
    );

    // 4. On Return: Resume life
    if (mounted) {
      _startHungerTimer();
      _loadPetStats(); // Reload in case they died or leveled up
    }
  }

  // --- IMAGE LOGIC (WEB + MOBILE) ---

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        String base64Image = base64Encode(bytes);
        await prefs.setString('custom_pet_web', base64Image);

        setState(() {
          webImage = bytes;
        });
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final String newPath = '${directory.path}/custom_pet.png';

        final File newImage = await File(pickedFile.path).copy(newPath);
        await prefs.setString('custom_pet_path', newPath);

        setState(() {
          mobileImage = newImage;
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New look applied! 📸")),
      );
    }
  }

  Future<void> _loadCustomImage() async {
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      String? base64Image = prefs.getString('custom_pet_web');
      if (base64Image != null) {
        setState(() {
          webImage = base64Decode(base64Image);
        });
      }
    } else {
      final String? path = prefs.getString('custom_pet_path');
      if (path != null) {
        final File imageFile = File(path);
        if (await imageFile.exists()) {
          setState(() {
            mobileImage = imageFile;
          });
        }
      }
    }
  }

  Future<void> _resetToDefaultLook() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      await prefs.remove('custom_pet_web');
      setState(() => webImage = null);
    } else {
      await prefs.remove('custom_pet_path');
      setState(() => mobileImage = null);
    }
  }

  ImageProvider? _getCustomPetImage() {
    if (kIsWeb && webImage != null) {
      return MemoryImage(webImage!);
    } else if (!kIsWeb && mobileImage != null) {
      return FileImage(mobileImage!);
    }
    return null;
  }

  // --- LOGIC HELPERS ---

  void _startHungerTimer() {
    hungerTimer?.cancel();
    hungerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;

      setState(() {
        hunger += 2;
        if (hunger > 100) hunger = 100;

        if (hunger >= 80) {
          if (myPet.currentHealth > 0) {
            myPet.currentHealth -= 2;
            if (myPet.currentHealth < 0) myPet.currentHealth = 0;
            debugPrint("Starving! HP dropping!");
          }
        }
      });
      _savePetStats();
    });
  }

  Future<void> _savePetStats() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> petData = {
      'name': myPet.name,
      'hp': myPet.currentHealth,
      'maxHp': myPet.maxHealth,
      'hunger': hunger,
      'strength': myPet.strength,
      'dexterity': myPet.dexterity,
      'constitution': myPet.constitution,
      'intelligence': myPet.intelligence,
      'wisdom': myPet.wisdom,
      'charisma': myPet.charisma,
    };
    String jsonString = jsonEncode(petData);
    await prefs.setString('pet_save_data', jsonString);
  }

  Future<void> _loadPetStats() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('pet_save_data');

    if (jsonString != null) {
      Map<String, dynamic> petData = jsonDecode(jsonString);
      setState(() {
        myPet.name = petData['name'];
        myPet.currentHealth = petData['hp'];
        myPet.maxHealth = petData['maxHp'];
        hunger = petData['hunger'] ?? 0;

        // --- ADD THESE LINES TO LOAD STATS ---
        myPet.strength = petData['strength'] ?? myPet.strength;
        myPet.dexterity = petData['dexterity'] ?? myPet.dexterity;
        myPet.constitution = petData['constitution'] ?? myPet.constitution;
        myPet.intelligence = petData['intelligence'] ?? myPet.intelligence;
        myPet.wisdom = petData['wisdom'] ?? myPet.wisdom;
        myPet.charisma = petData['charisma'] ?? myPet.charisma;
      });
    }
  }

  void _startNewPetProcess() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Start Over?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("This will re-roll stats and reset the image."),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Enter new pet name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Create"),
              onPressed: () async {
                String newName = nameController.text.isEmpty
                    ? "New Pet"
                    : nameController.text;

                setState(() {
                  myPet = Pet.rollStats(newName);
                  _resetToDefaultLook();
                });

                await _savePetStats();

                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void updatePetState(VoidCallback action) {
    setState(() {
      action();
    });
  }

  void _generateDirt() {
    final random = Random();
    dirtPatches = List.generate(5, (index) {
      return Offset(
        random.nextDouble() * 150,
        random.nextDouble() * 150,
      );
    });
  }

  void _feedPet(int amount) {
    setState(() {
      hunger -= 20;
      if (hunger < 0) hunger = 0;

      if (myPet.currentHealth < myPet.maxHealth) {
        myPet.heal(amount);
      }

      _savePetStats();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Delicious! Hunger: $hunger/100"),
          duration: const Duration(milliseconds: 500)
      ),
    );
  }

  void _handlePetting() {
    if (lastRewardTime != null) {
      final difference = DateTime.now().difference(lastRewardTime!);
      if (difference.inSeconds < 60) return;
    }

    setState(() {
      rubMeter += 5.0;
      if (rubMeter > 100) {
        final random = Random();
        final stats = ['strength', 'dexterity', 'constitution', 'intelligence', 'wisdom', 'charisma'];
        stats.shuffle();

        String buffStat = stats[0];
        String nerfStat = stats[1];
        int buffAmount = random.nextInt(2) + 1;
        int nerfAmount = random.nextInt(2) + 1;

        updatePetState(() {
          myPet.applyTempModifier(buffStat, buffAmount);
          myPet.applyTempModifier(nerfStat, -nerfAmount);
        });

        rubMeter = 0;
        lastRewardTime = DateTime.now();
        secondsRemaining = 60;
        _startCooldownTimer();

        String buffLabel = buffStat.substring(0, 3).toUpperCase();
        String nerfLabel = nerfStat.substring(0, 3).toUpperCase();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Wild Magic! +$buffAmount $buffLabel, -$nerfAmount $nerfLabel"),
            backgroundColor: Colors.purpleAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _startCooldownTimer() {
    cooldownTimer?.cancel();
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (secondsRemaining > 0) {
          secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _handleCleaning(Offset touchPosition) {
    setState(() {
      int dirtCountBefore = dirtPatches.length;
      dirtPatches.removeWhere((dirtOffset) {
        return (dirtOffset - touchPosition).distance < 40.0;
      });

      if (dirtCountBefore > 0 && dirtPatches.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sparkling Clean!"), duration: Duration(seconds: 1)),
        );
      }
    });
  }

  void _editPetName() {
    TextEditingController nameController = TextEditingController(text: myPet.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rename Pet"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: "Enter new name",
              suffixIcon: Icon(Icons.edit),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('pet_name', nameController.text);

                  if (!mounted) return;

                  setState(() {
                    myPet.name = nameController.text;
                  });
                }

                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    bool hasCustomImage = (kIsWeb && webImage != null) || (!kIsWeb && mobileImage != null);

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _editPetName,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  myPet.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 16, color: Colors.white70),
              ],
            ),
          ),
        ),

        actions: [
          if (hasCustomImage)
            IconButton(
              icon: const Icon(Icons.no_photography),
              tooltip: "Reset to Default Look",
              onPressed: _resetToDefaultLook,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewPetProcess,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 5, child: _buildPetArea(hasCustomImage)),
          _buildToolBar(),
          Expanded(flex: 4, child: _buildStatGrid()),
        ],
      ),
    );
  }

  Widget _buildPetArea(bool hasCustomImage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/hp.png',
                width: 40,
                height: 40,
                errorBuilder: (c, o, s) => const Icon(Icons.favorite, color: Colors.red, size: 40),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("HP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("${myPet.currentHealth} / ${myPet.maxHealth}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: myPet.currentHealth / myPet.maxHealth,
                      color: Colors.redAccent,
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("Hunger", style: TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: hunger / 100,
                            color: Colors.orange,
                            backgroundColor: Colors.black.withValues(alpha: 0.3),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        DragTarget<String>(
          onWillAcceptWithDetails: (details) => selectedTool == 'food',
          onAcceptWithDetails: (details) {
            _feedPet(5);
          },
          builder: (context, candidateData, rejectedData) {
            return GestureDetector(
              onPanUpdate: (details) {
                if (selectedTool == 'hand') {
                  _handlePetting();
                } else if (selectedTool == 'soap') {
                  _handleCleaning(details.localPosition);
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      image: hasCustomImage
                          ? DecorationImage(
                          image: _getCustomPetImage()!,
                          fit: BoxFit.cover)
                          : null,
                      border: Border.all(
                        color: candidateData.isNotEmpty ? Colors.green : Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)
                      ],
                    ),
                    child: !hasCustomImage
                        ? Center(
                      child: Icon(
                        myPet.isAlive ? Icons.pets : Icons.sentiment_very_dissatisfied,
                        size: 80,
                        color: Colors.brown,
                      ),
                    )
                        : null,
                  ),
                  ...dirtPatches.map((offset) => Positioned(
                    top: offset.dy,
                    left: offset.dx,
                    child: const Icon(Icons.blur_on, color: Colors.brown, size: 40),
                  )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolBar() {
    const double toolEmojiSize = 30.0;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. HAND BUTTON
          _toolButton('hand', '🫳'),

          // 2. SOAP BUTTON
          _toolButton('soap', '🧼'),

          // 3. CAMERA BUTTON
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Text('📸', style: TextStyle(fontSize: toolEmojiSize)),
            ),
          ),

          // 4. DUNGEON BUTTON (Sword)
          GestureDetector(
            onTap: _goToDungeon,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Text('⚔️', style: TextStyle(fontSize: toolEmojiSize)),
            ),
          ),

          // 5. FOOD BUTTON (Draggable)
          Draggable<String>(
            data: 'food',
            feedback: const Material(
              color: Colors.transparent,
              child: Text("🍗", style: TextStyle(fontSize: 50)),
            ),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Text("🍗", style: TextStyle(fontSize: toolEmojiSize)),
              ),
            ),
            onDragStarted: () => setState(() => selectedTool = 'food'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Text("🍗", style: TextStyle(fontSize: toolEmojiSize)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(String tool, String emoji) {
    bool isSelected = selectedTool == tool;
    bool isOnCooldown = tool == 'hand' && secondsRemaining > 0;

    return GestureDetector(
      onTap: isOnCooldown
          ? null
          : () {
        setState(() {
          if (selectedTool == tool) {
            selectedTool = 'hand';
          } else {
            selectedTool = tool;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOnCooldown
              ? Colors.grey
              : (isSelected ? Colors.blueAccent : Colors.white),
          shape: BoxShape.circle,
        ),
        child: isOnCooldown
            ? SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: Text(
              "$secondsRemaining",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
          ),
        )
            : Text(
          emoji,
          style: const TextStyle(fontSize: 30.0),
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    final List<String> stats = ['Strength', 'Dexterity', 'Constitution', 'Intelligence', 'Wisdom', 'Charisma'];

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFECF0F1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ABILITY SCORES",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                String statName = stats[index];
                int value = myPet.getTotalStat(statName);

                int modifier = (value - 10) ~/ 2;
                String modString = modifier >= 0 ? "+$modifier" : "$modifier";

                String imagePath = "assets/${statName.toLowerCase()}.png";

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        imagePath,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, color: Colors.grey);
                        },
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$value",
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "($modString)",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        statName.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.grey[500]
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}