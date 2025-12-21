import 'package:flutter/material.dart';
import '../petsim/pet_game_manager.dart';

class PetActionBar extends StatelessWidget {
  final PetGameManager manager;

  const PetActionBar({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Hand
          _toolButton('hand', '🫳', manager.selectTool),

          // Soap
          _toolButton('soap', '🧼', manager.selectTool),

          // Camera
          _toolButton('camera', '📸', (_) => manager.pickImage()),

          // Dungeon Button (Big)
          GestureDetector(
            onTap: () => manager.goToDungeon(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[800], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Text('⚔️', style: TextStyle(fontSize: 28)),
            ),
          ),

          // Food (Draggable)
          Draggable<String>(
            data: 'food',
            feedback: const Material(color: Colors.transparent, child: Text("🍗", style: TextStyle(fontSize: 40))),
            child: _toolContainer('🍗'),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(String tool, String emoji, Function(String) onTap) {
    bool isSelected = manager.selectedTool == tool;
    bool isOnCooldown = tool == 'hand' && manager.secondsRemaining > 0;

    return GestureDetector(
      onTap: isOnCooldown ? null : () => onTap(tool),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            shape: BoxShape.circle
        ),
        child: isOnCooldown
            ? Text("${manager.secondsRemaining}", style: const TextStyle(fontWeight: FontWeight.bold))
            : Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _toolContainer(String emoji) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );
  }
}