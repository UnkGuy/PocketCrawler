import 'dart:math';
import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import '../pet.dart'; // ✅ Go up one folder to find pet.dart

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  late Pet myPet;
  // COOLDOWN STATE
  DateTime? lastRewardTime; // When did we last get a stat boost?
  Timer? cooldownTimer;     // Updates the UI every second
  int secondsRemaining = 0; // For the visual countdown
  // --- GAME STATE ---
  List<Offset> dirtPatches = []; // Where the dirt is located
  String selectedTool = 'hand'; // Options: 'hand', 'soap', 'food'
  double rubMeter = 0.0; // Tracks how much you've rubbed the pet

  @override
  void initState() {
    super.initState();
    myPet = Pet.rollStats("Sir Barks-a-Lot");
    _generateDirt(); // Make the pet dirty initially
  }

  // --- LOGIC HELPERS ---

  void updatePetState(VoidCallback action) {
    setState(() {
      action();
    });
  }

  void _generateDirt() {
    final random = Random();
    // Create 5 random dirt spots relative to the pet center (200x200 box)
    dirtPatches = List.generate(5, (index) {
      return Offset(
        random.nextDouble() * 150,
        random.nextDouble() * 150,
      );
    });
  }

  void _feedPet(int amount) {
    if (myPet.currentHealth < myPet.maxHealth) {
      updatePetState(() => myPet.heal(amount));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nom nom! (+HP)"), duration: Duration(milliseconds: 300)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("I'm full!"), duration: Duration(milliseconds: 300)),
      );
    }
  }

  void _handlePetting() {
    // 1. Check Cooldown
    if (lastRewardTime != null) {
      final difference = DateTime.now().difference(lastRewardTime!);
      if (difference.inSeconds < 60) {
        return;
      }
    }

    setState(() {
      rubMeter += 5.0;

      // 2. Threshold Reached
      if (rubMeter > 100) {
        // --- NEW RANDOM LOGIC STARTS HERE ---
        final random = Random();

        // A. Pick two different stats
        final stats = ['strength', 'dexterity', 'constitution', 'intelligence', 'wisdom', 'charisma'];
        stats.shuffle(); // Randomizes the list order
        String buffStat = stats[0];
        String nerfStat = stats[1]; // Guaranteed to be different from buffStat

        // B. Determine amounts (1 or 2)
        int buffAmount = random.nextInt(2) + 1;
        int nerfAmount = random.nextInt(2) + 1;

        // C. Apply the Trade-off
        updatePetState(() {
          myPet.applyTempModifier(buffStat, buffAmount);
          myPet.applyTempModifier(nerfStat, -nerfAmount); // Note the negative sign
        });

        // --- LOGIC ENDS ---

        rubMeter = 0; // Reset Meter
        lastRewardTime = DateTime.now();
        secondsRemaining = 60;

        // D. Show Dynamic Message
        // formatting helper: "strength" -> "STR"
        String buffLabel = buffStat.substring(0, 3).toUpperCase();
        String nerfLabel = nerfStat.substring(0, 3).toUpperCase();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Wild Magic! +$buffAmount $buffLabel, -$nerfAmount $nerfLabel"),
            duration: const Duration(milliseconds: 2000),
            backgroundColor: Colors.purpleAccent, // Changed color to indicate "magic/random"
          ),
        );

        _startCooldownTimer();
      }
    });
  }

  void _startCooldownTimer() {
    // Cancel existing timer if any
    cooldownTimer?.cancel();

    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (secondsRemaining > 0) {
          secondsRemaining--;
        } else {
          timer.cancel(); // Stop ticking when we hit 0
        }
      });
    });
  }

  @override
  void dispose() {
    cooldownTimer?.cancel(); // Always clean up timers!
    super.dispose();
  }

  void _handleCleaning(Offset touchPosition) {
    setState(() {
      // 1. Remember how much dirt we had BEFORE scrubbing this frame
      int dirtCountBefore = dirtPatches.length;

      // 2. Remove dirt
      dirtPatches.removeWhere((dirtOffset) {
        return (dirtOffset - touchPosition).distance < 40.0;
      });

      // 3. Check if we JUST finished cleaning (we had dirt before, but now we have 0)
      if (dirtCountBefore > 0 && dirtPatches.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars(); // Optional: remove old messages
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Sparkling Clean!"),
              duration: Duration(milliseconds: 1000)
          ),
        );
      }
    });
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      appBar: AppBar(
        title: Text(myPet.name),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => updatePetState(() => myPet = Pet.rollStats("New Pet")),
          )
        ],
      ),
      body: Column(
        children: [
          // TOP: Pet and Health (Takes 50% of screen)
          Expanded(
              flex: 5,
              child: _buildPetArea()
          ),

          // MIDDLE: Tools (Fixed height)
          _buildToolBar(),

          // BOTTOM: Stats (Takes 40% of screen)
          Expanded(
              flex: 4,
              child: _buildStatGrid()
          ),
        ],
      ),
    );
  }

  Widget _buildPetArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. HEALTH TEXT RESTORED
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("HP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("${myPet.currentHealth} / ${myPet.maxHealth}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 5),

        // 2. HEALTH BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: LinearProgressIndicator(
            value: myPet.currentHealth / myPet.maxHealth,
            color: Colors.redAccent,
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        const SizedBox(height: 30),

        // 3. THE INTERACTIVE PET (Keep your existing drag target logic)
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
                  // Pet Container
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: candidateData.isNotEmpty ? Colors.green : Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        myPet.isAlive ? Icons.pets : Icons.sentiment_very_dissatisfied,
                        size: 80,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                  // Dirt Layers
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
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black.withValues(alpha: 0.2), // FIXED COLOR
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolButton('hand', Icons.back_hand, "Pet"),
          _toolButton('soap', Icons.cleaning_services, "Clean"),

          // Food Draggable
          Draggable<String>(
            data: 'apple',
            feedback: const Icon(Icons.apple, size: 50, color: Colors.red),
            childWhenDragging: const Icon(Icons.apple, size: 40, color: Colors.grey),
            onDragStarted: () => setState(() => selectedTool = 'food'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.apple, size: 30, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    final stats = ['Strength', 'Dexterity', 'Constitution', 'Intelligence', 'Wisdom', 'Charisma'];

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFECF0F1), // Light grey background for stats
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
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                String statName = stats[index];
                int value = myPet.getTotalStat(statName);
                // Safely handle missing DiceRoller if needed, or just use value
                int modifier = (value - 10) ~/ 2;

                String modString = modifier >= 0 ? "+$modifier" : "$modifier";

                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
                      ]
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(statName.substring(0, 3).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text("$value",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text("($modString)",
                          style: const TextStyle(fontSize: 12, color: Colors.blue)),
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

  Widget _toolButton(String tool, IconData icon, String label) {
    bool isSelected = selectedTool == tool;

    // Check if this specific button is on cooldown (Only applies to 'hand')
    bool isOnCooldown = tool == 'hand' && secondsRemaining > 0;

    return GestureDetector(
      // If on cooldown, tapping does nothing (or you can show a "Wait" message)
      onTap: isOnCooldown ? null : () => setState(() => selectedTool = tool),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Grey out the button if on cooldown
          color: isOnCooldown
              ? Colors.grey
              : (isSelected ? Colors.blueAccent : Colors.white),
          shape: BoxShape.circle,
        ),
        child: isOnCooldown
        // SHOW COUNTDOWN TEXT
            ? SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Text(
              "$secondsRemaining",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
            ),
          ),
        )
        // SHOW NORMAL ICON
            : Icon(icon, color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }

}