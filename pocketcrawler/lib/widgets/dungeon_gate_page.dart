import 'package:flutter/material.dart';
import '../../petsim/pet_game_manager.dart';

class DungeonGatePage extends StatelessWidget {
  final PetGameManager manager;
  const DungeonGatePage({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    // No background image here either (handled by PetScreen)

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                  "ADVENTURE LOG",
                  style: TextStyle(
                      color: Color(0xFFFFECB3), // Soft Gold
                      fontSize: 32,
                      fontFamily: 'Pixelify',
                      letterSpacing: 2,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2,2))]
                  )
              ),
              const SizedBox(height: 30),

              // STATS GRID
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _statCard("STR", manager.myPet.strength, Colors.red[900]!),
                  _statCard("DEX", manager.myPet.dexterity, Colors.green[800]!),
                  _statCard("CON", manager.myPet.constitution, Colors.orange[900]!),
                  _statCard("INT", manager.myPet.intelligence, Colors.blue[900]!),
                  _statCard("WIS", manager.myPet.wisdom, Colors.purple[900]!),
                  _statCard("CHA", manager.myPet.charisma, Colors.pink[900]!),
                ],
              ),

              const SizedBox(height: 40),

              // THE ENTER BUTTON
              GestureDetector(
                onTap: () => manager.goToDungeon(context),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 300), // Don't get too wide on tablets
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF5D4037), Color(0xFF4E342E)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8D6E63), width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0,5))
                      ]
                  ),
                  child: const Center(
                    child: Text(
                        "EMBARK ON QUEST",
                        style: TextStyle(
                            color: Color(0xFFFFECB3),
                            fontSize: 18,
                            fontFamily: 'Pixelify',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5
                        )
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, Color inkColor) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2,2))],
        border: Border.all(color: const Color(0xFFD7CCC8)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: inkColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const Divider(height: 10, thickness: 1, indent: 15, endIndent: 15, color: Colors.grey),
          Text("$value", style: TextStyle(color: const Color(0xFF3E2723), fontSize: 22, fontFamily: 'Pixelify')),
        ],
      ),
    );
  }
}