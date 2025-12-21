import 'package:flutter/material.dart';
import '../petsim/pet_game_manager.dart';

class PetDisplayArea extends StatelessWidget {
  final PetGameManager manager;

  const PetDisplayArea({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    bool hasCustomImage = manager.getCustomPetImage() != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // --- STATUS BARS ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildStatusBar("HP", manager.myPet.currentHealth, manager.myPet.maxHealth, Colors.redAccent),
              const SizedBox(height: 5),
              _buildStatusBar("Hunger", manager.hunger, 100, Colors.orange),
            ],
          ),
        ),

        const Spacer(),

        // --- DRAG TARGET (INTERACTION) ---
        DragTarget<String>(
          onWillAcceptWithDetails: (d) => manager.selectedTool == 'food',
          onAcceptWithDetails: (d) => manager.feedPet(5),
          builder: (context, candidates, rejects) {
            return GestureDetector(
              onPanUpdate: (d) {
                if (manager.selectedTool == 'hand') manager.handlePetting(context);
                if (manager.selectedTool == 'soap') manager.handleCleaning(d.localPosition, context);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // PET CONTAINER
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: candidates.isNotEmpty ? Colors.green : Colors.white, width: 4),
                      image: hasCustomImage
                          ? DecorationImage(image: manager.getCustomPetImage()!, fit: BoxFit.cover)
                          : null,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
                    ),
                    child: !hasCustomImage
                        ? Center(child: Icon(manager.myPet.isAlive ? Icons.pets : Icons.sentiment_very_dissatisfied, size: 80, color: Colors.brown))
                        : null,
                  ),
                  // DIRT PATCHES
                  ...manager.dirtPatches.map((o) => Positioned(
                      top: o.dy, left: o.dx,
                      child: const Icon(Icons.blur_on, color: Colors.brown, size: 40)
                  )),
                ],
              ),
            );
          },
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildStatusBar(String label, int current, int max, Color color) {
    double pct = (current / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        Expanded(
          child: LinearProgressIndicator(
            value: pct, color: color, backgroundColor: Colors.black26, minHeight: 10, borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Text("$current/$max", style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}