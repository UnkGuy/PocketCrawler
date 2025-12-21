import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dungeon/game_state.dart';
import '../dungeon/scenario.dart';
import '../dungeon/scenario_loader.dart';
import '../widgets/image_bubble.dart';
import '../pet.dart';
import 'game_over_screen.dart';
import 'victory_screen.dart'; // Ensure this file exists
import '../widgets/hover_icon.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;

  const GameScreen({super.key, required this.gameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final PetController myPetController = PetController();
  File? mobileImage;
  Uint8List? webImage;

  // --- IMAGE LOADING LOGIC ---
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

  ImageProvider _getPetImage() {
    if (kIsWeb && webImage != null) {
      return MemoryImage(webImage!);
    } else if (!kIsWeb && mobileImage != null) {
      return FileImage(mobileImage!);
    }
    return const AssetImage('assets/pets/pet_crystalcrab.gif');
  }

  @override
  void initState() {
    super.initState();
    _loadNextScenario();
    _loadCustomImage();
  }

  Future<void> _loadNextScenario() async {
    // 1. VICTORY CHECK
    if (widget.gameState.isDungeonCleared) {
      _showVictory();
      return;
    }

    // 2. DEATH CHECK
    if (widget.gameState.isPetDead) {
      _showGameOver();
      return;
    }

    // 3. LOAD SCENARIO
    List<Scenario> scenarios = await ScenarioLoader.loadScenarios();

    // Safety check
    if (scenarios.isEmpty) {
      print("ERROR: No scenarios loaded!");
      return;
    }

    if (mounted) {
      setState(() {
        final scenario = Scenario.selectRandomScenario(scenarios);
        widget.gameState.setCurrentScenario(scenario);
      });
    }
  }

  void _makeChoice(Choice choice) async {
    final result = widget.gameState.makeChoice(choice, myPetController);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          result.resultType,
          style: TextStyle(
            color: result.success ? Colors.green : Colors.red,
            fontWeight: FontWeight.normal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roll: ${result.roll} + ${result.modifier} = ${result.total}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'DC: ${result.dc}',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 20),
            Text(
              result.outcomeMessage,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );

    // Re-check death after choice outcome (e.g., trap damage)
    if (widget.gameState.isPetDead) {
      _showGameOver();
      return;
    }

    widget.gameState.completeScenario();
    widget.gameState.advanceFloor();
    _loadNextScenario();
  }

  void _showGameOver() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameOverScreen(
          summary: widget.gameState.getSummary(),
          pet: widget.gameState.pet,
        ),
      ),
    );
  }

  void _showVictory() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VictoryScreen(
          summary: widget.gameState.getSummary(),
          pet: widget.gameState.pet,
        ),
      ),
    );
  }

  void _useItem(int index) async {
    final result = widget.gameState.useItem(index);
    if (result == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(result.item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: result.messages
              .map((msg) => Text('• $msg', style: const TextStyle(fontSize: 16)))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    setState(() {});
  }

  void _confirmGiveUp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Give Up?", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "Retiring here means death. You will lose this pet forever.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showGameOver(); // Trigger death logic
            },
            child: const Text("Accept Fate", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.gameState.currentScenario;

    if (scenario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 1. LOCK THE BACK BUTTON
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("There is no escape from the dungeon!")),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Floor ${widget.gameState.currentFloor}'),
          backgroundColor: Colors.deepPurple,
          automaticallyImplyLeading: false, // Hides back arrow
          actions: [
            IconButton(
              icon: const Icon(Icons.flag),
              tooltip: "Give Up",
              onPressed: _confirmGiveUp,
            )
          ],
        ),
        body: Stack(
          children: [
            // BACKGROUND IMAGE
            Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        "assets/backgrounds/Dungeon${min(3, (widget.gameState.currentFloor / 20).ceil())}.gif"),
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.cover,
                  )),
              child: Column(
                children: [
                  // SCENARIO TEXT AREA
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            scenario.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            scenario.description,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Choose your action:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...scenario.choices.map((choice) => _buildChoiceButton(choice)),
                        ],
                      ),
                    ),
                  ),

                  // STATS & INVENTORY CARD
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.gameState.pet.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'HP: ${widget.gameState.pet.currentHealth}/${widget.gameState.pet.maxHealth}',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: widget.gameState.pet.currentHealth <=
                                      widget.gameState.pet.maxHealth / 3
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statChip('STR', widget.gameState.pet.getTotalStat('strength')),
                              _statChip('DEX', widget.gameState.pet.getTotalStat('dexterity')),
                              _statChip('CON', widget.gameState.pet.getTotalStat('constitution')),
                              _statChip('INT', widget.gameState.pet.getTotalStat('intelligence')),
                              _statChip('WIS', widget.gameState.pet.getTotalStat('wisdom')),
                              _statChip('CHA', widget.gameState.pet.getTotalStat('charisma')),
                            ],
                          ),

                          // INVENTORY DISPLAY
                          if (widget.gameState.inventory.isNotEmpty) ...[
                            const Divider(height: 16),
                            const Text('Inventory (Max 5):',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: List.generate(
                                widget.gameState.inventory.length,
                                    (index) => SmartHoverTooltip(
                                  triggerOnLongPress: true,
                                  backgroundColor: const Color.fromRGBO(41, 41, 41, 1.0),
                                  tooltipContent: Column(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(
                                                  "assets/items/${widget.gameState.inventory[index].id}.png"),
                                              filterQuality: FilterQuality.none),
                                        ),
                                      ),
                                      Text(
                                        widget.gameState.inventory[index].name,
                                        style: TextStyle(color: Colors.grey[100]),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        widget.gameState.inventory[index].description,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  child: ActionChip(
                                    label: Text(widget.gameState.inventory[index].name),
                                    onPressed: () => _useItem(index),
                                    backgroundColor: Colors.deepPurple[700],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // STATUS EFFECTS DISPLAY
                          if (widget.gameState.pet.activeEffects.isNotEmpty) ...[
                            const Divider(height: 16),
                            const Text('Status Effects:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: List.generate(
                                widget.gameState.pet.activeEffects.length,
                                    (index) => SmartHoverTooltip(
                                  triggerOnLongPress: true,
                                  backgroundColor: const Color.fromRGBO(41, 41, 41, 1.0),
                                  tooltipContent: Column(
                                    children: [
                                      Text(
                                        "Duration: ${widget.gameState.pet.activeEffects[index].duration}",
                                        style: TextStyle(color: Colors.grey[100]),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        widget.gameState.pet.activeEffects[index].description,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  child: ActionChip(
                                    label: Text(widget.gameState.pet.activeEffects[index].name),
                                    onPressed: () {},
                                    backgroundColor: Colors.deepPurple[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PET IMAGE BUBBLE
            DraggableBubble(
              controller: myPetController,
              initialPosition: const Offset(250, 500),
              size: 100,
              child: Image(
                image: _getPetImage(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/pets/pet_crystalcrab.gif');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, int value) {
    int modifier = ((value - 10) / 2).floor();
    String modStr = modifier >= 0 ? '+$modifier' : '$modifier';
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(modStr, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildChoiceButton(Choice choice) {
    final successChance = choice.getSuccessChance(
      widget.gameState.pet,
      hasAdvantage: widget.gameState.pet.hasEffect(StatusEffectType.advantage),
      hasDisadvantage: widget.gameState.pet.hasEffect(StatusEffectType.disadvantage),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _makeChoice(choice),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                choice.text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DC ${choice.difficultyClass}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (widget.gameState.oracleActive)
                    Text(
                      '${successChance.toStringAsFixed(0)}% success',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}