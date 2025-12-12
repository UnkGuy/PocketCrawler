import 'dart:async'; // For Timer
import 'dart:convert'; // For Web: encoding images to text
import 'dart:io'; // For Mobile: File handling
import 'dart:math'; // For Random
import 'dart:typed_data'; // For Web: handling image bytes

import 'package:flutter/foundation.dart'; // To check kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pet.dart';

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
    myPet = Pet.rollStats("Loading..."); // Temporary placeholder
    _generateDirt();
    _loadCustomImage();

    // LOAD SAVED STATS
    _loadPetStats();
  }

  // --- NEW FUNCTION ---
  Future<void> _loadPetData() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('pet_name');

    if (savedName != null) {
      setState(() {
        myPet.name = savedName;
      });
    }
  }

  @override
  void dispose() {
    cooldownTimer?.cancel();
    super.dispose();
  }

  // --- IMAGE LOGIC (WEB + MOBILE) ---

  Future<void> _pickImage() async {
    // Pick the image (Works on both Web & Mobile)
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Resize to keep it small for Web storage
    );

    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        // --- WEB LOGIC ---
        // 1. Read the file as bytes (numbers), not a path
        final bytes = await pickedFile.readAsBytes();

        // 2. Save to Browser "Cookies" (SharedPrefs) as a text string
        String base64Image = base64Encode(bytes);
        await prefs.setString('custom_pet_web', base64Image);

        // 3. Update UI
        setState(() {
          webImage = bytes;
        });
      } else {
        // --- MOBILE LOGIC ---
        // 1. Get the safe folder
        final directory = await getApplicationDocumentsDirectory();
        final String newPath = '${directory.path}/custom_pet.png';

        // 2. Copy the file there
        final File newImage = await File(pickedFile.path).copy(newPath);

        // 3. Save the path string
        await prefs.setString('custom_pet_path', newPath);

        // 4. Update UI
        setState(() {
          mobileImage = newImage;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New look applied! 📸")),
        );
      }
    }
  }

  Future<void> _loadCustomImage() async {
    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      // --- WEB LOAD ---
      String? base64Image = prefs.getString('custom_pet_web');
      if (base64Image != null) {
        setState(() {
          webImage = base64Decode(base64Image);
        });
      }
    } else {
      // --- MOBILE LOAD ---
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

  // Helper to choose the right image provider
  ImageProvider? _getCustomPetImage() {
    if (kIsWeb && webImage != null) {
      return MemoryImage(webImage!);
    } else if (!kIsWeb && mobileImage != null) {
      return FileImage(mobileImage!);
    }
    return null;
  }

  // --- LOGIC HELPERS ---
  // --- NEW: SAVE SYSTEM ---
  void _startHungerTimer() {
    hungerTimer?.cancel();
    // Run this logic every 5 seconds (Adjust 'seconds' to make it faster/slower)
    hungerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;

      setState(() {
        // 1. Increase Hunger
        hunger += 2;

        // 2. Cap Hunger at 100
        if (hunger > 100) hunger = 100;

        // 3. CONSEQUENCE: If hunger is high (over 80), lose HP
        if (hunger >= 80) {
          if (myPet.currentHealth > 0) {
            myPet.currentHealth -= 2; // Lose 2 HP
            if (myPet.currentHealth < 0) myPet.currentHealth = 0;

            // Optional: Visual feedback
            debugPrint("Starving! HP dropping!");
          }
        }
      });

      // Save continuously so we don't lose progress on crash
      _savePetStats();
    });
  }
  Future<void> _savePetStats() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> petData = {
      'name': myPet.name,
      'hp': myPet.currentHealth,
      'maxHp': myPet.maxHealth,
      'hunger': hunger, // <--- ADD THIS
      // Attributes
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
        hunger = petData['hunger'] ?? 0; // <--- LOAD THIS (Default to 0)

        // ... (rest of your attributes)
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
              onPressed: () async { // Add async
                String newName = nameController.text.isEmpty
                    ? "New Pet"
                    : nameController.text;

                setState(() {
                  // 1. Roll NEW stats
                  myPet = Pet.rollStats(newName);
                  _resetToDefaultLook();
                });

                // 2. SAVE them immediately
                await _savePetStats();

                if (mounted) Navigator.of(context).pop();
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
      // 1. Reduce Hunger
      hunger -= 20;
      if (hunger < 0) hunger = 0;

      // 2. Heal HP
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
        // Stats Logic
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

        // Reset
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
    TextEditingController nameController = TextEditingController(text: myPet.name); // Pre-fill current name

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
            autofocus: true, // Keyboard pops up automatically
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async { // <--- 1. Add 'async' here
                if (nameController.text.isNotEmpty) {
                  // 2. Save to Storage
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('pet_name', nameController.text);

                  // 3. Update Memory (UI)
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
    // Determine if we have a custom image to show
    bool hasCustomImage = (kIsWeb && webImage != null) || (!kIsWeb && mobileImage != null);

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true, // <--- 1. CENTERS THE TITLE

        // <--- 2. MAKES IT CLICKABLE
        title: GestureDetector(
          onTap: _editPetName,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2), // Subtle background
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Shrinks to fit text size
              children: [
                Text(
                  myPet.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 16, color: Colors.white70), // Little pencil icon
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
        // --- NEW HEALTH BAR SECTION ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0), // Less padding to fit icon
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center icon vertically
            children: [
              // 1. THE HP ICON
              Image.asset(
                'assets/hp.png',
                width: 40, // Adjust size
                height: 40,
                errorBuilder: (c, o, s) => const Icon(Icons.favorite, color: Colors.red, size: 40),
              ),

              const SizedBox(width: 15), // Space between icon and bar

              // 2. THE TEXT AND BAR (Expanded to fill width)
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
                      backgroundColor: Colors.black.withOpacity(0.3), // Updated for modern Flutter
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    // ... inside _buildPetArea, below the HP LinearProgressIndicator ...
                    const SizedBox(height: 8), // Space between HP and Hunger
                    // HUNGER BAR
                    Row(
                      children: [
                        const Text("Hunger", style: TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: hunger / 100, // 0.0 to 1.0
                            color: Colors.orange, // Orange for hunger
                            backgroundColor: Colors.black.withOpacity(0.3),
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

        // --- PET AVATAR LOGIC (Same as before) ---
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
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)
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

// --- MODIFIED TOOLBAR (ALL EMOJIS) ---
  Widget _buildToolBar() {
    const double toolEmojiSize = 30.0;

    return Container(
      padding: const EdgeInsets.all(20),
      // Note: Using 'withOpacity' for wider Flutter compatibility.
      // Use 'Colors.black.withValues(alpha: 0.2)' if on Flutter 3.27+
      color: Colors.black.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. HAND BUTTON (Emoji: 🫳)
          _toolButton('hand', '🫳'), // Alternative: 👋 or ✋

          // 2. SOAP BUTTON (Emoji: 🧼)
          _toolButton('soap', '🧼'), // Alternative: 🧽

          // 3. CAMERA BUTTON (Emoji: 📸)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              // Replaced Icon with Text Emoji
              child: const Text('📸', style: TextStyle(fontSize: toolEmojiSize)),
            ),
          ),

          // 4. FEED BUTTON (Emoji: 🍗)
          Draggable<String>(
            data: 'food',
            // Feedback: The giant emoji while dragging (wrapped in Material for clean rendering)
            feedback: const Material(
              color: Colors.transparent,
              child: Text("🍗", style: TextStyle(fontSize: 50)),
            ),
            // ChildWhenDragging: Ghosted version staying behind
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Text("🍗", style: TextStyle(fontSize: toolEmojiSize)),
              ),
            ),
            onDragStarted: () => setState(() => selectedTool = 'food'),
            // Child: The normal button state
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              // Replaced Icon with Text Emoji
              child: const Text("🍗", style: TextStyle(fontSize: toolEmojiSize)),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED HELPER FUNCTION ---
  // Now accepts a String emoji instead of IconData
  Widget _toolButton(String tool, String emoji) {
    bool isSelected = selectedTool == tool;
    bool isOnCooldown = tool == 'hand' && secondsRemaining > 0;

    return GestureDetector(
      onTap: isOnCooldown
          ? null
          : () {
        setState(() {
          if (selectedTool == tool) {
            selectedTool = 'hand'; // Deselect if already active
          } else {
            selectedTool = tool;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Background color changes based on selection state
          color: isOnCooldown
              ? Colors.grey
              : (isSelected ? Colors.blueAccent : Colors.white),
          shape: BoxShape.circle,
        ),
        child: isOnCooldown
        // Cooldown Timer Text
            ? SizedBox(
          width: 30, // Fixed width to match emoji size roughly
          height: 30,
          child: Center(
            child: Text(
              "$secondsRemaining",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
          ),
        )
        // The Emoji Text
            : Text(
          emoji,
          style: const TextStyle(fontSize: 30.0), // Fixed size for all emojis
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

                // Logic: (Score - 10) / 2
                int modifier = (value - 10) ~/ 2;
                String modString = modifier >= 0 ? "+$modifier" : "$modifier";

                // DYNAMIC IMAGE PATH LOGIC
                // "Strength" becomes "assets/strength.png"
                String imagePath = "assets/${statName.toLowerCase()}.png";

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. THE PNG IMAGE
                      Image.asset(
                        imagePath,
                        width: 40, // Adjust size as needed
                        height: 40,
                        // Optional: If you don't have images yet, this prevents a crash
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, color: Colors.grey);
                        },
                      ),

                      const SizedBox(height: 8),

                      // 2. VALUE
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

                      // 3. STAT NAME
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