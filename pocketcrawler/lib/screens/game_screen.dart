import 'dart:math';

import 'package:flutter/material.dart';
import '../dungeon/game_state.dart';
import '../dungeon/scenario.dart';
import '../dungeon/scenario_library.dart';
import '../image_bubble.dart';
import '../pet.dart';
import 'game_over_screen.dart';
import '/hover_icon.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;

  const GameScreen({super.key, required this.gameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {

  final PetController myPetController = PetController();

  @override
  void initState() {
    super.initState();
    _loadNextScenario();
  }

  void _loadNextScenario() {
    if (widget.gameState.isRunComplete) {
      _showGameOver();
      return;
    }

    setState(() {
      final scenario = Scenario.selectRandomScenario(
        ScenarioLibrary.getAllScenarios(),
      );
      widget.gameState.setCurrentScenario(scenario);
    });
  }

  void _makeChoice(Choice choice) async {
    final result = widget.gameState.makeChoice(choice,myPetController);

    // Show result dialog
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

    // Check if game is over
    if (widget.gameState.isPetDead) {
      _showGameOver();
      return;
    }

    // Move to next floor
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

  @override
  Widget build(BuildContext context) {
    final scenario = widget.gameState.currentScenario;
    if (scenario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Floor ${widget.gameState.currentFloor}'),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/backgrounds/Dungeon${min(3, (widget.gameState.currentFloor/20).ceil())}.gif"),
                  filterQuality: FilterQuality.none,
                  fit: BoxFit.cover,
                )
            ),
            child: Column(
              children: [
                // Scenario Content
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
                // Pet Stats Card
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
                                color: widget.gameState.pet.currentHealth <= widget.gameState.pet.maxHealth / 3
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
                        if (widget.gameState.inventory.isNotEmpty) ...[
                          const Divider(height: 16),
                          const Text('Inventory:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: List.generate(
                              widget.gameState.inventory.length,
                                  (index) => SmartHoverTooltip(
                                // Toggle this to false if you prefer a single tap on mobile
                                triggerOnLongPress: true,
                                backgroundColor: Color.fromRGBO(41, 41, 41, 1.0),
                                tooltipContent: Column(
                                  children: [
                                    Container(
                                      width:50,
                                      height:50,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage("assets/items/${widget.gameState.inventory[index].id}.png"),
                                            filterQuality: FilterQuality.none
                                        ),
                                      ),
                                    ),
                                    Text("${widget.gameState.inventory[index].name}",style: TextStyle(color: Colors.grey[100]),),
                                    SizedBox(height: 10,),
                                    Text("${widget.gameState.inventory[index].description}",style: TextStyle(color: Colors.grey),),

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
                        //put status effects here
                        if (widget.gameState.pet.activeEffects.isNotEmpty) ...[

                          const Divider(height: 16),
                          const Text('Status Effects:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children:
                            List.generate(
                              widget.gameState.pet.activeEffects.length,
                                  (index) => SmartHoverTooltip(
                                // Toggle this to false if you prefer a single tap on mobile
                                triggerOnLongPress: true,
                                backgroundColor: Color.fromRGBO(41, 41, 41, 1.0),
                                tooltipContent: Column(
                                  children: [
                                    Text("Duration: ${widget.gameState.pet.activeEffects[index].duration}",style: TextStyle(color: Colors.grey[100]),),
                                    SizedBox(height: 10,),
                                    Text(widget.gameState.pet.activeEffects[index].description,style: TextStyle(color: Colors.grey),),
                                  ],
                                ),
                                child: ActionChip(
                                  label: Text(widget.gameState.pet.activeEffects[index].name),
                                  onPressed: () => (){},
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

          //pet image
          DraggableBubble(
            controller: myPetController,
            size: 100,
            child: Image.asset(
              'assets/pets/pet_crystalcrab.gif',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
            ),
          ),
        ],
      )
    );
  }

  Widget _statChip(String label, int value) {
    int modifier = ((value - 10) / 2).floor();
    String modStr = modifier >= 0 ? '+$modifier' : '$modifier';
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(modStr, style: const TextStyle(fontSize: 12, color: Colors.white70)),
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